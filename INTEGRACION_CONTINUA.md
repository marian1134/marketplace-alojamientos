# Integración continua y pruebas

## Qué pasa en cada Pull Request

El flujo del proyecto es:

**Historia Jira → rama → commits → Pull Request → GitHub Actions → pruebas → SonarCloud Quality Gate → revisión → merge**

El archivo `.github/workflows/integracion-continua.yml` se ejecuta solo en cada
Pull Request hacia `main` y hace tres trabajos:

| Trabajo | Qué hace |
|---|---|
| **Backend · compilación y pruebas** | Levanta MySQL 8, crea la base con los scripts 01 a 16 (sin el 05, 12 ni 15), compila con Maven y ejecuta las pruebas automatizadas. Guarda los resultados y la cobertura (JaCoCo). |
| **Frontend · construcción** | Instala las dependencias, revisa el código con oxlint y construye la aplicación. |
| **SonarCloud · análisis estático** | Envía el código y la cobertura a SonarCloud y espera el Quality Gate. Solo corre si existe el secreto `SONAR_TOKEN`. |

## Pruebas automatizadas (backend)

Están en `backend/src/test/java` y se relacionan con las historias de usuario:

| Clase | Historias | Qué comprueba |
|---|---|---|
| `RegistroUsuarioTest` | HU-03 | Registro válido, correo repetido, celular inválido, contraseña débil |
| `SeguridadRolesTest` | HU-05, HU-28 | Un huésped no entra a administración, sin sesión no hay búsqueda |
| `CotizacionTest` | HU-18 | Total con limpieza, servicio 12,5 % y descuento semanal; fechas y capacidad inválidas |
| `ReservaTest` | HU-16, HU-19, HU-20 | Reserva confirmada al instante, sin superposición, idempotente, tarjeta vencida, búsqueda sin ocupados |
| `CancelacionYResenaTest` | HU-21, HU-23 | Devolución según política, registro de la cancelación, reseña solo al terminar y una sola vez |
| `ServiciosYReglasTest` | HU-09 | Publicar con servicios y reglas, validaciones de capacidad y servicios |
| `AdministracionReportesTest` | HU-28, HU-29 | Dashboard completo, reportes en Excel y PDF registrados, permisos, contrato OpenAPI |
| `ClienteAsistenteTest` | HU-42 | Lectura de la respuesta de Gemini (prueba unitaria) |

### Correrlas en el computador

1. Tener la base `marketplace` creada con los scripts (01 a 04, 06 a 11, 13, 14 y 16).
2. En la terminal, dentro de `backend`:

```
set DB_USERNAME=root
set DB_PASSWORD=SU_CLAVE_MYSQL
set MAIL_USERNAME=pruebas@stayhub.co
set MAIL_PASSWORD=x
mvnw.cmd verify
```

Cada prueba se deshace al terminar, así que no ensucia la base.
El reporte de cobertura queda en `backend/target/site/jacoco/index.html`.

## Activar SonarCloud (una sola vez)

Lo hace la dueña del repositorio (marian1134):

1. Entrar a https://sonarcloud.io con GitHub e importar el repositorio `marketplace-alojamientos`.
2. En SonarCloud: **Administration → Analysis Method** → desactivar *Automatic Analysis*.
3. Copiar el **token** que da SonarCloud.
4. En GitHub: **Settings → Secrets and variables → Actions → New repository secret**,
   nombre `SONAR_TOKEN` y pegar el token.
5. Revisar que `sonar.organization` y `sonar.projectKey` de `sonar-project.properties`
   sean los que muestra SonarCloud.

## Proteger la rama main (una sola vez)

En GitHub: **Settings → Branches → Add branch ruleset** (o *Add rule*) para `main`:

- Exigir Pull Request antes de unir, con **1 aprobación**.
- Exigir que pasen las verificaciones: *Backend · compilación y pruebas*,
  *Frontend · construcción* y *SonarCloud · análisis estático*.
- No permitir pushes directos a `main`.

## Contrato de la API (OpenAPI / Swagger)

Con el backend prendido:

- Página interactiva: http://localhost:8081/swagger-ui.html
- Contrato en JSON: http://localhost:8081/v3/api-docs
