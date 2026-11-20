# ADR 0001 — Secretos fuera del repositorio

- **Estado:** aceptada
- **Fecha:** 2026-11-20
- **Contexto:** auditoría técnica previa a la ronda de inversión

## Contexto

El repositorio contenía credenciales en texto plano:

- `docker-compose.yml`: una contraseña de desarrollo repetida en la base y en cuatro servicios, `ADMIN_PASSWORD: admin` y un secreto JWT por defecto.
- `src/admin/src/app.ts`: los mismos valores como *fallback* de `process.env`, es decir, credenciales válidas embebidas en el código.
- `README.md`: publicaba las credenciales del panel.
- La base y Redis se publicaban en `5433` y `6379` del host.

El repositorio es público, así que cualquier valor versionado debe considerarse comprometido.

## Decisión

1. **`.env` no versionado** (incluido en `.gitignore`) y **`.env.example` versionado** con las claves y valores vacíos.
2. **Compose interpola desde `.env`** usando `${VAR:?mensaje}`. Si la variable falta, el arranque falla con un mensaje explícito en lugar de continuar con un valor por defecto.
3. **La aplicación no tiene credenciales por defecto.** `src/admin/src/app.ts` valida al arrancar y aborta si falta una variable o si el secreto JWT mide menos de 32 caracteres.
4. **`db` y `redis` no publican puertos.** Solo son accesibles desde la red interna de Compose; `ui` (8080) y `admin` (8081) siguen siendo la entrada del sistema.
5. **Cada integrante genera su propio `.env`** con valores aleatorios. No se comparten secretos por chat ni por issues.
6. **En la nube los secretos no viven en `.env`**: se administran con SSM Parameter Store o Secrets Manager y los servicios los leen a través de su rol de IAM.

## Alternativas consideradas

| Alternativa | Por qué se descartó |
|---|---|
| Mantener valores por defecto "solo para desarrollo" | El entorno de desarrollo es el que se filtra; un default conocido es una credencial válida |
| Docker secrets | Requiere Swarm o variables de archivo; no aporta sobre `.env` en desarrollo local y complica el `compose` |
| SOPS / age para cifrar el `.env` | Agrega una dependencia y una clave que administrar, sin beneficio para secretos locales descartables |
| Exportar variables en el shell | No queda documentado qué variables necesita el sistema; `.env.example` cumple ese rol |

## Consecuencias

**Positivas**

- Ningún secreto en el repositorio ni en su historial a partir de este cambio.
- Un despliegue mal configurado falla rápido y con un mensaje claro.
- La base y Redis dejan de ser alcanzables desde la red del host.
- El mismo mecanismo (`variables de entorno`) es el que usan ECS y Terraform, así que el paso a la nube no cambia el modelo.

**Negativas / costos**

- Hay un paso manual: `cp .env.example .env` y completar valores.
- Cambiar la contraseña de Postgres no actualiza un volumen ya inicializado; hace falta `docker compose down -v`.
- Quien clone el repo sin leer el README va a ver el arranque fallar. El mensaje de error indica exactamente qué falta.

## Verificación

```bash
docker compose config --quiet        # sintaxis e interpolación
grep -nE "PASSWORD|SECRET" docker-compose.yml   # solo interpolaciones ${...}, sin valores
git check-ignore -v .env             # .env ignorado
```

## Referencias

- `docker-compose.yml`
- `.env.example`
- `src/admin/src/app.ts`
