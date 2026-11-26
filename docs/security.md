# Seguridad en CI

El workflow [build.yml](../.github/workflows/build.yml) ejecuta análisis en
Pull Requests a `main` y en cada push a `main`:

- **SAST:** Semgrep analiza el código con `--error`; cualquier hallazgo falla
  el job.
- **SCA:** Trivy analiza los manifiestos y lockfiles versionados. El umbral es
  cero vulnerabilidades `HIGH` o `CRITICAL`; el job falla si encuentra alguna.
- **Secretos:** Gitleaks revisa los commits agregados por cada Pull Request o
  push y falla si detecta credenciales expuestas. Si aparece una credencial
  real, hay que revocarla y rotarla; borrarla del último commit no elimina las
  versiones anteriores.
- **Imágenes:** Trivy analiza las seis imágenes de los servicios, incluyendo
  paquetes del sistema y dependencias incluidas en la imagen. Una vulnerabilidad
  `HIGH` o `CRITICAL` bloquea el job.

En Pull Requests, `Build and test microservices / Build and scan container
images` ejecuta el escaneo después de las pruebas de integración. Los análisis
de calidad, dependencias y secretos corren en jobs separados para que el fallo
de un escáner no oculte el resultado de otro. En `main`, el job
`Scan and publish images to GHCR` reconstruye cada servicio, escanea todas las
imágenes y solo las publica si todas pasan. El tag es el SHA completo del
commit; no se publica `latest`.

Las imágenes se publican en GitHub Container Registry con nombres como
`ghcr.io/<owner>/<repo>-catalog:<sha>`. La publicación requiere que la ejecución
sea un push a `main` y usa `GITHUB_TOKEN` con `packages: write` limitado a ese
job. No requiere guardar una contraseña de registry como secret.

El pipeline presenta los resultados como checks de GitHub Actions. Para que
bloqueen el merge, los checks de calidad, integración, seguridad y análisis de
imágenes deben estar marcados como requeridos en el ruleset de `main`.

## Inventario inicial

Escaneo local del 25-11-2026 con Trivy 0.76.2, limitado a vulnerabilidades
`HIGH` y `CRITICAL`. Los números son hallazgos por target de Trivy, no CVE
únicas; el mismo CVE puede afectar varios paquetes.

| Servicio | Dependencias desde manifiestos `HIGH/CRITICAL` | Imagen `HIGH/CRITICAL` |
| --- | ---: | ---: |
| `catalog` | 0 / 0 | 2 / 0 |
| `carts` | 0 / 0 | 57 / 0 |
| `orders` | 19 / 2 | 44 / 2 |
| `checkout` | 76 / 6 | 33 / 1 |
| `ui` | Sin lockfile analizable | 10 / 0 |
| `admin` | Sin lockfile analizable | 10 / 0 |

`ui` y `admin` tienen `package.json`, pero no lockfiles; Trivy filesystem no
pudo resolver sus grafos desde los manifiestos. El escaneo de imagen sí encontró
dependencias vulnerables en ambas. `carts` no presenta alertas en su archivo de
requisitos, pero la imagen incluye alertas del sistema operativo y Starlette.

## Remediaciones aplicadas

