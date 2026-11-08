# Base de datos `marketplace`

MySQL 8. Una sola base con 28 tablas y 1 vista, organizadas por módulo
(identidad, alojamientos, reservas, pagos, reseñas, notificaciones y
administración).

## Orden de los scripts

Ejecutar en MySQL Workbench, como `root`, en este orden:

| Script | Qué hace | ¿Obligatorio? |
|---|---|---|
| `01_crear_marketplace.sql` | Crea la base y las tablas. **Borra la base si ya existe.** | Sí (solo la primera vez) |
| `02_datos_iniciales.sql` | Políticas de cancelación y catálogo de servicios | Sí |
| `03_configuracion_tarifas.sql` | Tarifa de servicio y descuentos | Sí |
| `04_datos_prueba.sql` | Anfitrión, huésped y 4 alojamientos de ejemplo | No |
| `05_alojamientos_colombia.sql` | 1.080 alojamientos de ejemplo | No |
| `06_resenas_favoritos.sql` | Tabla `favorito` y reseñas de ejemplo | Sí |
| `07_habitaciones_descripciones.sql` | Columnas `habitaciones` y `banos` | Sí |
| `08_check_in.sql` | Hora de check-in y registro del check-in | Sí |
| `09_codigo_verificacion.sql` | Código de 6 números al iniciar sesión | Sí |
| `10_resenas_huesped.sql` | Reseñas del anfitrión sobre el huésped | Sí |
| `11_chat_reservas.sql` | Chat entre huésped y anfitrión | Sí |
| `12_configurar_administrador.sql` | Convierte una cuenta en administradora (se edita a mano) | No |
| `13_reservas_inmediatas.sql` | Todas las reservas se confirman al instante | Sí |
| `14_ajustes_base.sql` | Collation igual en todas las tablas y llave compuesta en `noche_reservada` | Sí |
| `16_servicios_y_reglas.sql` | Servicios (Wifi, piscina...) y reglas para los alojamientos que no tienen. Se puede ejecutar varias veces | Sí |
| `15_usuario_aplicacion.sql` | Usuario de MySQL con permisos mínimos para el backend (se edita a mano) | Recomendado |

Los scripts del 06 en adelante se pueden ejecutar más de una vez sin
dañar nada (menos el 04 y el 05, que duplican los datos de ejemplo).

## Seguridad

- **Inyección SQL.** El backend nunca arma consultas pegando lo que escribe
  el usuario. Usa JPA (repositorios de Spring) y, donde hay SQL escrito a
  mano (`JdbcTemplate` del panel de administración), los valores van
  siempre como parámetros `?`. Los filtros solo aceptan valores de una
  lista permitida.
- **Mínimo privilegio.** Con el script 15, el backend se conecta con el
  usuario `stayhub_app`, que solo puede leer y modificar filas de
  `marketplace` (`SELECT, INSERT, UPDATE, DELETE`). No puede borrar ni
  crear tablas, ni ver otras bases, ni crear usuarios.
- **Datos sensibles.** Contraseñas, códigos de verificación y tokens de
  recuperación se guardan cifrados con bcrypt. De las tarjetas solo se
  guardan los últimos 4 números; el pago lo procesa Stripe.
- **Claves fuera del repositorio.** Las claves de la base, del correo, de
  Stripe y de Gemini van en variables de entorno, nunca en los archivos.

## Integridad y normalización (3FN)

- Todas las relaciones son llaves foráneas reales. Solo `usuario`,
  `servicio` y `politica_cancelacion` no tienen, porque son tablas raíz.
- Reglas de negocio en la propia base: `CHECK` en estados, fechas y
  calificaciones; `UNIQUE` en correos, códigos de reserva y claves de
  idempotencia (sin cobros dobles).
- **Sin reservas dobles:** `noche_reservada` tiene una fila por noche con
  llave primaria `(publicacion_id, fecha)`.
- **Datos que se repiten a propósito** (no rompen la 3FN):
  - Precios de la cotización, devolución de la cancelación, rol en la
    auditoría y destinatario del correo: son el valor que tenía el dato
    en ese momento (lo que se cobró, a quién se envió), no una copia del
    valor actual.
  - `noche_reservada.publicacion_id`: se podría sacar de la reserva, pero
    es parte de la llave que impide las reservas dobles. La llave foránea
    compuesta `(reserva_id, publicacion_id) → reserva (id, publicacion_id)`
    garantiza que nunca quede distinto al de la reserva.
- `notificacion` y `evento_auditoria` usan `(entidad, entidad_id)` para
  apuntar a distintas tablas, por eso esas dos columnas no llevan llave
  foránea.
