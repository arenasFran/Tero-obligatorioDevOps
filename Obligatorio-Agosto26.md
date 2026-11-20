# Facultad de Ingeniería

**_Bernard Wand-Polak_**

Cuareim 1451, 11.100 Montevideo, Uruguay. Tel. 2902 15 05 Fax 2908 13 70

www.ort.edu.uy

| **EVALUACIÓN** | Obligatorio                                                           | **GRUPO** | TODOS | **FECHA** | Agosto 2026 |
| -------------- | --------------------------------------------------------------------- | --------- | ----- | --------- | ----------- |
| **MATERIA**    | Certificado en DevOps                                                 |           |       |           |             |
| **CARRERA**    | Analista en Tecnologías de la Información │ Actualización profesional |           |       |           |             |

---

## CONDICIONES

- **Puntaje máximo:** 50 puntos
- **Puntaje mínimo:** 1 puntos
- **Fecha de entrega:** 07/12/2026 hasta las 21:00 horas en gestion.ort.edu.uy (max. 40Mb en formato zip, rar o pdf)

---

## Inteligencia Artificial Generativa

- Seguir las pautas de los docentes: Se deben seguir las instrucciones específicas de los docentes sobre cómo utilizar la IA en cada curso.
- Citar correctamente las fuentes y usos de IA: Siempre que se utilice una herramienta de IA para generar contenido, se debe citar adecuadamente la fuente y la forma en que se utilizó. Se debe indicar:
  - la /las herramientas utilizadas y
  - el contexto de uso: por ejemplo, generación de código fuente, redacción de documentación, análisis de datos, corrección de errores, estilo, etc.
- Verificar el contenido generado por la IA: No todo el contenido generado por la IA es correcto o preciso. Es esencial que los estudiantes verifiquen la información antes de usarla.
- Ser responsables con el uso de la IA: Conocer los riesgos y desafíos, como la creación de “alucinaciones”, los peligros para la privacidad, las cuestiones de propiedad intelectual, los sesgos inherentes y la producción de contenido falso
- El uso de herramientas de Inteligencia Artificial Generativa (IAG) puede emplearse como apoyo en el proceso de aprendizaje. Sin embargo, no sustituye el razonamiento crítico ni la elaboración personal. El estudiante es responsable de que el trabajo presentado refleje su propia comprensión, análisis y proceso cognitivo sobre el tema
- En caso de existir dudas sobre la autoría, plagio o uso no atribuido de IAG, el docente tendrá la opción de convocar al equipo de obligatorio a una defensa específica e individual sobre el tema
- La defensa es obligatoria y eliminatoria.
- La defensa será presencial salvo en los casos en que se habilite la defensa oral sincrónica en forma remota.

---

## Defensa

**Fecha de defensa: Semanas del 08/12 al 18/12**

La defensa es obligatoria y eliminatoria. El docente es quien definirá y comunicará la modalidad, y mecánica de defensa. La no presentación a la misma implica la pérdida de la totalidad de los puntos del Obligatorio.

**IMPORTANTE:**

1. Inscribirse
2. Formar grupos de hasta 3 personas del mismo dictado
3. Subir el trabajo a Gestión antes de la hora indicada (ver hoja “RECORDATORIO” al final del documento)

Aquellos de ustedes que presenten alguna dificultad con su inscripción o tengan inconvenientes técnicos, por favor contactarse con el Coordinador o Coordinación adjunta **antes de las 20:00hs.** del día de la entrega, a través de los mails [alamon@ort.edu.uy](mailto:alamon@ort.edu.uy) y [rodríguez_mb@ort.edu.uy](about:blank) o telefónicamente al 29021505 - int 1156 u 1138

---

## Letra

**Tero** es un marketplace uruguayo que vende accesorios, ropa, comida y vehículos livianos. Lo construyó un equipo pequeño y funciona: tiene tienda, carrito, checkout, órdenes y un panel de administración, repartidos en seis microservicios con su base de datos y su Redis. El problema no es lo que hace, sino dónde y cómo corre. Hoy **Tero** se ejecuta únicamente con docker compose en las computadoras del equipo de desarrollo. No existe un ambiente en la nube, no hay pipelines y nadie puede decir con certeza qué versión del código está corriendo. Cada demostración implica que alguien levante los contenedores a mano y confíe en que todo arranque.

