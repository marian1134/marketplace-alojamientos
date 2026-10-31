USE marketplace_alojamientos;

CREATE TABLE IF NOT EXISTS alojamiento (
    id_alojamiento BIGINT NOT NULL AUTO_INCREMENT,
    id_anfitrion BIGINT NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    descripcion VARCHAR(2000) NOT NULL,
    ciudad VARCHAR(150) NOT NULL,
    direccion VARCHAR(150) NOT NULL,

    tipo_alojamiento ENUM(
        'APARTAMENTO',
        'CASA',
        'HABITACION',
        'FINCA',
        'CABAÑA',
        'OTRO'
    ) NOT NULL,

    capacidad INT NOT NULL,
    precio_noche DECIMAL(12,2) NOT NULL,

    estado ENUM(
        'BORRADOR',
        'PENDIENTE_REVISION',
        'ACTIVO',
        'PAUSADO',
        'BLOQUEADO'
    ) NOT NULL DEFAULT 'BORRADOR',

    fecha_creacion DATETIME(6) NOT NULL,
    fecha_actualizacion DATETIME(6) NOT NULL,

    PRIMARY KEY (id_alojamiento),

    KEY idx_alojamiento_anfitrion (id_anfitrion),

    CONSTRAINT fk_alojamiento_anfitrion
        FOREIGN KEY (id_anfitrion)
        REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_alojamiento_capacidad
        CHECK (capacidad > 0),

    CONSTRAINT chk_alojamiento_precio
        CHECK (precio_noche > 0)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci;