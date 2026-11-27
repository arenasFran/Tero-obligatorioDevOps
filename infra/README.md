# Infraestructura en AWS

Este directorio contiene toda la infraestructura de Tero como código
(Terraform), el despliegue en ECS Fargate y los scripts de operación.

> Estado: **dev desplegado y verificado**. `test` y `prod` están definidos y
> validados, pero no aplicados (ver [Estado y cómo retomar](#estado-y-cómo-retomar)).

## Arquitectura

```
                              Internet
                                 │
                 ┌───────────────┴───────────────┐
                 │                               │
            ALB público :80                ALB público :8081
                 │                               │
                ui                            admin
                 │                               │
                 │                        RDS PostgreSQL 16
                 │                        (catalogdb, cartdb, orders)
                 │                               ▲
                 ▼                               │
          ALB interno ──────────────────────────┤
          ├ :8082 → catalog ────────────────────┤
          ├ :8083 → carts ──────────────────────┤
          ├ :8084 → orders ─────────────────────┤
          └ :8085 → checkout ── ElastiCache Redis
```

- **Un ALB público** expone la tienda (`:80`) y el panel (`:8081`).
- **Un ALB interno** conecta los cuatro microservicios HTTP. Reemplaza a Cloud
  Map, que AWS Academy bloquea (ver
  [ADR 0004](../docs/adr/0004-sin-cloud-map.md)).
- **RDS PostgreSQL** no es pública: solo acepta el puerto 5432 desde el security
  group de las tareas.
- **ElastiCache Redis** reemplaza al contenedor `redis` del compose.
- Todas las tareas corren en **subnets públicas** con IP pública para descargar
  imágenes, pero sin NAT Gateway (ahorro de aproximadamente USD 32/mes).
- Los secretos viven en **Secrets Manager**; las tareas los leen con `LabRole`.

## Estructura

```
infra/
├── modules/
│   ├── network/       # VPC, subnets, route table, security groups
│   ├── database/      # RDS, parameter group y secreto de credenciales
│   ├── redis/         # ElastiCache
│   ├── ecs-cluster/   # Clúster de ECS con Container Insights
│   ├── alb/           # ALB genérico (público o interno) con listeners
│   ├── ecs-service/   # Task definition + servicio + log group
│   └── stack/         # Compone un ambiente completo
├── envs/
│   ├── dev/           # 10.10.0.0/16
│   ├── test/          # 10.20.0.0/16
│   └── prod/          # 10.30.0.0/16
├── sql/init-db.sql    # Crea catalogdb, cartdb y cart_items (idempotente)
├── scripts/
│   ├── run-db-init.sh # Corre el SQL en una tarea one-off dentro de la VPC
│   └── smoke-test.sh  # Recorre el flujo completo por las URLs públicas
└── README.md
```

Cada ambiente tiene su `backend.tf` con el estado remoto en
`s3://tero-tfstate-871694822674/<ambiente>/terraform.tfstate`, cifrado con SSE-S3
y con `use_lockfile`.

## Requisitos

- Terraform >= 1.10
- AWS CLI v2 con credenciales de AWS Academy
- `curl` y `jq` (para el smoke test)
- Las imágenes de los seis servicios publicadas en GHCR con el tag del commit

El bucket del estado se crea una sola vez, fuera de Terraform (la letra lo
permite explícitamente):

```bash
aws s3api create-bucket --bucket tero-tfstate-871694822674 --region us-east-1
aws s3api put-bucket-versioning \
  --bucket tero-tfstate-871694822674 \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption \
  --bucket tero-tfstate-871694822674 \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block \
  --bucket tero-tfstate-871694822674 \
  --public-access-block-configuration \
  'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
```

## Cómo aplicar un ambiente

```bash
cd infra/envs/dev
terraform init
terraform plan  -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
```

`image_tag` en el `.tfvars` es el SHA del commit que publicó el pipeline en
GHCR. Tiene que existir; si no, ECS no puede descargar la imagen.

Para `test` y `prod` es idéntico, cambiando el directorio y el `.tfvars`.

### Destruir

El laboratorio tiene presupuesto limitado: conviene destruir antes de cerrar la
sesión de Academy.

```bash
cd infra/envs/dev
terraform destroy -var-file=dev.tfvars
```

El bucket del estado y el secreto se conservan porque no los administra este
`destroy` (el bucket) o porque se recrean con `recovery_window_in_days = 0`.

## Variables principales

| Variable | Descripción | Default |
|---|---|---|
| `region` | Región de AWS | — |
| `environment` | Nombre del ambiente (`dev`, `test`, `prod`) | — |
| `vpc_cidr` | Bloque CIDR de la VPC | — |
| `availability_zones` | Zonas de disponibilidad | — |
| `image_tag` | SHA del commit desplegado | — |
| `image_prefix` | Prefijo de las imágenes en GHCR | `ghcr.io/arenasfran/tero-obligatoriodevops` |
| `desired_count` | Tareas por servicio | `1` |
| `log_retention_days` | Retención de logs en CloudWatch | `7` |

## Outputs

| Output | Qué devuelve |
|---|---|
| `ui_url` | URL pública de la tienda |
| `admin_url` | URL pública del panel |
| `internal_alb_dns_name` | DNS del ALB interno que usan los microservicios |
| `redis_endpoint` | Host de ElastiCache |
| `database_endpoint` | Host de RDS |
| `database_secret_arn` | ARN del secreto con las credenciales |
| `cluster_name` | Nombre del clúster de ECS |

## Inicialización de la base

RDS solo crea la base `orders`. El recurso `null_resource.db_init` lanza una
tarea one-off con la imagen `postgres:16-alpine` que ejecuta
`infra/sql/init-db.sql` dentro de la VPC. El script es idempotente: crea
`catalogdb`, `cartdb` y la tabla `cart_items` solo si no existen.

Se vuelve a ejecutar si cambia el SQL (hash) o la task definition.

## Smoke test

```bash
./infra/scripts/smoke-test.sh dev
```

Recorre, solo con las URLs públicas:

1. health de la tienda y del panel;
2. login del panel con las credenciales de Secrets Manager;
3. alta de un producto;
4. lectura del catálogo a través del ALB interno;
5. alta y lectura del carrito (PostgreSQL);
6. checkout (Redis);
7. confirmación de la orden (orders → PostgreSQL);
8. lectura de la orden desde la tienda y desde el panel.

El producto se llama `Producto de prueba` y se reemplaza en cada corrida.

## Operación

```bash
# Logs de un servicio
aws logs tail /ecs/tero-dev/catalog --follow

# Estado de los servicios
aws ecs describe-services --cluster tero-dev \
  --services catalog carts orders checkout ui admin \
  --query 'services[].{servicio:serviceName,corriendo:runningCount,evento:events[0].message}'

# Salud de los target groups
aws elbv2 describe-target-health \
  --target-group-arn "$(aws elbv2 describe-target-groups \
    --names tero-dev-catalog --query 'TargetGroups[0].TargetGroupArn' --output text)"
```

### Si RDS se reinicia

`carts` mantiene una única conexión a PostgreSQL y no la reabre sola: después de
un reboot o failover de RDS devuelve `500` hasta reiniciarse. Se resuelve con:

```bash
aws ecs update-service --cluster tero-dev --service carts --force-new-deployment
```

## Deuda técnica conocida

| Tema | Por qué quedó así | Remediación |
|---|---|---|
| TLS hacia RDS desactivado (`rds.force_ssl=0`) | Las apps legacy usan `sslmode=disable` y no se pueden recompilar sin pasar por el pipeline (main exige aprobación externa) | Agregar `sslmode`/`ssl` configurable en catalog, orders, carts y admin; reconstruir imágenes; volver a `force_ssl=1` |
| `carts` no reconecta a PostgreSQL | Una conexión `psycopg2` por proceso, sin pool | Usar pool con reintentos o reconectar ante `OperationalError` |
| Despliegue manual | AWS Academy no permite OIDC hacia GitHub Actions | En una cuenta real, rol asumible por el workflow y `terraform apply` desde el runner |
| Una tarea por servicio | Costo del laboratorio | `desired_count >= 2` y auto scaling para producción |
| Sin HTTPS | No hay dominio ni certificado en el laboratorio | ACM + Route 53 y redirección 80 → 443 |

## Excepciones de Semgrep

El pipeline corre `semgrep scan --config auto --error`, que incluye reglas de
Terraform. Estas están suprimidas con `# nosemgrep` y su justificación:

| Regla | Motivo de la excepción |
|---|---|
| `aws-secretsmanager-secret-unencrypted` | Secrets Manager ya cifra en reposo con la clave gestionada `aws/secretsmanager`; una CMK propia requiere `kms:CreateKey`, que AWS Academy bloquea |
| `aws-cloudwatch-log-group-unencrypted` | CloudWatch Logs cifra en reposo con claves del servicio; una CMK propia requiere `kms:CreateKey`, bloqueado |
| `aws-elb-access-logs-not-enabled` | Los logs de aplicación ya se centralizan en CloudWatch; los access logs del ALB se agregan con el módulo de observabilidad |
| `insecure-load-balancer-tls-version` | Sin dominio ni certificado en el laboratorio, el ALB solo publica HTTP; en producción se agrega 443 + ACM + redirección |

Corregidas de raíz (no suprimidas): backups de RDS a 1 día, exportación de logs
de PostgreSQL a CloudWatch y subnets sin asignación automática de IP pública.

## Justificación frente a la letra

Cómo cada decisión de este módulo responde a un punto del obligatorio:

| Punto | Cómo se cumple acá |
|---|---|
| **3.2** Registry de imágenes | GHCR, publicadas por el pipeline en `.github/workflows/build.yml` |
| **3.3** Orquestación en nube | ECS Fargate con seis servicios |
| **7.1** IaC con Terraform | Todo en `infra/`, salvo el bucket del estado (la letra lo permite explícitamente) |
| **7.2** Modularización | `modules/{stack,alb,ecs-service,redis,network,database,ecs-cluster}` |
| **7.2** Variables por ambiente | `envs/{dev,test,prod}` con CIDR e `image_tag` propios |
| **7.2** Outputs documentados | `outputs.tf` con `description` en cada módulo y ambiente |
| **7.2** Secretos seguros | Secrets Manager + `random_password`; el estado remoto se cifra en S3 (SSE-S3); ningún secreto en el repositorio |
| **7.2** Estado remoto | S3 con versionado, cifrado y `use_lockfile` |
| **8** Observabilidad (base) | Logs centralizados en CloudWatch y Container Insights activado; dashboard y alertas se completan en su módulo |
| **7.3** Serverless | Pendiente, módulo aparte (ver más abajo) |

> Nota: `rds.force_ssl=0` y el ALB en HTTP son concesiones del laboratorio
> (sin CMK, sin dominio y sin poder recompilar las apps sin pasar por `main`).
> Están documentadas como deuda arriba y se justifican en la defensa.

## Estado y cómo retomar

**Hecho y verificado (2026-11-27)**

- `dev` aplicado: VPC, RDS, ElastiCache, dos ALB, seis servicios ECS, secretos e
  inicialización de la base.
- Los seis target groups en `healthy`.
- Smoke test completo en verde.

**Definido pero no aplicado**

- `test` y `prod`: mismos módulos, distinto CIDR y estado remoto. Se aplican con
  el mismo procedimiento cuando haya presupuesto en el laboratorio.

**Próximos módulos (aparte de infraestructura)**

1. **Serverless**: Lambda con EventBridge o API Gateway, con un propósito de
   seguridad u observabilidad (por ejemplo, rotación de secretos o alertas).
2. **Observabilidad**: dashboard de CloudWatch con métricas de ECS/ALB, y al
   menos dos alarmas con procedimiento de respuesta.
3. **Deploy automatizado**: script de despliegue por ambiente mientras no haya
   OIDC.

Para retomar: `terraform init && terraform plan -var-file=dev.tfvars` en
`infra/envs/dev`, y correr `./infra/scripts/smoke-test.sh dev` como línea base.
