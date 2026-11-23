# Pruebas automatizadas

## Decisión

Se usan pruebas funcionales de API con Newman y una colección Postman versionada en `tests/postman/tero-api.postman_collection.json`. Newman ejecuta la colección sin depender de una cuenta Postman.

Las pruebas recorren la UI como gateway y verifican:

1. Que el catálogo devuelva productos iniciales y guarda el identificador y precio de uno.
2. Que ese mismo producto se pueda agregar al carrito y luego recuperar con la cantidad y el precio esperados.

Esto cubre la integración de la UI con los servicios de catálogo y carrito. El carrito se limpia al final de la colección; además, cada ejecución de CI usa una base efímera.

## Ejecución en CI

El workflow `.github/workflows/build.yml` corre en cada pull request hacia `main` y en cada push a `main`. Construye las seis imágenes, levanta el stack de Docker Compose con credenciales aleatorias de uso temporal y ejecuta Newman contra `http://localhost:8080`.

Si un servicio no compila, no está disponible o falla una aserción de la colección, el check de Actions falla. No se usan credenciales de ambientes reales.

## Ejecución local

Con Docker Compose y Node.js instalados, completar `.env` usando `.env.example`. Si el stack habitual ya está levantado, detenerlo primero porque la UI usa los puertos `8080` y `8081`. Levantar el stack de pruebas con un nombre de proyecto separado para no reutilizar el volumen de desarrollo:

```bash
docker compose -p tero-api-test up --build --detach
```

En otra terminal, ejecutar la misma colección que usa CI:

```bash
npx --yes newman@6.2.3 run tests/postman/tero-api.postman_collection.json \
  --env-var "baseUrl=http://localhost:8080" \
  --env-var "customerId=local-api-test"
```

Al terminar, detener el stack y limpiar los datos locales de prueba:

```bash
docker compose -p tero-api-test down --volumes
```
