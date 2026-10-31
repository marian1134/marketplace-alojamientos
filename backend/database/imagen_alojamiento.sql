USE marketplace_alojamientos;

CREATE TABLE IF NOT EXISTS imagen_alojamiento (
    id_imagen BIGINT NOT NULL AUTO_INCREMENT,
    id_alojamiento BIGINT NOT NULL,
    url_imagen VARCHAR(500) NOT NULL,
    nombre_original VARCHAR(255) NOT NULL,
    tipo_contenido VARCHAR(100) NOT NULL,
    principal BIT(1) NOT NULL DEFAULT b'0',
    orden_imagen INT NOT NULL DEFAULT 0,
    fecha_creacion DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    PRIMARY KEY (id_imagen),

    KEY idx_imagen_alojamiento (id_alojamiento),

    CONSTRAINT fk_imagen_alojamiento
        FOREIGN KEY (id_alojamiento)
        REFERENCES alojamiento (id_alojamiento)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_imagen_orden
        CHECK (orden_imagen >= 0)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;