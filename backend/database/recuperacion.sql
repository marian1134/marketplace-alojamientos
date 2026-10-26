USE marketplace_alojamientos;

CREATE TABLE IF NOT EXISTS token_recuperacion (
    id_token BIGINT NOT NULL AUTO_INCREMENT,
    id_usuario BIGINT NOT NULL,
    token_hash VARCHAR(64) NOT NULL,
    fecha_creacion DATETIME(6) NOT NULL,
    fecha_expiracion DATETIME(6) NOT NULL,
    usado BIT(1) NOT NULL DEFAULT b'0',

    PRIMARY KEY (id_token),

    CONSTRAINT uk_token_recuperacion_hash
        UNIQUE (token_hash),

    CONSTRAINT fk_token_recuperacion_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
);