# ADR 0003 — CloudWatch como plataforma única de observabilidad

- **Estado:** aceptada
- **Fecha:** 2026-11-26
- **Contexto:** obligatorio DevOps, despliegue en ECS Fargate sobre AWS Academy

## Contexto

La letra pide cuatro cosas para el sistema desplegado:

1. Recolectar métricas de infraestructura (CPU, memoria, red) o de aplicación
   (latencia, tasa de errores, throughput).
2. Centralizar los logs de todos los servicios en una plataforma única, con
   formato estructurado que permita búsquedas y filtros.
3. Al menos un dashboard con métricas relevantes.
4. Al menos dos alertas, cada una con condición de disparo y procedimiento de
   respuesta.

Sugiere CloudWatch, Prometheus, Grafana, Loki, OpenTelemetry "u otras equivalentes",
sin imponer ninguna.

El contexto técnico del proyecto:

- La aplicación corre en **ECS Fargate**, no en Kubernetes.
- La cuenta es **AWS Academy**: presupuesto acotado, sin roles IAM propios y con
  credenciales que caducan cada pocas horas.
- El equipo son **dos personas** y tiene que poder operar y explicar la solución.
- Los servicios `cart`, `catalog` y `orders` ya exponen `/metrics` en formato
  Prometheus; `ui`, `checkout` y `admin` no.

## Decisión

**CloudWatch** como única plataforma de observabilidad, con este reparto:

| Necesidad | Implementación |
|---|---|
| Métricas de infraestructura | **Container Insights** para CPU, memoria y red de las tareas ECS |
| Métricas de aplicación | Métricas del **Application Load Balancer**: latencia, throughput y tasa de 5xx |
| Logs centralizados | Driver `awslogs`, un log group por servicio, salida en JSON |
| Dashboard | `aws_cloudwatch_dashboard` definido en Terraform |
| Alertas | Dos alarmas de CloudWatch que publican en SNS; una Lambda procesa el cambio de estado |

La recolección de métricas de aplicación desde los endpoints `/metrics` se deja
fuera del alcance inicial. CloudWatch no los scrapea de forma nativa y hacerlo
requiere un sidecar ADOT o Prometheus gestionado, que agrega componentes sin
sumar un requisito de la letra.

## Alternativas consideradas

| Alternativa | Por qué se descartó |
|---|---|
| Prometheus + Grafana + Loki | Cubre lo mismo, pero exige mantener tres servicios encendidos las 24 horas. En Fargate son al menos dos tareas más por ambiente (~USD 18/mes) más almacenamiento persistente, sobre un presupuesto de Academy ya ajustado |
| Prometheus + Grafana sobre CloudWatch como fuente | Agrega complejidad sin beneficio: el dashboard se puede hacer nativo en CloudWatch |
| Datadog / New Relic / Grafana Cloud | Sacan los datos de la cuenta de AWS, requieren una cuenta externa y una API key que rotar. El plan gratuito tiene retención corta y el costo escala por host |
| Solo logs, sin métricas | No cumple el punto 1 de la letra |

## Consecuencias

**Positivas**

- Una sola herramienta cubre los cuatro requisitos, y una sola cosa que explicar
  en la defensa.
- No hay servidores de observabilidad que mantener ni actualizar.
- Las métricas de ECS y ALB no requieren instrumentación: existen desde que el
  servicio arranca.
- Las alarmas se integran con EventBridge, que es el disparador de la Lambda del
  componente serverless.
- Todo se define en Terraform, igual que el resto de la infraestructura.

**Negativas / costos**

- Dependencia del proveedor: migrar a Prometheus implicaría reescribir dashboards
  y alarmas.
- La retención de logs por defecto es de 7 días; hay que fijarla explícitamente
  para no pagar almacenamiento indefinido.
- Las consultas se hacen con CloudWatch Logs Insights, un lenguaje propio que el
  equipo tiene que aprender.
- Los `/metrics` que ya exponen tres servicios quedan sin recolectar. Se documenta
  como mejora futura, no como deuda oculta.

## Verificación

```bash
# Las tareas envían logs al log group del servicio
aws logs describe-log-groups --log-group-name-prefix /ecs/tero-dev

# Container Insights está activo en el cluster
aws ecs describe-clusters --clusters tero-dev \
  --include SETTINGS --query 'clusters[0].settings'

# Las dos alarmas existen y tienen acción asociada
aws cloudwatch describe-alarms --alarm-name-prefix tero-dev \
  --query 'MetricAlarms[].{Nombre:AlarmName,Accion:AlarmActions}'

# El dashboard existe
aws cloudwatch list-dashboards --dashboard-name-prefix tero-dev
```

## Referencias

- `docs/security.md` — hallazgos y remediaciones
- Cards #107 a #111 del tablero
- Letra del obligatorio, sección 8 (Observabilidad)
