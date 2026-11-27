# Estrategia de ramificación

## Estrategia elegida
GitHub Flow: una rama permanente (`main`) y ramas cortas por tarea que se integran mediante Pull Request.

## Justificación
- El equipo es chico (2 personas) y trabaja en un solo repositorio.
- Hay un único camino a producción: no se mantienen versiones en paralelo.
- Git Flow agrega `develop`, `release/*` y `hotfix/*`, lo que sería burocracia innecesaria para este equipo.
- Trunk-Based Development requiere feature flags y alta cobertura de tests, que Tero todavía no tiene.
- Si el equipo creciera o hubiera que mantener varias versiones a la vez, se reevaluaría Git Flow.

## Reglas del equipo
- `main` siempre debe estar desplegable y está protegida (ruleset `protect-main`).
- Nadie empuja directo a `main`: todo entra por PR.
- Cada PR necesita 1 aprobación de un integrante distinto al autor.
- Nombres de rama: `feature/`, `docs/`, `fix/` seguido de una descripción corta.
- Cada PR referencia su issue con `Closes #N`.
- Se borra la rama después del merge.

## Relación con los ambientes
Dev, Test y Prod no son ramas permanentes. El código entra por Pull Request a `main`; desde ahí se despliega a Dev y Test. Prod se despliega a partir de un tag de versión `v*` (por ejemplo, `v1.0.0`) creado sobre un commit de `main` que ya pasó Test.

Los environments de GitHub están configurados así:

- **Dev:** permite despliegues desde la rama `main`, sin aprobación manual.
- **Test:** permite despliegues desde la rama `main`, sin aprobación manual.
- **Prod:** permite despliegues desde tags `v*` y requiere la aprobación de `MacDuki`. Está activada la prevención de autoaprobación y los administradores no pueden omitir la regla.

El pipeline debe construir el artefacto una sola vez y promover ese mismo artefacto de Dev a Test y luego a Prod, siempre que pase los quality gates de calidad y seguridad. El tag de Prod identifica el commit aprobado; no implica mantener una rama `prod`.
