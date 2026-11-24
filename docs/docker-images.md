# Optimización de imágenes Docker

## Decisión

Los seis servicios usan etapas de construcción separadas de las imágenes de
ejecución. Las etapas finales conservan solo el runtime y los archivos
necesarios para iniciar cada servicio; todas mantienen un usuario no-root.

- **catalog y orders:** se compilan con Go sobre Alpine y terminan en Alpine
  con certificados CA. `catalog` mantiene CGO porque su persistencia SQLite
  usa `go-sqlite3`; por eso instala herramientas de compilación solo en el
  builder y conserva `libgcc` en runtime. `orders` se compila con CGO
  deshabilitado. Se eligió Alpine en lugar de `scratch`/distroless para
  conservar una base operable con certificados y soporte de diagnóstico.
- **carts:** instala las dependencias Python en una etapa `python:3.12-slim`
  y copia el prefijo instalado a la etapa final. Se conserva Debian slim para
  usar las wheels disponibles de `psycopg2-binary` sin introducir toolchains
  en runtime; las dependencias de la aplicación son necesarias en producción.
- **checkout:** compila con Node Alpine y Yarn, luego `yarn workspaces focus
  --production` quita las dependencias de desarrollo antes de copiar
  `node_modules` y `dist` a runtime.
- **ui y admin:** compilan con Node Alpine, ejecutan `npm prune --omit=dev` y
  copian únicamente `node_modules`, `dist` y `public`. Los HTML públicos son
  requeridos por los servidores Express y se conservan explícitamente.

Alpine mantiene una capa de runtime pequeña sin cambiar los comandos de inicio
ni el comportamiento de los servicios. Para Python se prefiere slim a Alpine
por compatibilidad con sus wheels; para los servicios Node se conservan las
imágenes oficiales de Node para evitar una base distroless que complique el
diagnóstico. Los builders y sus toolchains no forman parte de las imágenes
finales.

## Comparación medida

Los originales se construyeron desde `origin/main` en el commit `5c28e6b`;
las variantes optimizadas se construyeron desde esta rama. Medición del
24-11-2026 con Docker Engine 29.9.3, usando `docker image inspect` (`.Size`,
bytes de la imagen local, no tamaño comprimido de descarga).

| Servicio | Original (bytes) | Multi-stage (bytes) | Original (MiB) | Multi-stage (MiB) | Reducción |
| --- | ---: | ---: | ---: | ---: | ---: |
| catalog | 2,263,574,423 | 49,224,229 | 2,158.71 | 46.94 | 97.83% |
| carts | 1,682,127,652 | 243,866,207 | 1,604.20 | 232.57 | 85.50% |
| orders | 2,025,185,707 | 36,246,249 | 1,931.37 | 34.57 | 98.21% |
| checkout | 2,033,869,567 | 329,124,234 | 1,939.65 | 313.88 | 83.82% |
| ui | 1,762,374,644 | 249,343,675 | 1,680.73 | 237.79 | 85.85% |
| admin | 1,764,948,004 | 246,456,050 | 1,683.19 | 235.04 | 86.04% |

Cada imagen multi-stage resultó más liviana que su original. La reducción se
calcula como `(original - multi-stage) / original * 100`.

## Regenerar la comparación (PowerShell)

Ejecutar desde la raíz del repositorio. El SHA `5c28e6b` fija el mismo commit
que era `origin/main` al tomar estas mediciones. Si Docker Desktop instaló el
CLI fuera de `PATH`, el bloque inicial también incorpora su directorio para
que Docker encuentre el helper de credenciales.

```powershell
git fetch origin
$dockerDir = "$env:LOCALAPPDATA\Programs\DockerDesktop\resources\bin"
if (-not (Test-Path (Join-Path $dockerDir "docker.exe"))) {
    $docker = (Get-Command docker.exe -ErrorAction Stop).Source
    $dockerDir = Split-Path $docker
}
$env:PATH = "$dockerDir;$env:PATH"
$docker = Join-Path $dockerDir "docker.exe"
& $docker version

$baseline = Join-Path (Split-Path (Get-Location).Path -Parent) "Tero-obligatorioDevOps-card79-baseline"
git worktree add $baseline 5c28e6b
if ($LASTEXITCODE -ne 0) { throw "No se pudo crear el worktree base" }

$services = @(
    @{ Tag = "catalog"; Context = "catalog" },
    @{ Tag = "carts"; Context = "cart" },
    @{ Tag = "orders"; Context = "orders" },
    @{ Tag = "checkout"; Context = "checkout" },
    @{ Tag = "ui"; Context = "ui" },
    @{ Tag = "admin"; Context = "admin" }
)

foreach ($service in $services) {
    & $docker build --pull --tag "tero-$($service.Tag):original" (Join-Path $baseline "src\$($service.Context)")
    if ($LASTEXITCODE -ne 0) { throw "Falló el build original: $($service.Tag)" }
}
foreach ($service in $services) {
    & $docker build --pull --tag "tero-$($service.Tag):multistage" (Join-Path (Get-Location).Path "src\$($service.Context)")
    if ($LASTEXITCODE -ne 0) { throw "Falló el build multi-stage: $($service.Tag)" }
}

$comparison = foreach ($service in $services) {
    $original = [Int64](& $docker image inspect --format '{{.Size}}' "tero-$($service.Tag):original")
    $optimized = [Int64](& $docker image inspect --format '{{.Size}}' "tero-$($service.Tag):multistage")
    if ($optimized -ge $original) { throw "$($service.Tag) no quedó más liviana" }
    [pscustomobject]@{
        Servicio = $service.Tag
        OriginalBytes = $original
        MultiStageBytes = $optimized
        ReduccionPorcentaje = [Math]::Round(100 * ($original - $optimized) / $original, 2)
    }
}
$comparison | Format-Table -AutoSize

git worktree remove $baseline
```