Un fondo de inversión regional quiere financiar la expansión de **Tero**, pero condicionó el cierre de la ronda a una auditoría técnica. Los primeros días de Diciembre, una firma auditora visitará la empresa con un checklist de controles. **Tero** debe poder demostrar cada uno con evidencia concreta. Si no los cumple, la ronda se posterga. Antes de la visita formal, el auditor revisó el repositorio y dejó estas observaciones preliminares, que no son exhaustivas:

- Las contraseñas de la base de datos y las credenciales del panel de administración están escritas en archivos del repositorio.
- Todas las imágenes de contenedor se construyen en un solo paso sobre imágenes base completas, y los procesos corren como administrador (root) dentro del contenedor.
- La base de datos y Redis están publicados en puertos de la máquina anfitriona.
- No hay pruebas automatizadas, ni análisis de código ni de dependencias.
- No hay forma de saber qué versión se está ejecutando ni de repetir un despliegue de la misma manera dos veces.
- Algunos servicios ya exponen métricas, pero nadie hace la recolección ni las mira.

La empresa los contrata como equipo consultor DevOps. El objetivo no es aprobar la auditoría con maquillaje: **Tero** no tiene cultura DevOps ni un equipo de infraestructura propio, y su gente tendrá que operar lo que ustedes construyan una vez terminada la consultoría. Por eso el auditor no sólo verificará que los controles se cumplan, sino que alguien más pueda entenderlos, repetirlos y mantenerlos.

---

## Entrega

A continuación, se detallan los aspectos que deberá contemplar la solución entregada. Cada sección define requerimientos mínimos obligatorios; el equipo es libre de superar dichos mínimos.

### 1. Planificación y Seguimiento

1. Utilizar _Kanban_ o _Scrum_ para planificar y hacer seguimiento de las tareas identificadas por el equipo.
2. Documentar mediante capturas de pantalla el estado del tablero en al menos tres momentos distintos del proyecto (inicio, mitad y cierre), evidenciando la evolución del trabajo.
3. El tablero debe reflejar la totalidad de las tareas del proyecto, incluyendo las de infraestructura, seguridad, testing y observabilidad.

### 2. Integración y Entrega Continua (CI/CD)

1. Desarrollar _pipelines_ de CI/CD para al menos tres ambientes: Dev, Test y Prod.
2. Cada pipeline debe contener como mínimo las siguientes etapas/fases:
   - Build / compilación de artefactos.
   - Ejecución de pruebas automatizadas.
   - Análisis de calidad de código (ver sección 4).
   - Análisis de seguridad (ver sección 5).
   - Publicación de imagen de contenedor (ver sección 3).
   - Despliegue al ambiente correspondiente.
3. Implementar _quality gates_ entre ambientes: ningún artefacto debe promoverse al siguiente ambiente si no cumple los umbrales definidos de calidad y seguridad.
4. El pipeline debe ser reproducible y estar completamente definido como código (YAML u otro formato de definición declarativa).

### 3. Containerización y Despliegue

1. Optimizar la construcción de imágenes de contenedor aplicando buenas prácticas, por ejemplo:
   - Uso de imágenes base mínimas (distroless, alpine o similares).
   - Construcción multi-stage para reducir el tamaño final de la imagen.
   - Usuario no-root dentro del contenedor.
   - _.dockerignore_ adecuado.
2. Publicar las imágenes en un container registry (ECR, Docker Hub, GHCR u otro).
3. Desplegar los contenedores en un servicio de orquestación en nube (AWS ECS, EKS u equivalente en Azure/GCP).

### 4. Testing y Calidad

