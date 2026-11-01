-- =====================================================================
-- DATOS DE PRUEBA (opcional): marketplace
-- Ejecutar después de 03_configuracion_tarifas.sql.
-- Sirve para probar y presentar: crea un anfitrión, un huésped y
-- 4 alojamientos activos con foto. Ejecútalo una sola vez.
--
-- Anfitrión: anfitrion@stayhub.co  /  contraseña: Admin2026*
-- Huésped:   huesped@stayhub.co    /  contraseña: Admin2026*
-- =====================================================================

SET NAMES utf8mb4;
USE marketplace;

INSERT INTO usuario (nombre, email, password_hash, telefono, rol, estado)
SELECT 'Mariana Torres', 'anfitrion@stayhub.co',
       '$2a$10$Tql3s424VuQO5ngHKlvTheULgN6OzX5.jtqPcgQhIF5TFb181gDtK',
       '3001234567', 'ANFITRION', 'ACTIVA'
WHERE NOT EXISTS (SELECT 1 FROM usuario WHERE email = 'anfitrion@stayhub.co');

INSERT INTO usuario (nombre, email, password_hash, telefono, rol, estado)
SELECT 'Lina Niño', 'huesped@stayhub.co',
       '$2a$10$Tql3s424VuQO5ngHKlvTheULgN6OzX5.jtqPcgQhIF5TFb181gDtK',
       '3109876543', 'HUESPED', 'ACTIVA'
WHERE NOT EXISTS (SELECT 1 FROM usuario WHERE email = 'huesped@stayhub.co');

SET @anfitrion = (SELECT id FROM usuario WHERE email = 'anfitrion@stayhub.co');
SET @flexible  = (SELECT id FROM politica_cancelacion WHERE tipo = 'FLEXIBLE');
SET @moderada  = (SELECT id FROM politica_cancelacion WHERE tipo = 'MODERADA');
SET @estricta  = (SELECT id FROM politica_cancelacion WHERE tipo = 'ESTRICTA');

INSERT INTO publicacion
  (anfitrion_id, titulo, descripcion, ciudad, ubicacion_descripcion, tipo,
   capacidad, precio_noche, tarifa_limpieza, modo_reserva, politica_id, etapa)
VALUES
  (@anfitrion, 'Cabaña frente al lago',
   'Cabaña moderna y acogedora frente al lago, perfecta para desconectarse. Terraza privada, zona BBQ y una vista espectacular. Ideal para familias, parejas o grupos de amigos.',
   'Guatapé', 'A 5 minutos del malecón', 'CABANA', 6, 480000, 100000, 'INMEDIATA', @flexible, 'ACTIVA'),
  (@anfitrion, 'Villa frente al mar',
   'Villa con piscina privada a pasos de la playa. Cuatro habitaciones con aire acondicionado y cocina equipada.',
   'Santa Marta', 'Sector El Rodadero', 'CASA', 8, 620000, 120000, 'INMEDIATA', @moderada, 'ACTIVA'),
  (@anfitrion, 'Apartamento con vista a la ciudad',
   'Apartamento en El Poblado con balcón y vista panorámica. Cerca de restaurantes, centros comerciales y el metro.',
   'Medellín', 'El Poblado, cerca al parque Lleras', 'APARTAMENTO', 4, 280000, 50000, 'CON_APROBACION', @moderada, 'ACTIVA'),
  (@anfitrion, 'Glamping en la montaña',
   'Domo con jacuzzi, chimenea y vista a las montañas. Desayuno incluido y senderos ecológicos.',
   'Villa de Leyva', 'Vereda Monquirá, a 10 minutos del pueblo', 'GLAMPING', 2, 350000, 40000, 'INMEDIATA', @estricta, 'ACTIVA');

INSERT INTO imagen (publicacion_id, url, orden)
SELECT id, '/imagenes/registro-fondo.png', 0
FROM publicacion
WHERE anfitrion_id = @anfitrion
  AND id NOT IN (SELECT publicacion_id FROM (SELECT publicacion_id FROM imagen) i);

SELECT id, titulo, ciudad, etapa FROM publicacion WHERE anfitrion_id = @anfitrion;
