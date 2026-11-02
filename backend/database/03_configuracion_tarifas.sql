-- =====================================================================
-- CONFIGURACIÓN DE TARIFAS: marketplace
-- Ejecutar después de 02_datos_iniciales.sql. Es obligatorio para reservar.
--
-- Crea el usuario administrador y la configuración vigente de tarifas:
--   * tarifa de servicio StayHub: 12.5 % del valor de las noches
--   * descuento semanal (7 noches o más): 10 %
--   * descuento mensual (28 noches o más): 20 %
--
-- Administrador: admin@stayhub.co  /  contraseña: Admin2026*
-- =====================================================================

SET NAMES utf8mb4;
USE marketplace;

INSERT INTO usuario (nombre, email, password_hash, rol, estado)
SELECT 'Administrador StayHub', 'admin@stayhub.co',
       '$2a$10$Tql3s424VuQO5ngHKlvTheULgN6OzX5.jtqPcgQhIF5TFb181gDtK',
       'ADMINISTRADOR', 'ACTIVA'
WHERE NOT EXISTS (SELECT 1 FROM usuario WHERE email = 'admin@stayhub.co');

INSERT INTO configuracion_tarifas
  (porcentaje_servicio, descuento_semanal, descuento_mensual, vigente, actualizado_por)
SELECT 12.50, 10.00, 20.00, TRUE, id
FROM usuario
WHERE email = 'admin@stayhub.co'
  AND NOT EXISTS (SELECT 1 FROM configuracion_tarifas WHERE vigente = TRUE);

SELECT porcentaje_servicio, descuento_semanal, descuento_mensual
FROM configuracion_tarifas WHERE vigente = TRUE;
