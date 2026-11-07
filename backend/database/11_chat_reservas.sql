-- Ejecutar sobre la base existente antes de iniciar el backend.
USE marketplace;
CREATE TABLE IF NOT EXISTS mensaje_reserva (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  reserva_id INT UNSIGNED NOT NULL,
  remitente_id INT UNSIGNED NOT NULL,
  contenido VARCHAR(2000) NOT NULL,
  clave_cliente CHAR(36) NOT NULL,
  creada_en DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_mensaje_reserva_cliente (reserva_id, remitente_id, clave_cliente),
  INDEX ix_mensaje_reserva_historial (reserva_id, id),
  CONSTRAINT fk_mensaje_reserva_reserva FOREIGN KEY (reserva_id) REFERENCES reserva (id),
  CONSTRAINT fk_mensaje_reserva_remitente FOREIGN KEY (remitente_id) REFERENCES usuario (id),
  CONSTRAINT ck_mensaje_reserva_contenido CHECK (CHAR_LENGTH(TRIM(contenido)) BETWEEN 1 AND 2000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SHOW CREATE TABLE mensaje_reserva;
