# Bootstrap del estado de Terraform

Crea el bucket S3 donde los tres ambientes guardan su `terraform.tfstate`.

## Por qué no lo gestiona Terraform

La organización de AWS Academy aplica un *service control policy* que niega
`s3:GetBucketObjectLockConfiguration`. El proveedor de AWS lee esa configuración
cada vez que administra un bucket, así que cualquier recurso `aws_s3_bucket`
falla:

```
AccessDenied: not authorized to perform: s3:GetBucketObjectLockConfiguration
... with an explicit deny in a service control policy
```

La letra del obligatorio permite explícitamente crear el bucket del estado de
Terraform fuera de Terraform. Por eso este directorio contiene un script
idempotente en lugar de archivos `.tf`.

## Uso

```bash
cd infra/bootstrap
./create-state-bucket.sh
```

Se puede ejecutar las veces que haga falta: si el bucket existe, solo reaplica
la configuración.

## Qué configura

| Propiedad | Valor | Motivo |
|---|---|---|
| Versionado | Habilitado | Permite recuperar un estado anterior si un `apply` lo corrompe |
| Acceso público | Bloqueado | El estado puede contener datos sensibles |
| Cifrado | SSE-S3 (AES256) | Cifrado en reposo sin administrar claves propias |
| Propiedad de objetos | `BucketOwnerEnforced` | Deshabilita ACL y simplifica los permisos |

## Cómo lo usan los ambientes

Cada ambiente declara este backend:

```hcl
terraform {
  backend "s3" {
    bucket       = "tero-tfstate-871694822674"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

`use_lockfile` usa el bloqueo nativo de S3: no hace falta una tabla DynamoDB.
Requiere Terraform 1.10 o superior.

## Consecuencia

El bucket no se destruye con `terraform destroy` porque no está en ningún estado.
Es intencional: perder el bucket obliga a importar toda la infraestructura a mano.
