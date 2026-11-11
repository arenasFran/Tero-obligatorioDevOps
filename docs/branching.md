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
- `main` siempre debe estar desplegable y está protegida (ruleset `proteger-main`).
- Nadie empuja directo a `main`: todo entra por PR.
- Cada PR necesita 1 aprobación de un integrante distinto al autor.
- Nombres de rama: `feature/`, `docs/`, `fix/` seguido de una descripción corta.
- Cada PR referencia su issue con `Closes #N`.
- Se borra la rama después del merge.

## Relación con los ambientes
Dev, Test y Prod no son ramas. Todos los ambientes se despliegan desde `main` y el pipeline promueve el mismo artefacto de uno al siguiente, siempre que pase los quality gates de calidad y seguridad.
