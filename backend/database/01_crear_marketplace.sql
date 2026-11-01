-- =====================================================================
-- BASE DE DATOS UNIFICADA: marketplace
-- Proyecto: Marketplace de Alojamientos – Inversiones LR
-- Motor: MySQL 8.0 o superior
--
-- Un solo esquema (marketplace) con 24 tablas y 1 vista, organizadas por
-- módulo (los mismos 7 servicios de la arquitectura). Normalizado hasta 3FN.
--
-- Diferencias con la versión de 7 bases de datos:
--   * Todas las relaciones son llaves foráneas reales (antes las relaciones
--     entre servicios eran solo referencias "ref.").
--   * Se eliminaron las copias que solo existían por estar en bases
--     separadas: reserva.anfitrion_id (se obtiene de la publicación) y
--     resena.publicacion_id / resena.huesped_id (se obtienen de la reserva).
--   * Se mantienen los valores congelados a propósito: precios de la
--     cotización y de sus servicios adicionales, porcentaje y valor de la
--     devolución, rol en la auditoría y destinatario del correo.
--   * Nombres del equipo en publicacion: ubicacion_descripcion, etapa,
--     motivo_etapa. Política de cancelación con columna tipo
--     (FLEXIBLE, MODERADA, ESTRICTA). Tablas correo_enviado y
--     reporte_resena. Foto de perfil del usuario y motivo de rechazo de la
--     reserva.
--   * Identificadores INT UNSIGNED AUTO_INCREMENT (en Java: Long).
--
-- Ejecutar completo en MySQL Workbench (rayo). Borra y vuelve a crear el
-- esquema marketplace.
-- =====================================================================

DROP DATABASE IF EXISTS marketplace;
CREATE DATABASE marketplace CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE marketplace;

-- ---------------------------------------------------------------------
-- MÓDULO DE IDENTIDAD
-- ---------------------------------------------------------------------
CREATE TABLE marketplace.usuario (
  id                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre             VARCHAR(100) NOT NULL,
  email              VARCHAR(150) NOT NULL,
  password_hash      VARCHAR(255) NOT NULL,
  telefono           VARCHAR(20)  NULL,
  foto_url           VARCHAR(500) NULL,
  rol                VARCHAR(20)  NOT NULL,
  estado             VARCHAR(20)  NOT NULL DEFAULT 'ACTIVA',
  motivo_restriccion VARCHAR(500) NULL,
  intentos_fallidos  SMALLINT     NOT NULL DEFAULT 0,
  bloqueado_hasta    DATETIME     NULL,
  creado_en          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_usuario_email (email),
  CONSTRAINT ck_usuario_rol    CHECK (rol IN ('HUESPED','ANFITRION','ADMINISTRADOR')),
  CONSTRAINT ck_usuario_estado CHECK (estado IN ('ACTIVA','INACTIVA','RESTRINGIDA'))
) ENGINE=InnoDB;