1. Implementar _al menos uno_ de los siguientes tipos de testing:
   - Pruebas funcionales / de integración entre microservicios (Postman/Newman, REST-assured, Pact, Selenium, etc.).
   - Pruebas de carga y rendimiento (k6, JMeter, Locust, etc.).

   > (escribir un par de tests solamente)

2. Integrar _una_ herramienta de análisis de código estático (SonarQube, ESLint, Semgrep, o similar) en el pipeline de CI.
3. Definir umbrales de calidad (coverage mínimo, número máximo de code smells, etc.) que actúen como quality gate.
4. Elaborar un informe\* con los resultados obtenidos, hallazgos significativos y recomendaciones de mejora.
   (\* el informe no es más que un párrafo en la documentación que exprese la interpretación de los resultados).

### 5. DevSecOps

1. Integrar en el pipeline de CI _una_ herramienta de Software Composition Analysis (SCA) que analice las dependencias de los microservicios en busca de CVEs conocidos. Ejemplos de herramientas: Trivy (modo filesystem), Snyk, OWASP Dependency-Check.
2. Definir un quality gate que bloquee el pipeline ante vulnerabilidades de severidad CRITICAL o HIGH sin parche disponible.
3. Escanear cada imagen de contenedor construida antes de publicarla en el registro. Ejemplos de herramientas: Trivy (modo image), Anchore Grype, Clair.
4. Integrar _al menos una_ herramienta de Static Application Security Testing (SAST) en el pipeline. Ejemplos de herramientas: Semgrep, Bandit (Python), GoSec (Go), NodeJsScan, SonarQube.
5. Reportar los hallazgos y documentar las remediaciones aplicadas o las excepciones justificadas.
6. Ningún secreto (contraseña, API key, token, connection string) debe estar hardcodeado en el código fuente ni en los archivos de configuración del repositorio. (.gitignore frenar el .env por ejemplo)
7. Integrar en el pipeline _un_ detector de secretos expuestos (git-secrets, detect-secrets, TruffleHog, Gitleaks u otros) que falle el build si detecta credenciales en el código.

### 6. Control de Versiones

1. Almacenar todo el código (aplicación, pipelines, IaC, configuración) en repositorio/s Git.
2. Implementar una estrategia de ramificación claramente definida. Opciones sugeridas:
   - Git Flow (ramas main, develop, feature/\*, release/\*, hotfix/\*).
   - Trunk-Based Development con feature flags.
   - GitHub Flow (main + feature branches + PRs).
3. Justificar la elección de la estrategia en función de las características del equipo y del contexto del proyecto.
4. Demostrar colaboración efectiva mediante Pull Requests con revisiones de código entre integrantes del equipo (mínimo dos PRs documentados con comentarios de revisión).
5. Las ramas de feature no deben fusionarse a main/develop sin aprobación de al menos un revisor distinto al autor (revisar por ejemplo Branch Protection Rules).

### 7. Infraestructura como Código (IaC)

1. Implementar toda la infraestructura como código utilizando Terraform (salvo el bucket del estado de Terraform).
2. El código de IaC debe cumplir los siguientes estándares:
   - Modularización adecuada: al menos _un_ módulo reutilizable (ej: módulo de red, de contenedores, de base de datos).
   - Variables parametrizadas por ambiente: usar archivos _.tfvars_ diferenciados para Dev, Test y Prod.
   - Outputs relevantes documentados con descripción.
   - Manejo seguro de secretos: no almacenar valores sensibles en el estado de Terraform sin cifrar.
   - Estado remoto: usar un backend remoto (S3, Terraform Cloud u otro) para el archivo de estado.
3. Servicios Serverless (_elegir al menos uno_):
   - AWS Lambda para automatizaciones y/o procesamiento de eventos: alertas automáticas, análisis de logs de seguridad, notificaciones de vulnerabilidades, rotación de secretos, etc.
   - API Gateway para gestión de acceso y seguridad a APIs: rate limiting, autenticación, WAF básico.

> El servicio serverless debe integrarse con el resto de la arquitectura y tener un propósito claramente definido. Se valorará especialmente que el propósito esté relacionado con seguridad u observabilidad.

### 8. Observabilidad

