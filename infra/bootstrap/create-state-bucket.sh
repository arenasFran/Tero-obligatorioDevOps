#!/usr/bin/env bash
#
# Crea y configura el bucket S3 donde Terraform guarda el estado de los tres
# ambientes. Se ejecuta una sola vez por cuenta.
#
# Por qué no lo gestiona Terraform: la organización de AWS Academy aplica un
# service control policy que niega s3:GetBucketObjectLockConfiguration. El
# proveedor de AWS lee esa configuración al administrar un bucket, así que
# cualquier `aws_s3_bucket` falla con AccessDenied. La letra permite crear el
# bucket del estado fuera de Terraform, así que se crea con este script.
#
# Uso:
#   ./create-state-bucket.sh [nombre-del-bucket]

set -euo pipefail

bucket="${1:-tero-tfstate-871694822674}"
region="${AWS_REGION:-us-east-1}"

if aws s3api head-bucket --bucket "$bucket" 2>/dev/null; then
  echo "El bucket $bucket ya existe; se reaplica la configuración."
else
  echo "Creando el bucket $bucket en $region."
  if [[ "$region" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$bucket" --region "$region" >/dev/null
  else
    aws s3api create-bucket --bucket "$bucket" --region "$region" \
      --create-bucket-configuration LocationConstraint="$region" >/dev/null
  fi
fi

echo "Habilitando versionado."
aws s3api put-bucket-versioning \
  --bucket "$bucket" \
  --versioning-configuration Status=Enabled

echo "Bloqueando el acceso público."
aws s3api put-public-access-block \
  --bucket "$bucket" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "Exigiendo cifrado en reposo."
aws s3api put-bucket-encryption \
  --bucket "$bucket" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'

echo "Fijando propiedad de los objetos a la cuenta."
aws s3api put-bucket-ownership-controls \
  --bucket "$bucket" \
  --ownership-controls '{"Rules":[{"ObjectOwnership":"BucketOwnerEnforced"}]}'

echo
echo "Verificación:"
aws s3api get-bucket-versioning --bucket "$bucket"
aws s3api get-public-access-block --bucket "$bucket" --output json
