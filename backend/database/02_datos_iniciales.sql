-- =====================================================================
-- DATOS INICIALES: marketplace
-- Ejecutar después de 01_crear_marketplace.sql.
-- Son catálogos que la app necesita para funcionar (no son datos de prueba).
-- =====================================================================

USE marketplace;

-- Políticas de cancelación. Toda publicación debe tener una (publicacion.politica_id).
INSERT INTO politica_cancelacion
  (tipo, dias_anticipacion, porcentaje_antes, porcentaje_despues, libera_fechas)
VALUES
  ('FLEXIBLE', 1, 100.00,  0.00, TRUE),   -- devolución total hasta 1 día antes
  ('MODERADA', 5, 100.00, 50.00, TRUE),   -- total hasta 5 días antes; 50 % después
  ('ESTRICTA', 7,  50.00,  0.00, TRUE);   -- 50 % hasta 7 días antes; nada después

-- Catálogo de servicios que el anfitrión puede marcar en su publicación.
INSERT INTO servicio (nombre) VALUES
  ('Wifi'),
  ('Parqueadero'),
  ('Cocina'),
  ('Pet friendly'),
  ('Piscina'),
  ('Aire acondicionado'),
  ('Zona BBQ'),
  ('Vista al lago'),
  ('Vista al mar'),
  ('Terraza privada'),
  ('Lavadora'),
  ('TV');

SELECT tipo FROM politica_cancelacion;
SELECT COUNT(*) AS servicios FROM servicio;