1. Implementar una solución de monitoreo que permita tener visibilidad del estado del sistema en producción.
   - Recolectar métricas de infraestructura (CPU, memoria, red) o de aplicación (latencia, tasa de errores, throughput) para los microservicios desplegados.
   - Centralizar los logs de todos los servicios en una plataforma única, con formato estructurado que permita búsquedas y filtros.
   - Configurar al menos _1 dashboard_ con métricas relevantes para la operación del sistema.
   - Establecer al menos _2 alertas_ que cubran disponibilidad, rendimiento, seguridad y/o uso de recursos. Cada alerta debe tener definida su condición de disparo (trigger) y un procedimiento básico de respuesta.

> Herramientas sugeridas (no excluyentes): CloudWatch, Prometheus, Grafana, Loki, Open Telemetry u otras equivalentes.

### 9. Documentación

1. Crear un README.md completo con instrucciones de despliegue, configuración de variables de entorno y pre-requisitos.
2. Generar los siguientes diagramas:
   - Diagrama de arquitectura general del sistema.
   - Flujo completo del pipeline CI/CD con las etapas de seguridad integradas.
   - Estrategia de Git (branching model) adoptada.
   - Documentar las decisiones de diseño más relevantes (Architecture Decision Records o formato libre) y las lecciones aprendidas del proyecto.

### Algunas consideraciones / aclaraciones

