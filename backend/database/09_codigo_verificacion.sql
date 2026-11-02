-- =====================================================================
-- CÓDIGO DE VERIFICACIÓN AL INICIAR SESIÓN: marketplace
-- Ejecutar después de 08_check_in.sql.
-- OBLIGATORIO: sin esta tabla el backend no arranca.
-- Se puede ejecutar más de una vez sin problema.
--
-- Al iniciar sesión, después de la contraseña correcta, se envía al correo
-- un código de 6 números. Aquí se guarda el código cifrado (nunca el código
-- tal cual), cuándo vence y cuántas veces lo han escrito mal.
-- Reglas: vence a los 10 minutos, se permiten 5 intentos y solo se usa una vez.
-- =====================================================================

SET NAMES utf8mb4;
USE marketplace;

CREATE TABLE IF NOT EXISTS marketplace.codigo_verificacion (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id  INT UNSIGNED NOT NULL,
  codigo_hash VARCHAR(255) NOT NULL,
  expira_en   DATETIME     NOT NULL,
  intentos    SMALLINT     NOT NULL DEFAULT 0,
  usado       BOOLEAN      NOT NULL DEFAULT FALSE,
  creado_en   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX ix_codigo_usuario (usuario_id, usado, creado_en),
  CONSTRAINT fk_codigo_usuario FOREIGN KEY (usuario_id) REFERENCES marketplace.usuario (id) ON DELETE CASCADE,
  CONSTRAINT ck_codigo_intentos CHECK (intentos >= 0)
) ENGINE=InnoDB;

SELECT 'Código de verificación listo' AS resultado;
