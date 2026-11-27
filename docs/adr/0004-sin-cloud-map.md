# ADR 0004 — Descubrimiento sin Cloud Map: ALB interno y ElastiCache

- **Estado:** aceptada
- **Fecha:** 2026-11-27
- **Contexto:** despliegue en AWS Academy con ECS Fargate

## Contexto

En `docker compose` los servicios se encuentran por nombre (`catalog`, `carts`,
`redis`) porque comparten una red y Docker resuelve el DNS. En ECS cada tarea
tiene una dirección IP efímera, así que hace falta un mecanismo de
descubrimiento.

La opción natural es AWS Cloud Map. Se intentó crear el espacio de nombres y
AWS Academy lo bloqueó:

```
AccessDeniedException: ... is not authorized to perform:
servicediscovery:CreatePrivateDnsNamespace ...
```

También se probó `CreateHttpNamespace`, con el mismo resultado. La cuenta del
laboratorio no permite crear roles de IAM, así que no se puede ampliar la
política. Además, un balanceador de aplicación no puede distribuir tráfico TCP,
de modo que Redis tampoco puede resolverse con un ALB.

## Decisión

1. **Cuatro servicios HTTP internos** (`catalog`, `carts`, `orders`,
   `checkout`) se publican en un **ALB interno**, con un puerto por servicio:

   | Servicio | Puerto del ALB interno |
   |---|---|
   | catalog | 8082 |
   | carts | 8083 |
   | orders | 8084 |
   | checkout | 8085 |

   La UI los consume como `http://<alb-interno>:<puerto>`.

2. **Redis se reemplaza por ElastiCache** (`cache.t4g.micro`, Redis 7.1). Su
   endpoint es un nombre DNS estable que entrega AWS, sin necesidad de
   descubrimiento propio.

3. **No se usa Cloud Map** ni los nombres `*.local`. El `docker-compose.yml`
   local sigue funcionando como antes; el cambio aplica solo a la nube.

## Alternativas consideradas

| Alternativa | Por qué se descartó |
|---|---|
| Cloud Map con DNS privado | `servicediscovery:CreatePrivateDnsNamespace` denegado por la política del laboratorio |
| Cloud Map con namespace HTTP | `servicediscovery:CreateHttpNamespace` denegado por la misma política |
| NLB + registro dinámico de IPs | Requiere una Lambda o un script que actualice los targets en cada despliegue; agrega piezas y un punto de falla |
| Redis como servicio de ECS | Sin Cloud Map no hay forma estable de alcanzarlo: el ALB no balancea TCP |
| ECS Service Connect | Gestiona Cloud Map por debajo; no se pudo verificar que el laboratorio permita esas llamadas |

## Consecuencias

**Positivas**

- No depende de permisos que el laboratorio bloquea.
- El ALB interno aporta health checks y métricas de acceso por servicio.
- ElastiCache entrega un endpoint estable, persistencia y una caché separada
  del ciclo de vida de las tareas.
- El ALB interno no es público: solo acepta tráfico desde el CIDR de la VPC.

**Negativas / costos**

- Un ALB interno adicional cuesta aproximadamente USD 16/mes (sin contar LCU).
- El puerto forma parte del contrato entre servicios: si cambia, hay que
  actualizar las variables de la UI.
- Se pierde la resolución por nombre dentro de la VPC; los logs muestran
  direcciones IP en lugar de nombres de servicio.
- Hay un salto más en el camino de cada request interno.

## Verificación

```bash
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[].{nombre:LoadBalancerName,interno:Scheme}'
# tero-dev-alb       internet-facing
# tero-dev-internal  internal

aws ecs describe-services --cluster tero-dev --services catalog \
  --query 'services[0].serviceRegistries'   # vacío: no hay Cloud Map
```

El smoke test recorre `ui → ALB interno → catalog/carts/checkout/orders` y
falla si cualquiera de los saltos no responde.

## Referencias

- `infra/modules/alb/main.tf`
- `infra/modules/redis/main.tf`
- `infra/modules/stack/main.tf`
- `infra/modules/network/main.tf`
- `infra/scripts/smoke-test.sh`