CREATE TABLE marketplace.token_recuperacion (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id  INT UNSIGNED NOT NULL,
  token_hash  VARCHAR(255) NOT NULL,
  expira_en   DATETIME     NOT NULL,
  usado       BOOLEAN      NOT NULL DEFAULT FALSE,
  creado_en   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_token_hash (token_hash),
  CONSTRAINT fk_token_usuario FOREIGN KEY (usuario_id) REFERENCES marketplace.usuario (id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- MÓDULO DE ALOJAMIENTOS (publicaciones, disponibilidad y búsqueda)
-- ---------------------------------------------------------------------
CREATE TABLE marketplace.politica_cancelacion (
  id                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo               VARCHAR(20)  NOT NULL,
  dias_anticipacion  SMALLINT     NOT NULL,
  porcentaje_antes   DECIMAL(5,2) NOT NULL,
  porcentaje_despues DECIMAL(5,2) NOT NULL,
  libera_fechas      BOOLEAN      NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id),
  UNIQUE KEY ux_politica_tipo (tipo),
  CONSTRAINT ck_politica_tipo    CHECK (tipo IN ('FLEXIBLE','MODERADA','ESTRICTA')),
  CONSTRAINT ck_politica_dias    CHECK (dias_anticipacion >= 0),
  CONSTRAINT ck_politica_antes   CHECK (porcentaje_antes BETWEEN 0 AND 100),
  CONSTRAINT ck_politica_despues CHECK (porcentaje_despues BETWEEN 0 AND 100)
) ENGINE=InnoDB;

CREATE TABLE marketplace.publicacion (
  id                    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  anfitrion_id          INT UNSIGNED  NOT NULL,
  titulo                VARCHAR(120)  NOT NULL,
  descripcion           TEXT          NOT NULL,
  ciudad                VARCHAR(80)   NOT NULL,
  ubicacion_descripcion VARCHAR(200)  NOT NULL,
  tipo                  VARCHAR(20)   NOT NULL,
  capacidad             SMALLINT      NOT NULL,
  precio_noche          DECIMAL(12,2) NOT NULL,
  tarifa_limpieza       DECIMAL(12,2) NOT NULL DEFAULT 0,
  modo_reserva          VARCHAR(20)   NOT NULL DEFAULT 'INMEDIATA',
  politica_id           INT UNSIGNED  NOT NULL,
  etapa                 VARCHAR(25)   NOT NULL DEFAULT 'BORRADOR',
  motivo_etapa          VARCHAR(500)  NULL,
  creado_en             DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX ix_publicacion_busqueda (etapa, ciudad, tipo, capacidad, precio_noche),
  INDEX ix_publicacion_anfitrion (anfitrion_id),
  CONSTRAINT fk_publicacion_anfitrion FOREIGN KEY (anfitrion_id) REFERENCES marketplace.usuario (id),
  CONSTRAINT fk_publicacion_politica  FOREIGN KEY (politica_id)  REFERENCES marketplace.politica_cancelacion (id),
  CONSTRAINT ck_publicacion_tipo      CHECK (tipo IN ('CASA','APARTAMENTO','HABITACION','CABANA','FINCA','GLAMPING')),
  CONSTRAINT ck_publicacion_capacidad CHECK (capacidad > 0),
  CONSTRAINT ck_publicacion_precio    CHECK (precio_noche > 0),
  CONSTRAINT ck_publicacion_limpieza  CHECK (tarifa_limpieza >= 0),
  CONSTRAINT ck_publicacion_modo      CHECK (modo_reserva IN ('INMEDIATA','CON_APROBACION')),
  CONSTRAINT ck_publicacion_etapa     CHECK (etapa IN ('BORRADOR','PENDIENTE_REVISION','ACTIVA','PAUSADA','BLOQUEADA'))
) ENGINE=InnoDB;

CREATE TABLE marketplace.imagen (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  publicacion_id INT UNSIGNED NOT NULL,
  url            VARCHAR(500) NOT NULL,
  orden          SMALLINT     NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  CONSTRAINT fk_imagen_publicacion FOREIGN KEY (publicacion_id) REFERENCES marketplace.publicacion (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE marketplace.regla_alojamiento (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  publicacion_id INT UNSIGNED NOT NULL,
  descripcion    VARCHAR(300) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_regla_publicacion FOREIGN KEY (publicacion_id) REFERENCES marketplace.publicacion (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE marketplace.servicio (
  id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(60) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_servicio_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE marketplace.publicacion_servicio (
  publicacion_id INT UNSIGNED NOT NULL,
  servicio_id    INT UNSIGNED NOT NULL,
  PRIMARY KEY (publicacion_id, servicio_id),
  CONSTRAINT fk_pubserv_publicacion FOREIGN KEY (publicacion_id) REFERENCES marketplace.publicacion (id) ON DELETE CASCADE,
  CONSTRAINT fk_pubserv_servicio    FOREIGN KEY (servicio_id)    REFERENCES marketplace.servicio (id)
) ENGINE=InnoDB;

CREATE TABLE marketplace.servicio_adicional (
  id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  publicacion_id INT UNSIGNED  NOT NULL,
  nombre         VARCHAR(80)   NOT NULL,
  precio         DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_servadic_publicacion FOREIGN KEY (publicacion_id) REFERENCES marketplace.publicacion (id) ON DELETE CASCADE,
  CONSTRAINT ck_servadic_precio CHECK (precio >= 0)
) ENGINE=InnoDB;

CREATE TABLE marketplace.periodo_disponible (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  publicacion_id INT UNSIGNED NOT NULL,
  fecha_inicio   DATE     NOT NULL,
  fecha_fin      DATE     NOT NULL,
  PRIMARY KEY (id),
  INDEX ix_periodo_publicacion (publicacion_id, fecha_inicio, fecha_fin),
  CONSTRAINT fk_periodo_publicacion FOREIGN KEY (publicacion_id) REFERENCES marketplace.publicacion (id) ON DELETE CASCADE,
  CONSTRAINT ck_periodo_fechas CHECK (fecha_fin > fecha_inicio)
) ENGINE=InnoDB;

-- Vista para consultar los servicios de cada publicación con sus nombres.
-- La tabla publicacion_servicio guarda solo los identificadores (3FN).
CREATE OR REPLACE VIEW marketplace.v_publicacion_servicio AS
SELECT p.id     AS publicacion_id,
       p.titulo AS publicacion,
       s.id     AS servicio_id,
       s.nombre AS servicio
FROM marketplace.publicacion_servicio ps
JOIN marketplace.publicacion p ON p.id = ps.publicacion_id
JOIN marketplace.servicio    s ON s.id = ps.servicio_id;

-- ---------------------------------------------------------------------
-- MÓDULO DE RESERVAS (cotización, reservas y cancelaciones)
-- ---------------------------------------------------------------------
CREATE TABLE marketplace.configuracion_tarifas (
  id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  porcentaje_servicio DECIMAL(5,2) NOT NULL,
  descuento_semanal   DECIMAL(5,2) NOT NULL,
  descuento_mensual   DECIMAL(5,2) NOT NULL,
  vigente             BOOLEAN      NOT NULL DEFAULT TRUE,
  vigente_unico       TINYINT      GENERATED ALWAYS AS (IF(vigente, 1, NULL)) STORED,
  actualizado_por     INT UNSIGNED NOT NULL,
  actualizado_en      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_configuracion_vigente (vigente_unico),   -- solo una configuración vigente
  CONSTRAINT fk_conf_usuario FOREIGN KEY (actualizado_por) REFERENCES marketplace.usuario (id),
  CONSTRAINT ck_conf_servicio CHECK (porcentaje_servicio BETWEEN 0 AND 100),
  CONSTRAINT ck_conf_semanal  CHECK (descuento_semanal BETWEEN 0 AND 100),
  CONSTRAINT ck_conf_mensual  CHECK (descuento_mensual BETWEEN 0 AND 100)
) ENGINE=InnoDB;

CREATE TABLE marketplace.reserva (
  id                 INT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo             VARCHAR(20) NOT NULL,
  publicacion_id     INT UNSIGNED NOT NULL,
  huesped_id         INT UNSIGNED NOT NULL,
  fecha_llegada      DATE        NOT NULL,
  fecha_salida       DATE        NOT NULL,
  cantidad_huespedes SMALLINT    NOT NULL,
  estado             VARCHAR(25) NOT NULL,
  clave_idempotencia CHAR(36)    NOT NULL,
  requiere_revision  BOOLEAN     NOT NULL DEFAULT FALSE,
  motivo_rechazo     VARCHAR(500) NULL,                   -- si el anfitrión la rechaza
  creada_en          DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizada_en     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_reserva_codigo (codigo),
  UNIQUE KEY ux_reserva_idempotencia (clave_idempotencia),
  INDEX ix_reserva_huesped (huesped_id),
  INDEX ix_reserva_publicacion (publicacion_id, fecha_llegada, fecha_salida),
  CONSTRAINT fk_reserva_publicacion FOREIGN KEY (publicacion_id) REFERENCES marketplace.publicacion (id),
  CONSTRAINT fk_reserva_huesped     FOREIGN KEY (huesped_id)     REFERENCES marketplace.usuario (id),
  CONSTRAINT ck_reserva_fechas    CHECK (fecha_salida > fecha_llegada),
  CONSTRAINT ck_reserva_huespedes CHECK (cantidad_huespedes > 0),
  CONSTRAINT ck_reserva_estado    CHECK (estado IN ('PENDIENTE_PAGO','PENDIENTE_APROBACION','CONFIRMADA','RECHAZADA','ANULADA','CANCELADA','COMPLETADA'))
) ENGINE=InnoDB;

-- Una fila por cada noche ocupada. La llave primaria (publicacion_id, fecha)
-- impide que dos reservas activas ocupen la misma noche del mismo alojamiento
-- (RF-RES-03, RNF-CON-02). Las filas se insertan en la misma transacción que
-- crea la reserva y se eliminan al cancelarla, anularla o rechazarla.
CREATE TABLE marketplace.noche_reservada (
  publicacion_id INT UNSIGNED NOT NULL,
  fecha          DATE     NOT NULL,
  reserva_id     INT UNSIGNED NOT NULL,
  PRIMARY KEY (publicacion_id, fecha),
  CONSTRAINT fk_noche_publicacion FOREIGN KEY (publicacion_id) REFERENCES marketplace.publicacion (id),
  CONSTRAINT fk_noche_reserva     FOREIGN KEY (reserva_id)     REFERENCES marketplace.reserva (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE marketplace.cotizacion (
  id               INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  reserva_id       INT UNSIGNED  NOT NULL,
  precio_noche     DECIMAL(12,2) NOT NULL,
  tarifa_limpieza  DECIMAL(12,2) NOT NULL,
  tarifa_servicio  DECIMAL(12,2) NOT NULL,
  descuentos       DECIMAL(12,2) NOT NULL DEFAULT 0,
  total            DECIMAL(12,2) NOT NULL,
  moneda           CHAR(3)       NOT NULL DEFAULT 'COP',
  configuracion_id INT UNSIGNED  NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_cotizacion_reserva (reserva_id),
  CONSTRAINT fk_cotizacion_reserva       FOREIGN KEY (reserva_id)       REFERENCES marketplace.reserva (id),
  CONSTRAINT fk_cotizacion_configuracion FOREIGN KEY (configuracion_id) REFERENCES marketplace.configuracion_tarifas (id),
  CONSTRAINT ck_cotizacion_total  CHECK (total >= 0)
) ENGINE=InnoDB;

CREATE TABLE marketplace.cotizacion_servicio_adicional (
  cotizacion_id         INT UNSIGNED  NOT NULL,
  servicio_adicional_id INT UNSIGNED  NOT NULL,
  nombre                VARCHAR(80)   NOT NULL,
  precio                DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (cotizacion_id, servicio_adicional_id),
  CONSTRAINT fk_cotserv_cotizacion FOREIGN KEY (cotizacion_id)         REFERENCES marketplace.cotizacion (id) ON DELETE CASCADE,
  CONSTRAINT fk_cotserv_servicio   FOREIGN KEY (servicio_adicional_id) REFERENCES marketplace.servicio_adicional (id)
) ENGINE=InnoDB;

CREATE TABLE marketplace.cancelacion (
  id                    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  reserva_id            INT UNSIGNED  NOT NULL,
  cancelado_por         INT UNSIGNED  NOT NULL,
  fecha                 DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  motivo                VARCHAR(500)  NOT NULL,
  porcentaje_devolucion DECIMAL(5,2)  NOT NULL,
  valor_devolucion      DECIMAL(12,2) NOT NULL,
  fechas_liberadas      BOOLEAN       NOT NULL,
  estado_final          VARCHAR(25)   NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_cancelacion_reserva (reserva_id),
  CONSTRAINT fk_cancelacion_reserva FOREIGN KEY (reserva_id)    REFERENCES marketplace.reserva (id),
  CONSTRAINT fk_cancelacion_usuario FOREIGN KEY (cancelado_por) REFERENCES marketplace.usuario (id),
  CONSTRAINT ck_cancelacion_valor CHECK (valor_devolucion >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- MÓDULO DE PAGOS
-- ---------------------------------------------------------------------
CREATE TABLE marketplace.pago (
  id                 INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  reserva_id         INT UNSIGNED  NOT NULL,
  monto              DECIMAL(12,2) NOT NULL,
  monto_reembolsado  DECIMAL(12,2) NOT NULL DEFAULT 0,
  moneda             CHAR(3)       NOT NULL DEFAULT 'COP',
  estado             VARCHAR(20)   NOT NULL,
  referencia_stripe  VARCHAR(100)  NULL,
  ultimos4           CHAR(4)       NULL,
  clave_idempotencia CHAR(36)      NOT NULL,
  creado_en          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_pago_reserva (reserva_id),
  UNIQUE KEY ux_pago_referencia (referencia_stripe),
  UNIQUE KEY ux_pago_idempotencia (clave_idempotencia),
  CONSTRAINT fk_pago_reserva FOREIGN KEY (reserva_id) REFERENCES marketplace.reserva (id),
  CONSTRAINT ck_pago_monto  CHECK (monto > 0),
  CONSTRAINT ck_pago_estado CHECK (estado IN ('PENDIENTE','APROBADO','RECHAZADO','REEMBOLSADO','REEMBOLSO_PARCIAL'))
) ENGINE=InnoDB;

CREATE TABLE marketplace.evento_stripe (
  id_evento   VARCHAR(100) NOT NULL,                     -- evita procesar dos veces el mismo webhook
  tipo        VARCHAR(60)  NOT NULL,
  pago_id     INT UNSIGNED NULL,
  recibido_en DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_evento),
  CONSTRAINT fk_evento_pago FOREIGN KEY (pago_id) REFERENCES marketplace.pago (id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- MÓDULO DE RESEÑAS
-- ---------------------------------------------------------------------
CREATE TABLE marketplace.resena (
  id                  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  reserva_id          INT UNSIGNED  NOT NULL,            -- una reseña por reserva
  calificacion        SMALLINT      NOT NULL,
  comentario          VARCHAR(1000) NOT NULL,
  fecha               DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  visible             BOOLEAN       NOT NULL DEFAULT TRUE,
  motivo_ocultamiento VARCHAR(500)  NULL,
  ocultada_por        INT UNSIGNED  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY ux_resena_reserva (reserva_id),
  CONSTRAINT fk_resena_reserva  FOREIGN KEY (reserva_id)   REFERENCES marketplace.reserva (id),
  CONSTRAINT fk_resena_ocultada FOREIGN KEY (ocultada_por) REFERENCES marketplace.usuario (id),
  CONSTRAINT ck_resena_calificacion CHECK (calificacion BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- Reportes de reseñas hechos por huéspedes o anfitriones. El administrador
-- los revisa y decide si oculta la reseña (RF-REV-05).
CREATE TABLE marketplace.reporte_resena (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  resena_id     INT UNSIGNED NOT NULL,
  reportado_por INT UNSIGNED NOT NULL,
  motivo        VARCHAR(500) NOT NULL,
  fecha         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atendido      BOOLEAN      NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id),
  UNIQUE KEY ux_reporte_resena_usuario (resena_id, reportado_por),   -- un usuario reporta una reseña una sola vez
  INDEX ix_reporte_pendiente (atendido, fecha),
  CONSTRAINT fk_reporte_resena  FOREIGN KEY (resena_id)     REFERENCES marketplace.resena (id),
  CONSTRAINT fk_reporte_usuario FOREIGN KEY (reportado_por) REFERENCES marketplace.usuario (id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- MÓDULO DE NOTIFICACIONES
-- ---------------------------------------------------------------------
CREATE TABLE marketplace.notificacion (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id INT UNSIGNED NOT NULL,
  tipo       VARCHAR(40)  NOT NULL,
  titulo     VARCHAR(120) NOT NULL,
  mensaje    VARCHAR(500) NOT NULL,
  entidad    VARCHAR(30)  NULL,
  entidad_id INT UNSIGNED NULL,
  leida      BOOLEAN      NOT NULL DEFAULT FALSE,
  creada_en  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX ix_notificacion_usuario (usuario_id, leida, creada_en DESC),
  CONSTRAINT fk_notificacion_usuario FOREIGN KEY (usuario_id) REFERENCES marketplace.usuario (id)
) ENGINE=InnoDB;

-- Registro de los correos enviados por los eventos importantes: reserva
-- confirmada, comprobante de pago, cancelación y devolución. El contenido
-- del correo sale de la notificación; aquí se guarda a quién se envió y
-- si el envío funcionó.
CREATE TABLE marketplace.correo_enviado (
  id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  notificacion_id INT UNSIGNED NOT NULL,
  destinatario    VARCHAR(150) NOT NULL,
  asunto          VARCHAR(150) NOT NULL,
  estado          VARCHAR(10)  NOT NULL DEFAULT 'PENDIENTE',
  intentos        SMALLINT     NOT NULL DEFAULT 0,
  error           VARCHAR(500) NULL,
  enviado_en      DATETIME     NULL,
  creado_en       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY ux_correo_notificacion (notificacion_id),
  INDEX ix_correo_estado (estado, creado_en),
  CONSTRAINT fk_correo_notificacion FOREIGN KEY (notificacion_id) REFERENCES marketplace.notificacion (id) ON DELETE CASCADE,
  CONSTRAINT ck_correo_estado   CHECK (estado IN ('PENDIENTE','ENVIADO','FALLIDO')),
  CONSTRAINT ck_correo_intentos CHECK (intentos >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- MÓDULO DE ADMINISTRACIÓN Y REPORTES
-- ---------------------------------------------------------------------
CREATE TABLE marketplace.evento_auditoria (
  id         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  fecha_hora DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario_id INT UNSIGNED  NULL,                         -- nulo si lo genera el sistema
  rol        VARCHAR(20)   NULL,
  servicio   VARCHAR(30)   NOT NULL,
  accion     VARCHAR(60)   NOT NULL,
  entidad    VARCHAR(30)   NOT NULL,
  entidad_id VARCHAR(60)   NULL,
  resultado  VARCHAR(10)   NOT NULL,
  detalle    VARCHAR(1000) NULL,
  ip         VARCHAR(45)   NULL,
  trace_id   VARCHAR(40)   NULL,
  PRIMARY KEY (id),
  INDEX ix_auditoria_consulta (fecha_hora DESC, usuario_id, entidad),
  CONSTRAINT fk_auditoria_usuario FOREIGN KEY (usuario_id) REFERENCES marketplace.usuario (id),
  CONSTRAINT ck_auditoria_resultado CHECK (resultado IN ('EXITO','FALLO'))
) ENGINE=InnoDB;

CREATE TABLE marketplace.exportacion_reporte (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo_reporte   VARCHAR(20) NOT NULL,
  formato        VARCHAR(5)  NOT NULL,
  solicitado_por INT UNSIGNED NOT NULL,
  fecha_desde    DATE        NULL,
  fecha_hasta    DATE        NULL,
  ciudad         VARCHAR(80) NULL,
  fecha          DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_exportacion_usuario FOREIGN KEY (solicitado_por) REFERENCES marketplace.usuario (id),
  CONSTRAINT ck_exportacion_tipo    CHECK (tipo_reporte IN ('USUARIOS','PUBLICACIONES','RESERVAS','INGRESOS','DEMANDA')),
  CONSTRAINT ck_exportacion_formato CHECK (formato IN ('PDF','XLSX')),
  CONSTRAINT ck_exportacion_fechas  CHECK (fecha_hasta IS NULL OR fecha_desde IS NULL OR fecha_hasta >= fecha_desde)
) ENGINE=InnoDB;

-- Verificación: deben aparecer 24 tablas y 1 vista.
SHOW FULL TABLES FROM marketplace;
