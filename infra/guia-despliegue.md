# Guía para desplegar Tero en AWS desde cero

Esta guía permite que alguien nuevo, partiendo de una máquina limpia, reproduzca
el ambiente completo de Tero (seis microservicios, RDS y Redis) en ECS Fargate
con Terraform. Está pensada para seguirla **en orden**, sin conocer el proyecto.

> La referencia técnica (arquitectura, variables, outputs, operación, deuda y
> justificación frente a la letra) está en [`infra/README.md`](README.md).

## 1. Qué necesitás instalado

- **Git** y una cuenta con acceso al repositorio.
- **Terraform >= 1.10** (`terraform version`).
- **AWS CLI v2** (`aws --version`).
- **Python 3** (el script de inicialización de la base lo usa).
- **curl** y **jq** (para el smoke test).
- **Docker** (opcional, solo para verificar que existen las imágenes).

```bash
terraform version && aws --version && jq --version && python3 --version
```

## 2. Conectar tu AWS

1. Entrá a **AWS Academy**, abrí el curso y entrá al **Learner Lab**.
2. Pulsá **Start Lab** y esperá a que la luz quede verde.
3. En **AWS Details** copiá los tres valores:
   `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` y `AWS_SESSION_TOKEN`.

Configuralos en la CLI:

```bash
aws configure set aws_access_key_id     "<AWS_ACCESS_KEY_ID>"
aws configure set aws_secret_access_key "<AWS_SECRET_ACCESS_KEY>"
aws configure set aws_session_token     "<AWS_SESSION_TOKEN>"
aws configure set region                us-east-1
```

Verificá que estás conectado:

```bash
aws sts get-caller-identity
```

Debe devolver un `Account` de 12 dígitos y el rol `voclabs`. Ese número de
cuenta es importante para el paso siguiente.

> Las credenciales de Academy son temporales (suelen durar ~4 horas o hasta
> cerrar el lab). Si los comandos de AWS empiezan a dar `ExpiredToken`, repetí
> este paso.

## 3. Ajustá el bucket del estado a tu cuenta

El estado de Terraform vive en un bucket S3 por cuenta:

```
tero-tfstate-<ACCOUNT_ID>
```

- Si usás **la cuenta de Fran** (`871694822674`), no tenés que tocar nada.
- Si tenés **tu propio Learner Lab** (otro Account ID), reemplazá el nombre del
  bucket en `infra/envs/dev/backend.tf`, `infra/envs/test/backend.tf` e
  `infra/envs/prod/backend.tf`.

## 4. Clonar el repositorio

```bash
git clone https://github.com/arenasFran/Tero-obligatorioDevOps.git
cd Tero-obligatorioDevOps
```

Mientras la PR #130 no esté fusionada en `main`, la infraestructura vive en la
rama `feat/terraform-infra`:

```bash
git checkout feat/terraform-infra
```

Cuando se fusione, clonás y trabajás directo sobre `main`.

## 5. Crear el bucket del estado (una sola vez)

```bash
aws s3api create-bucket --bucket tero-tfstate-<ACCOUNT_ID> --region us-east-1

aws s3api put-bucket-versioning \
  --bucket tero-tfstate-<ACCOUNT_ID> \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket tero-tfstate-<ACCOUNT_ID> \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-public-access-block \
  --bucket tero-tfstate-<ACCOUNT_ID> \
  --public-access-block-configuration \
  'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
```

## 6. Las imágenes de contenedor

No hace falta construir nada: el pipeline ya publicó las seis imágenes en GHCR
con el **SHA del commit** como tag. Ese SHA es el `image_tag` que está en cada
`.tfvars`.

Podés verificar que una imagen existe (requiere Docker):

```bash
docker manifest inspect ghcr.io/arenasfran/tero-obligatoriodevops-catalog:$(grep image_tag infra/envs/dev/dev.tfvars | sed 's/.*= //;s/"//g')
```

Si no tenés Docker, no importa: si la imagen no existiera, `terraform apply`
fallaría con un mensaje claro en el servicio.

## 7. Desplegar el ambiente `dev`

```bash
cd infra/envs/dev
terraform init
terraform plan  -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
```

Qué pasa en el primer `apply` (10–15 minutos):

1. Se crea la VPC, las subnets y los security groups.
2. Se crea RDS PostgreSQL, ElastiCache Redis y el clúster ECS.
3. Se crean los dos balanceadores (público e interno).
4. Una tarea one-off inicializa `catalogdb`, `cartdb` y `cart_items`.
5. Se crean los seis servicios y ECS arranca las tareas.

Para `test` y `prod` el procedimiento es idéntico, cambiando el directorio:

```bash
cd infra/envs/test && terraform init && terraform plan -var-file=test.tfvars -out=tfplan && terraform apply tfplan
cd infra/envs/prod && terraform init && terraform plan -var-file=prod.tfvars -out=tfplan && terraform apply tfplan
```

> En el laboratorio suele alcanzar con `dev` para mostrar todo; los tres
> ambientes juntos consumen presupuesto.

## 8. Verificar que todo funciona

```bash
./infra/scripts/smoke-test.sh dev
```

Recorre tienda, panel, catálogo, carrito, checkout y órdenes. Si imprime
`Smoke test completo: OK`, el despliegue está sano.

También podés ver las URLs:

```bash
terraform -chdir=infra/envs/dev output ui_url
terraform -chdir=infra/envs/dev output admin_url
```

## 9. Destruir cuando termines

El lab tiene presupuesto limitado: destruí antes de cerrar la sesión.

```bash
cd infra/envs/dev
terraform destroy -var-file=dev.tfvars
```

## 10. Problemas comunes

| Síntoma | Solución |
|---|---|
| `Error acquiring the state lock` | Quedó un lock de un `apply` interrumpido: `terraform force-unlock -force <ID>` (el ID aparece en el error) |
| El script falla con `exit status 126` | `chmod +x infra/scripts/*.sh` y volvé a aplicar |
| Después de un reboot de RDS, `carts` devuelve 500 | `aws ecs update-service --cluster tero-dev --service carts --force-new-deployment` |
| `ExpiredToken` en los comandos AWS | Repetí el paso 2 (credenciales nuevas) |
| Semgrep falla en el PR | Están documentadas las excepciones en `infra/README.md` |

## 11. Resumen de un minuto

```
Internet → ALB público :80 (ui) / :8081 (admin)
ui → ALB interno → catalog/carts/orders/checkout → RDS + ElastiCache Redis
```

- **Cloud Map** está bloqueado en AWS Academy, por eso los servicios internos se
  alcanzan con un ALB interno y Redis es ElastiCache (ADR 0004).
- **Secretos** en Secrets Manager; nada sensible en el repositorio.
- **Estado** en S3 cifrado, con versionado y lock.
- El `smoke-test.sh` es la prueba de que todo el camino funciona.