1. Las aplicaciones a desplegar se encuentran en el siguiente repositorio: [Tero](https://github.com/ORT-ATI-CertificadoDevOps/Tero)
2. Queda a consideración del equipo la elección de las herramientas y/o servicios a utilizar para desplegar la solución propuesta.
3. Se deberá exponer el trabajo realizado en una instancia de defensa.
4. La documentación entregada será valorada en prolijidad, calidad y organización. Queda en total libertad la definición del formato de la misma.
5. El equipo deberá entregar **_todo_** el contenido generado en el formato establecido por el sistema de gestión (.rar o .zip). Este archivo contendrá **_todo_** lo utilizado: repositorio git, documentación, imágenes, etc.
6. Registrar equipo de obligatorio: [Listado de Alumnos DevOps - 2026 (Agosto)](https://docs.google.com/spreadsheets/d/12axQTgXXWl5j1zkNsuz_BJ3p-1hCdKBjWuRe148kuME/edit?usp=sharing)

Se podrán realizar **_todas_** las consultas que quieran, mientras estas sean **_claras_**, **_concisas_** y tengan un **_mínimo de investigación_** previa. No se podrán enviar documentos para ser corregidos o medir el avance fuera de las fechas de entrega previstas.

---

## Defensa

La defensa será con el “auditor” y tendrá una duración estimada de unos 25 minutos y tiene tres partes en las que el equipo trabaja sobre su propia solución:

- **Hacer (10 min)**: El auditor pide una tarea breve sobre la solución del equipo, por ejemplo volver a una versión anterior, rotar una credencial o interpretar un cambio de infraestructura.
- **Resolver (8 min)**: El auditor comparte un caso, como un pipeline que falló o una alerta disparada. El equipo lo diagnostica en voz alta y explica qué haría.
- **Explicar (7 min)**: El auditor elige dos puntos de la entrega y pregunta por qué se resolvieron así y qué pasaría si cambiaran las condiciones.

El auditor decide quién del equipo responde o ejecuta en cada parte. Todos deben poder hacerlo. Se puede consultar la documentación propia y la oficial de las herramientas. No se espera una solución perfecta: se evalúa cómo razonan y qué decisiones toman.

La defensa es obligatoria y eliminatoria.

---

## Rúbrica

| SE PIDE                                                               | PUNTAJE MÁXIMO | CRITERIO                                                                                                         |
| --------------------------------------------------------------------- | -------------- | ---------------------------------------------------------------------------------------------------------------- |
| Implementación en base a los puntos detallados en la parte de entrega | 6              | La solución resuelve el problema propuesto de forma completa, es innovadora y demuestra entendimiento de DevOps. |
| Gestión de proyecto                                                   | 4              | Se evidencia uso consistente de la metodología seleccionada con un progreso bien documentado.                    |
| Documentación técnica                                                 | 4              | Documentación completa, bien estructurada y técnicamente precisa en formato Markdown (o el formato entregado).   |
| Containerización y despliegue                                         | 4              | Containers con buenas prácticas incluídas y desplegados en servicio de orquestación en la nube.                  |
| Gestión de código                                                     | 4              | Repositorio/s bien organizado/s con separación adecuada de componentes.                                          |
| Estrategias de ramificación                                           | 4              | Evidencia clara de trabajo colaborativo con un uso correcto de las estrategias de ramificación y pull requests.  |
| Implementación serverless                                             | 4              | Servicio serverless implementado con propósito claro y bien integrado.                                           |
| Infraestructura como código                                           | 4              | IaC bien implementada, modular y parametrizada.                                                                  |
| Análisis de código estático                                           | 4              | Informe detallado con hallazgos significativos y recomendaciones accionables.                                    |
| Testing y Calidad                                                     | 4              | Integración de uno de los tipos de testing mencionados y ejecución de los criterios de calidad.                  |
| Seguridad                                                             | 4              | Herramientas integradas al SDLC y criterios aplicados.                                                           |
| Observabilidad                                                        | 4              | Recolección de las señales indicadas y elaboración de las visualizaciones y alertas requeridas.                  |

---

## RECORDATORIO: IMPORTANTE PARA LA ENTREGA

### Obligatorios

La entrega de los obligatorios será en formato digital online, a excepción de algunas materias que se entregarán en Bedelía y en ese caso recibirá información específica en el dictado de la misma.

Los principales aspectos a destacar sobre la **entrega online de obligatorios** son:

1. Ingresá al sistema de Gestión.
2. En el menú, seleccioná el ítem “Evaluaciones” y la instancia de evaluación correspondiente, que figura bajo el título “Inscripto”.
3. Para iniciar la entrega hacé clic en el ícono: ![Ícono de entrega](media/image1.png)
4. Ingresá el número de estudiante de cada uno de los integrantes y hacé clic en “Agregar”. El sistema confirmará que los integrantes estén inscriptos al obligatorio y, de ser así, mostrará el nombre y la fotografía de cada uno de ellos. Una vez agregados todos los integrantes, hacé clic en “Crear equipo”.

   **Cualquier integrante podrá:**
   - Modificar la integración del equipo.
   - Subir el archivo de la entrega.

5. Seleccioná el archivo que deseás entregar. Verificá el nombre del archivo que aparecerá en la pantalla y hacé clic en “Subir” para iniciar la entrega. Cada equipo (hasta 3 estudiantes) debe entregar **un único archivo en formato zip o rar** (los documentos de texto deben ser pdf, y deben ir dentro del zip o rar). El archivo a subir debe tener **un tamaño máximo de 40mb**

   Cuando el archivo quede subido, se mostrará el nombre generado por el sistema (1), el tamaño y la fecha en que fue subido.

6. El sistema enviará un e-mail a todos los integrantes del equipo informando los detalles del archivo entregado y confirmando que la entrega fue realizada correctamente.
7. Podés cerrar la pestaña de entrega y continuar utilizando Gestión o salir del sistema.
8. La **hora tope para subir el archivo será las 21:00** del día fijado para la entrega.
9. La entrega se podrá realizar desde cualquier lugar (ej. hogar del estudiante, laboratorios de la Universidad, etc).
10. Aquellos de ustedes que presenten alguna dificultad con su inscripción o tengan inconvenientes técnicos, por favor contactarse con la Coordinadora o Coordinación adjunta antes de las 20:00hs. del día de la entrega, a través de los mails, [alamon@ort.edu.uy](mailto:alamon@ort.edu.uy) o [rodríguez_mb@ort.edu.uy](about:blank); o telefónicamente al 29021505 - int 1156 u 1138

---

**Computación - Electrónica - Telecomunicaciones - Sistemas de Información**
