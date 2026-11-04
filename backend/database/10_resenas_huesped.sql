-- Ejecutar una vez sobre la base existente, ANTES de iniciar el backend.
-- No borra ni modifica las reseñas de alojamientos ni las reservas.
USE marketplace;

CREATE TABLE IF NOT EXISTS resena_huesped (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    reserva_id INT UNSIGNED NOT NULL,
    calificacion SMALLINT NOT NULL,
    comentario VARCHAR(1000) NOT NULL,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT uq_resena_huesped_reserva UNIQUE (reserva_id),
    CONSTRAINT fk_resena_huesped_reserva FOREIGN KEY (reserva_id) REFERENCES reserva (id),
    CONSTRAINT ck_resena_huesped_calificacion CHECK (calificacion BETWEEN 1 AND 5),
    CONSTRAINT ck_resena_huesped_comentario CHECK (CHAR_LENGTH(TRIM(comentario)) BETWEEN 10 AND 1000)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SHOW CREATE TABLE resena_huesped;
