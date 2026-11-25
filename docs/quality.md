# Análisis de calidad de código

## Herramienta y ejecución

El workflow `.github/workflows/build.yml` ejecuta Semgrep en un job independiente
del build y de las pruebas de integración. El análisis corre en cada pull request
hacia `main` y en cada push a `main`, y usa `--config auto` para seleccionar
reglas según los lenguajes encontrados en el repositorio.

## Umbral de calidad

El quality gate permite **cero hallazgos** de las reglas seleccionadas. La opción
`--error` hace que Semgrep devuelva un estado distinto de cero cuando detecta
hallazgos; en ese caso falla el job y el check requerido puede bloquear el merge.
Las excepciones deben justificarse junto a la regla o el código afectado, no
ocultarse desactivando el análisis.

## Informe

Semgrep aporta análisis estático basado en reglas para los lenguajes del proyecto.
El job publica en GitHub Actions el resumen y las ubicaciones de los hallazgos de
cada ejecución. El umbral inicial es estricto: cualquier hallazgo debe revisarse
y corregirse o justificarse antes de integrar cambios. Este análisis no mide
cobertura de pruebas ni métricas de mantenibilidad como SonarQube; la cobertura
del flujo funcional se verifica por separado con las pruebas Newman.

En el primer análisis local, Semgrep 1.163.0 ejecutó 592 reglas sobre 95 archivos
y reportó seis hallazgos bloqueantes: referencias mutables de GitHub Actions, la
falta de una espera mínima para dependencias nuevas de Yarn y dos alertas sobre
integridad en favicons SVG embebidos. Se fijaron las Actions a SHA completos, se
configuró una espera mínima de siete días en Yarn y se justificaron las dos
excepciones porque esos favicons son `data:` locales, no recursos externos. El
análisis posterior ejecutó las mismas 592 reglas sobre 95 archivos y terminó con
cero hallazgos.
