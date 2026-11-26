#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_REPOSITORY:?GitHub Actions debe definir GITHUB_REPOSITORY}"
: "${GITHUB_SHA:?GitHub Actions debe definir GITHUB_SHA}"

owner_lower="${GITHUB_REPOSITORY_OWNER,,}"
repository_lower="${GITHUB_REPOSITORY#*/}"
repository_lower="${repository_lower,,}"
image_tag="${GITHUB_SHA}"
image_prefix="ghcr.io/${owner_lower}/${repository_lower}"
trivy_cache="${RUNNER_TEMP:-/tmp}/trivy-cache"

services=(catalog carts orders checkout ui admin)
declare -A contexts=(
  [catalog]="src/catalog"
  [carts]="src/cart"
  [orders]="src/orders"
  [checkout]="src/checkout"
  [ui]="src/ui"
  [admin]="src/admin"
)

mkdir -p "$trivy_cache"

for service in "${services[@]}"; do
  image="${image_prefix}-${service}:${image_tag}"
  echo "Compilando ${image}"
  docker build --pull \
    --label "org.opencontainers.image.source=https://github.com/${GITHUB_REPOSITORY}" \
    --label "org.opencontainers.image.revision=${GITHUB_SHA}" \
    --tag "$image" \
    "${contexts[$service]}"
done

scan_status=0
for service in "${services[@]}"; do
  image="${image_prefix}-${service}:${image_tag}"
  echo "Analizando ${image}"
  if ! docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${trivy_cache}:/root/.cache/" \
    ghcr.io/aquasecurity/trivy:0.76.2 \
    image --scanners vuln --severity HIGH,CRITICAL --exit-code 1 "$image"; then
    scan_status=1
  fi
done

if [[ "$scan_status" -ne 0 ]]; then
  echo "Una o más imágenes tienen vulnerabilidades altas o críticas; no se publicará ninguna imagen." >&2
  exit "$scan_status"
fi

if [[ "${PUBLISH_IMAGES:-false}" == "true" ]]; then
  : "${GH_TOKEN:?Se requiere GH_TOKEN para publicar imágenes}"
  echo "$GH_TOKEN" | docker login ghcr.io --username "$GITHUB_ACTOR" --password-stdin

  for service in "${services[@]}"; do
    image="${image_prefix}-${service}:${image_tag}"
    echo "Publicando ${image}"
    docker push "$image"
  done
fi
