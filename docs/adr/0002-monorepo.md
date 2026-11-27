# ADR 0002 — Un solo repositorio para aplicación, pipelines e infraestructura

- **Estado:** aceptada
- **Fecha:** 2026-11-26
- **Contexto:** obligatorio DevOps, equipo de dos personas, AWS Academy

## Contexto

El proyecto tiene que entregarse con seis microservicios, los pipelines de CI/CD,
la infraestructura como código (Terraform), las pruebas de API y la documentación.
La letra pide almacenar todo el código —aplicación, pipelines, IaC y configuración—
en repositorio o repositorios Git, sin imponer una cantidad.

Las condiciones que importan para decidir:

- El equipo son **dos personas**. Cada PR necesita la aprobación del otro, así que
  cuanta menos coordinación entre repositorios, mejor.
- Un cambio de infraestructura suele venir acompañado de un cambio en el workflow
  o en las variables de la aplicación. Si viven en repos distintos, ese cambio se
  parte en dos PRs que hay que mergear en orden.
- La entrega es **un único archivo** de hasta 40 MB que debe contener el repositorio
  completo. Un solo repositorio simplifica el armado del zip.
- La cuenta de AWS es **Academy**: los roles y permisos no se administran desde el
  repositorio, así que no hay un motivo de seguridad para separar la infraestructura.

## Decisión

Un único repositorio, con separación explícita por directorio:

```
.
├── src/            # los seis microservicios
├── tests/          # colección Postman/Newman
├── .github/        # workflows y scripts de CI
├── infra/          # Terraform: bootstrap, módulos y ambientes
└── docs/           # ADRs, guías, diagramas y evidencias
```

La separación de componentes se garantiza por estructura de directorios y por
revisión en el PR, no por repositorios distintos.

## Alternativas consideradas

| Alternativa | Por qué se descartó |
|---|---|
| Un repositorio por microservicio | Seis PRs para un cambio transversal, seis tableros de issues y seis configuraciones de CI. Con dos personas el costo de coordinación supera el beneficio |
| Repositorio de aplicación + repositorio de infraestructura | Es la separación más común en equipos grandes, pero obliga a sincronizar dos PRs por cada cambio que toca imagen y despliegue, y a versionar el tag de imagen entre repositorios |
| Un repositorio por ambiente (dev/test/prod) | Los ambientes se diferencian por `.tfvars`, no por código. Duplicar el repositorio garantiza que se desincronicen |

## Consecuencias

**Positivas**

- Un cambio de aplicación y su cambio de infraestructura viajan en el mismo PR y
  se revisan juntos.
- Una sola configuración de checks requeridos en `main`.
- El zip de entrega se arma con un `git archive` del repositorio.
- El historial muestra la evolución completa del proyecto en un solo lugar.

**Negativas / costos**

- Los permisos de GitHub son por repositorio: no se puede dar acceso de lectura a
  la infraestructura sin darlo también al código.
- El pipeline tiene que filtrar por rutas (`paths:`) para no reconstruir las seis
  imágenes cuando solo cambió la documentación.
- El repositorio crece con el historial de imágenes y evidencias; hay que cuidar
  el tamaño para no acercarse al límite de 40 MB de la entrega.

## Verificación

```bash
# La separación existe y es explícita
ls -d src tests .github infra docs

# Un PR puede tocar aplicación e infraestructura a la vez
git log --oneline --name-only -1 <commit-de-infra>
```

## Referencias

- `README.md` — estructura del repositorio
- `docs/branching.md` — GitHub Flow sobre `main`
- Letra del obligatorio, sección 6 (Control de Versiones)