| Hallazgo | Cambio | Validación |
| --- | --- | --- |
| `catalog`: CVE-2026-33815 en `github.com/jackc/pgx/v5` 5.6.0 | Actualizado `pgx` a 5.13.0. Su requisito de Go llevó el builder primero a 1.25.4; el cambio posterior de `x/net` elevó el builder final a 1.27.4. `go get` también actualizó dependencias transitivas. | El reescaneo local ya no reporta esta CVE y el build de la imagen terminó correctamente. |
| `catalog`: CVE-2026-33186 y hallazgos posteriores en `google.golang.org/grpc` 1.73.0 | Actualizado gRPC a 1.83.2; `go get` ajustó dependencias transitivas. Se eligió 1.83.2 porque Trivy también reportó tres vulnerabilidades `HIGH` en 1.79.3. | El reescaneo local ya no reporta vulnerabilidades de gRPC ni hallazgos `CRITICAL`; el build de la imagen terminó correctamente. En ese paso quedaban tres `HIGH` en otras dependencias. |
| `catalog`: CVE-2026-78661 y CVE-2026-78669 en `golang.org/x/net` 0.58.0 | Actualizado `golang.org/x/net` a 0.62.0, versión corregida indicada por Trivy, y el builder a Go 1.27.4, ya que `x/net` 0.62.0 requiere Go 1.26 o superior. `go get` ajustó dependencias transitivas. | El reescaneo local ya no reporta estas CVE, y el build de la imagen terminó correctamente. Queda un hallazgo `HIGH` en `github.com/klauspost/compress`; no quedan hallazgos `CRITICAL`. |
| `catalog`: CVE-2026-63209 en `github.com/klauspost/compress` 1.17.11 | Actualizado a 1.18.7, versión corregida indicada por Trivy. | Build y reescaneo final de imagen sin hallazgos `HIGH/CRITICAL`. |
| `orders`: CVE-2026-33815/33816 en `pgx` 5.6.0; avisos de `x/crypto`, `x/net` y `x/text` | Actualizados a `pgx` 5.13.0, `x/crypto` 0.58.0, `x/net` 0.62.0 y `x/text` 0.43.0; el grafo requiere Go 1.26, por eso el módulo usa `go 1.26.0` y el builder Go 1.27.4. | Build local correcto; Trivy final reporta cero hallazgos `HIGH/CRITICAL` en manifiestos e imagen. |
| `catalog`, `orders`, `checkout`, `ui`, `admin` y `carts`: paquetes del sistema operativo en las imágenes | Se actualizaron los paquetes disponibles durante el build (`apk upgrade` en Alpine, `apt-get upgrade` en Debian). Para `carts`, se cambió la base de Debian a `python:3.12-alpine`, que no conserva los hallazgos Debian sin versión corregida disponible. | Las seis imágenes se reconstruyeron; Trivy final reporta cero hallazgos `HIGH/CRITICAL`. |
| `checkout`: dependencias de JavaScript vulnerables, incluidas `multer`, `js-yaml`, `lodash`, `path-to-regexp`, `brace-expansion`, `ip-address` y `picomatch` | Se actualizaron las resoluciones transitivas en `yarn.lock` y se declararon overrides compatibles en `package.json` para asegurar versiones corregidas. | Build local correcto; Trivy final reporta cero hallazgos `HIGH/CRITICAL` en lockfile e imagen. |
| `ui` y `admin`: faltaban lockfiles; sus imágenes incluían el npm/Corepack de la imagen base | Generados y versionados `package-lock.json`, instalación cambiada a `npm ci`, y npm/Corepack eliminados de las imágenes runtime porque los servicios solo ejecutan Node. | Ambos builds correctos; `npm audit` encontró cero vulnerabilidades y Trivy final reporta cero hallazgos `HIGH/CRITICAL` en imágenes y manifiestos. |
| `carts`: Starlette 0.38.6 vulnerable a CVE-2024-47874, CVE-2026-48818 y CVE-2026-54283 | FastAPI actualizado a 0.165.0, que instala Starlette 1.10.0; Prometheus FastAPI Instrumentator actualizado a 8.1.0 para compatibilidad con esa versión de Starlette. | Build local correcto en Alpine; Trivy final reporta cero hallazgos `HIGH/CRITICAL` en dependencias e imagen. |

## Verificación después de las remediaciones

El reescaneo local con Trivy 0.76.2 analizó los seis targets de imagen y los
manifiestos/lockfiles del repositorio con severidades `HIGH,CRITICAL`. El
resultado fue cero hallazgos en cada imagen (`catalog`, `carts`, `orders`,
`checkout`, `ui`, `admin`) y cero en el filesystem. Los seis Docker builds
terminaron correctamente. No se publicaron imágenes ni se hicieron commits o
pushes durante esta revisión.
