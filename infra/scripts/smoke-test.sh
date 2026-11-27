#!/usr/bin/env bash
#
# Smoke test de punta a punta de un ambiente desplegado.
#
# Recorre el flujo real de la tienda usando solo las URLs públicas:
#   admin crea un producto -> catalog lo lista -> carrito -> checkout -> orden
#
# Uso:
#   ./smoke-test.sh dev
#   ./smoke-test.sh test
#
# Requiere: terraform, awscli, curl y jq, con credenciales del laboratorio.
# No imprime credenciales: lee el usuario y la clave del panel desde Secrets
# Manager y los usa solo dentro del script.

set -uo pipefail

environment="${1:-dev}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
env_dir="${script_dir}/../envs/${environment}"

fail() {
  echo "FALLO: $*" >&2
  exit 1
}

for cmd in terraform aws curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || fail "falta el comando '$cmd'"
done

[[ -d "$env_dir" ]] || fail "no existe el ambiente '$environment' en $env_dir"

ui_url="$(terraform -chdir="$env_dir" output -raw ui_url 2>/dev/null)" \
  || fail "no se pudo leer ui_url. ¿Está aplicado el ambiente?"
admin_url="$(terraform -chdir="$env_dir" output -raw admin_url 2>/dev/null)" \
  || fail "no se pudo leer admin_url"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
jar="$work/cookies.txt"
body="$work/body.json"

# request <método> <url> [json]
# Devuelve el código HTTP e imprime el cuerpo en $body.
request() {
  local method=$1 url=$2 data=${3:-}
  if [[ -n "$data" ]]; then
    curl -sS --max-time 30 -o "$body" -w '%{http_code}' \
      -X "$method" -H 'Content-Type: application/json' \
      -b "$jar" -c "$jar" --data "$data" "$url"
  else
    curl -sS --max-time 30 -o "$body" -w '%{http_code}' \
      -X "$method" -b "$jar" -c "$jar" "$url"
  fi
}

expect() {
  local got=$1 want=$2 label=$3
  [[ "$got" == "$want" ]] || {
    echo "--- respuesta ---" >&2
    cat "$body" >&2
    echo >&2
    fail "$label (HTTP $got, esperaba $want)"
  }
  echo "OK   $label"
}

echo "Smoke test del ambiente '$environment'"
echo "  tienda: $ui_url"
echo "  admin:  $admin_url"
echo

# 1. Salud de las dos aplicaciones públicas.
expect "$(request GET "$ui_url/health")" 200 "health de la tienda"
expect "$(request GET "$admin_url/health")" 200 "health del panel"

# 2. Login del panel con las credenciales de Secrets Manager.
credentials="$(aws secretsmanager get-secret-value \
  --secret-id "tero-${environment}/admin" \
  --query SecretString --output text 2>/dev/null)" \
  || fail "no se pudo leer el secreto tero-${environment}/admin"

login_payload="$(jq -n \
  --arg u "$(printf '%s' "$credentials" | jq -r .username)" \
  --arg p "$(printf '%s' "$credentials" | jq -r .password)" \
  '{username: $u, password: $p}')"

expect "$(request POST "$admin_url/auth/login" "$login_payload")" 200 "login del panel"
expect "$(request GET "$admin_url/auth/me")" 200 "sesión del panel"

# 3. Producto de prueba: se borra si quedó de una corrida anterior.
old_products="$(curl -sS --max-time 30 -b "$jar" "$admin_url/admin/api/products")" \
  || fail "no se pudo listar productos en el panel"
while read -r old_id; do
  [[ -n "$old_id" ]] || continue
  curl -sS --max-time 30 -o /dev/null -b "$jar" \
    -X DELETE "$admin_url/admin/api/products/$old_id"
done < <(printf '%s' "$old_products" | jq -r '.[] | select(.name == "Producto de prueba") | .id')

product_payload='{"name":"Producto de prueba","description":"Creado por el smoke test de infraestructura","price":1990}'
expect "$(request POST "$admin_url/admin/api/products" "$product_payload")" 201 "alta de producto en el panel"

product_id="$(jq -r '.id // empty' "$body")"
[[ -n "$product_id" ]] || fail "el panel no devolvió el id del producto"

# 4. El producto tiene que verse desde el catálogo pasando por el ALB interno.
expect "$(request GET "$ui_url/api/catalog/products")" 200 "catálogo a través de la tienda"
grep -q "$product_id" "$body" || fail "el catálogo no devolvió el producto $product_id"

# 5. Carrito persistido en PostgreSQL.
customer="smoke-$(date +%s)"
cart_payload="$(jq -n --arg id "$product_id" '{itemId: $id, quantity: 2, unitPrice: 1990}')"
expect "$(request POST "$ui_url/api/carts/${customer}/items" "$cart_payload")" 201 "agregar al carrito"

expect "$(request GET "$ui_url/api/carts/${customer}")" 200 "leer el carrito"
grep -q "$product_id" "$body" || fail "el carrito no devolvió el producto $product_id"

# 6. Checkout: calcula el total y lo guarda en Redis.
checkout_payload="$(jq -n --arg id "$product_id" '{
  items: [{id: $id, name: "Producto de prueba", quantity: 2, price: 1990}],
  shippingAddress: {
    firstName: "Fran", lastName: "Arenas",
    address1: "Cuareim 1451", city: "Montevideo",
    state: "Montevideo", zip: "11000",
    email: "smoke@example.com"
  }
}')"
expect "$(request POST "$ui_url/api/checkout/${customer}/update" "$checkout_payload")" 201 "crear checkout"
total="$(jq -r '.total // empty' "$body")"
[[ -n "$total" ]] || fail "el checkout no devolvió el total"
echo "     total calculado: $total"

# 7. Confirmar el checkout: checkout llama a orders y orders persiste en PostgreSQL.
expect "$(request POST "$ui_url/api/checkout/${customer}/submit")" 201 "confirmar checkout"
order_id="$(jq -r '.orderId // empty' "$body")"
[[ -n "$order_id" ]] || fail "el checkout no devolvió orderId"

expect "$(request GET "$ui_url/api/orders")" 200 "listar órdenes desde la tienda"
grep -q "$order_id" "$body" || fail "la orden $order_id no aparece en orders"

expect "$(request GET "$admin_url/admin/api/orders")" 200 "listar órdenes desde el panel"
grep -q "$order_id" "$body" || fail "la orden $order_id no aparece en el panel"

echo
echo "Smoke test completo: OK (orden $order_id)"
