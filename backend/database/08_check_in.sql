-- =====================================================================
-- CHECK-IN: marketplace
-- Ejecutar después de 07_habitaciones_descripciones.sql.
-- OBLIGATORIO: sin estas columnas el backend no arranca.
-- Se puede ejecutar más de una vez sin problema.
--
-- 1. publicacion.hora_check_in: desde qué hora puede llegar el huésped
--    (la pone cada anfitrión; por defecto 3:00 p. m.).
-- 2. reserva.check_in_en: cuándo hizo el huésped su check-in (NULL = no lo ha hecho).
-- 3. reserva.recordatorio_enviado: si ya se envió el correo de "mañana llegas".
--
-- Reglas: el check-in se hace el día de llegada, desde la hora de check-in
-- hasta las 11:59 p. m. Si no se hace, el anfitrión puede cancelar la
-- reserva por "no se presentó".
-- =====================================================================

SET NAMES utf8mb4;
USE marketplace;

-- 1. Hora de check-in del alojamiento
SET @existe = (SELECT COUNT(*) FROM information_schema.columns
               WHERE table_schema = 'marketplace' AND table_name = 'publicacion'
                 AND column_name = 'hora_check_in');
SET @sql = IF(@existe = 0,
  'ALTER TABLE publicacion ADD COLUMN hora_check_in TIME NOT NULL DEFAULT ''15:00:00'' AFTER banos',
  'SELECT 1');
PREPARE agregar FROM @sql;
EXECUTE agregar;
DEALLOCATE PREPARE agregar;

-- 2. Momento del check-in
SET @existe = (SELECT COUNT(*) FROM information_schema.columns
               WHERE table_schema = 'marketplace' AND table_name = 'reserva'
                 AND column_name = 'check_in_en');
SET @sql = IF(@existe = 0,
  'ALTER TABLE reserva ADD COLUMN check_in_en DATETIME NULL AFTER motivo_rechazo',
  'SELECT 1');
PREPARE agregar FROM @sql;
EXECUTE agregar;
DEALLOCATE PREPARE agregar;

-- 3. Recordatorio enviado
SET @existe = (SELECT COUNT(*) FROM information_schema.columns
               WHERE table_schema = 'marketplace' AND table_name = 'reserva'
                 AND column_name = 'recordatorio_enviado');
SET @sql = IF(@existe = 0,
  'ALTER TABLE reserva ADD COLUMN recordatorio_enviado BOOLEAN NOT NULL DEFAULT FALSE AFTER check_in_en',
  'SELECT 1');
PREPARE agregar FROM @sql;
EXECUTE agregar;
DEALLOCATE PREPARE agregar;

-- Las reservas que ya terminaron no necesitan recordatorio
UPDATE reserva
SET recordatorio_enviado = TRUE
WHERE fecha_llegada <= CURDATE() AND recordatorio_enviado = FALSE;

SELECT 'Check-in listo' AS resultado;
