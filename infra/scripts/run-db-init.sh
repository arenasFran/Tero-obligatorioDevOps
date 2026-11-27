#!/usr/bin/env bash
#
# Ejecuta infra/sql/init-db.sql contra RDS usando una tarea de ECS.
#
# RDS no es accesible desde internet, así que el SQL no puede correr desde la
# máquina que aplica Terraform. Se lanza una tarea one-off con la imagen de
# PostgreSQL dentro de la VPC, que sí llega a la base.
#
# Lo invoca el recurso null_resource.db_init del módulo stack. También se puede
# ejecutar a mano con las mismas variables de entorno.

set -euo pipefail

: "${AWS_REGION:?Falta AWS_REGION}"
: "${CLUSTER:?Falta CLUSTER}"
: "${TASK_DEFINITION:?Falta TASK_DEFINITION}"
: "${SUBNETS:?Falta SUBNETS}"
: "${SECURITY_GROUPS:?Falta SECURITY_GROUPS}"
: "${LOG_GROUP:?Falta LOG_GROUP}"
: "${SQL_B64:?Falta SQL_B64}"

overrides=$(python3 - "$SQL_B64" <<'PY'
import json
import sys

sql_b64 = sys.argv[1]
print(json.dumps({
    "containerOverrides": [{
        "name": "psql",
        "environment": [{"name": "SQL_B64", "value": sql_b64}],
        "command": [
            "sh", "-c",
            'echo "$SQL_B64" | base64 -d > /tmp/init.sql && '
            'psql -v ON_ERROR_STOP=1 -d orders -f /tmp/init.sql'
        ],
    }]
}))
PY
)

echo "Lanzando la tarea de inicialización de la base..."
task_arn=$(aws ecs run-task \
  --region "$AWS_REGION" \
  --cluster "$CLUSTER" \
  --task-definition "$TASK_DEFINITION" \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[${SUBNETS}],securityGroups=[${SECURITY_GROUPS}],assignPublicIp=ENABLED}" \
  --overrides "$overrides" \
  --query 'tasks[0].taskArn' \
  --output text)

if [[ -z "$task_arn" || "$task_arn" == "None" ]]; then
  echo "No se pudo lanzar la tarea de inicialización." >&2
  exit 1
fi

echo "Tarea: $task_arn"
aws ecs wait tasks-stopped --region "$AWS_REGION" --cluster "$CLUSTER" --tasks "$task_arn"

exit_code=$(aws ecs describe-tasks \
  --region "$AWS_REGION" \
  --cluster "$CLUSTER" \
  --tasks "$task_arn" \
  --query 'tasks[0].containers[0].exitCode' \
  --output text)

if [[ "$exit_code" != "0" ]]; then
  echo "La inicialización falló (exit code: $exit_code)." >&2
  aws ecs describe-tasks \
    --region "$AWS_REGION" \
    --cluster "$CLUSTER" \
    --tasks "$task_arn" \
    --query 'tasks[0].stoppedReason' \
    --output text >&2 || true
  echo "Últimos logs:" >&2
  aws logs tail "$LOG_GROUP" --since 15m --region "$AWS_REGION" >&2 || true
  exit 1
fi

echo "Base inicializada correctamente."
