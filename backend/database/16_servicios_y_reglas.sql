-- Servicios y reglas para los alojamientos que todavía no tienen.
-- Así los filtros por servicio y el detalle del alojamiento muestran información.
-- Se puede ejecutar varias veces: solo toca alojamientos sin servicios o sin reglas,
-- de modo que no borra lo que un anfitrión ya haya elegido.
USE marketplace;
SET NAMES utf8mb4;

-- Wifi en todos los alojamientos sin servicios
INSERT IGNORE INTO publicacion_servicio (publicacion_id, servicio_id)
SELECT p.id, s.id
FROM publicacion p
JOIN servicio s ON s.nombre = 'Wifi'
WHERE NOT EXISTS (SELECT 1 FROM publicacion_servicio ps WHERE ps.publicacion_id = p.id);

-- Otros servicios repartidos de forma variada (según el id del alojamiento y del servicio)
INSERT IGNORE INTO publicacion_servicio (publicacion_id, servicio_id)
SELECT p.id, s.id
FROM publicacion p
JOIN servicio s ON s.nombre <> 'Wifi'
WHERE (SELECT COUNT(*) FROM publicacion_servicio ps WHERE ps.publicacion_id = p.id) = 1
  AND (
        MOD(p.id * 7 + s.id * 3, 4) = 0
     OR (s.nombre = 'Cocina' AND p.tipo IN ('CASA', 'APARTAMENTO', 'CABANA', 'FINCA'))
     OR (s.nombre = 'Piscina' AND p.tipo = 'FINCA')
     OR (s.nombre = 'Parqueadero' AND p.tipo IN ('CASA', 'FINCA', 'CABANA'))
  );

-- Reglas básicas para los alojamientos sin reglas
INSERT INTO regla_alojamiento (publicacion_id, descripcion)
SELECT p.id, 'No se permite fumar dentro del alojamiento.'
FROM publicacion p
WHERE NOT EXISTS (SELECT 1 FROM regla_alojamiento r WHERE r.publicacion_id = p.id);

INSERT INTO regla_alojamiento (publicacion_id, descripcion)
SELECT p.id, 'Horario de silencio desde las 10:00 p. m. hasta las 7:00 a. m.'
FROM publicacion p
WHERE (SELECT COUNT(*) FROM regla_alojamiento r WHERE r.publicacion_id = p.id) = 1;

INSERT INTO regla_alojamiento (publicacion_id, descripcion)
SELECT p.id, IF(EXISTS (SELECT 1 FROM publicacion_servicio ps JOIN servicio s ON s.id = ps.servicio_id
                       WHERE ps.publicacion_id = p.id AND s.nombre = 'Pet friendly'),
                'Se admiten mascotas pequeñas con aviso previo.',
                'No se admiten mascotas.')
FROM publicacion p
WHERE (SELECT COUNT(*) FROM regla_alojamiento r WHERE r.publicacion_id = p.id) = 2;

SELECT COUNT(DISTINCT publicacion_id) AS alojamientos_con_servicios FROM publicacion_servicio;
SELECT COUNT(DISTINCT publicacion_id) AS alojamientos_con_reglas FROM regla_alojamiento;
