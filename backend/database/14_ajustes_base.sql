-- =====================================================================
-- AJUSTES DE CONSISTENCIA: marketplace
-- Ejecutar después de 13_reservas_inmediatas.sql.
-- No borra datos. Se puede ejecutar más de una vez sin problema.
--
-- 1. Misma forma de comparar textos (collation utf8mb4_unicode_ci) en
--    todas las tablas. mensaje_reserva y resena_huesped se habían creado
--    con otra (utf8mb4_0900_ai_ci) y eso hace fallar comparaciones entre
--    tablas, por ejemplo en 12_configurar_administrador.sql.
--
-- 2. noche_reservada guarda publicacion_id aunque se puede obtener de la
--    reserva. Es a propósito: la llave primaria (publicacion_id, fecha)
--    es la que impide las reservas dobles. Para que ese dato repetido
--    nunca quede distinto al de la reserva, la llave foránea pasa a ser
--    compuesta: (reserva_id, publicacion_id) -> reserva (id, publicacion_id).
-- =====================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
USE marketplace;

-- ---------------------------------------------------------------------
-- 1. Collation igual en todas las tablas
-- ---------------------------------------------------------------------
ALTER TABLE mensaje_reserva CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE resena_huesped  CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 2. noche_reservada siempre de acuerdo con su reserva
-- ---------------------------------------------------------------------

-- 2.1 Revisión: noches cuyo alojamiento no coincide con el de su reserva.
--     Debe dar 0. Si da más, el paso 2.4 falla y hay que revisar esas filas.
SELECT COUNT(*) AS noches_inconsistentes
FROM noche_reservada n
JOIN reserva r ON r.id = n.reserva_id
WHERE r.publicacion_id <> n.publicacion_id;

-- 2.2 La pareja (id, publicacion_id) de la reserva debe ser única para
--     poder apuntarle con una llave foránea compuesta
SET @existe = (SELECT COUNT(*) FROM information_schema.statistics
               WHERE table_schema = 'marketplace' AND table_name = 'reserva'
                 AND index_name = 'ux_reserva_id_publicacion');
SET @sql = IF(@existe = 0,
  'ALTER TABLE reserva ADD UNIQUE KEY ux_reserva_id_publicacion (id, publicacion_id)',
  'SELECT 1');
PREPARE paso FROM @sql; EXECUTE paso; DEALLOCATE PREPARE paso;

-- 2.3 Se quita la llave foránea simple (solo reserva_id)
SET @existe = (SELECT COUNT(*) FROM information_schema.table_constraints
               WHERE constraint_schema = 'marketplace' AND table_name = 'noche_reservada'
                 AND constraint_name = 'fk_noche_reserva' AND constraint_type = 'FOREIGN KEY');
SET @sql = IF(@existe = 1,
  'ALTER TABLE noche_reservada DROP FOREIGN KEY fk_noche_reserva',
  'SELECT 1');
PREPARE paso FROM @sql; EXECUTE paso; DEALLOCATE PREPARE paso;

-- 2.4 Y se pone la compuesta (si se borra la reserva, se borran sus noches)
SET @existe = (SELECT COUNT(*) FROM information_schema.table_constraints
               WHERE constraint_schema = 'marketplace' AND table_name = 'noche_reservada'
                 AND constraint_name = 'fk_noche_reserva_publicacion');
SET @sql = IF(@existe = 0,
  'ALTER TABLE noche_reservada ADD CONSTRAINT fk_noche_reserva_publicacion FOREIGN KEY (reserva_id, publicacion_id) REFERENCES reserva (id, publicacion_id) ON DELETE CASCADE',
  'SELECT 1');
PREPARE paso FROM @sql; EXECUTE paso; DEALLOCATE PREPARE paso;

-- ---------------------------------------------------------------------
-- Comprobación final
-- ---------------------------------------------------------------------
SELECT table_collation AS collation, COUNT(*) AS tablas
FROM information_schema.tables
WHERE table_schema = 'marketplace' AND table_type = 'BASE TABLE'
GROUP BY table_collation;

SELECT constraint_name AS llaves_noche_reservada
FROM information_schema.table_constraints
WHERE constraint_schema = 'marketplace' AND table_name = 'noche_reservada'
  AND constraint_type = 'FOREIGN KEY';
