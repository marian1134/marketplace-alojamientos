-- =====================================================================
-- RESEÑAS Y FAVORITOS: marketplace
-- Ejecutar después de 05_alojamientos_colombia.sql (o de 04 si no usas el 05).
-- OBLIGATORIO: crea la tabla favorito; sin ella el backend no arranca.
-- Se puede ejecutar más de una vez sin duplicar datos.
--
-- 1. Crea la tabla favorito (alojamientos guardados por cada usuario).
-- 2. Crea 10 huéspedes de prueba y estadías pasadas (COMPLETADAS) con su
--    pago, cotización y reseña, para que los alojamientos tengan estrellas.
-- 3. Deja a huesped@stayhub.co una estadía terminada SIN reseña para probar
--    el botón "Dejar reseña" en Mis viajes.
-- Huéspedes: huesped1..10@huespedes.stayhub.co / contraseña: Admin2026*
-- =====================================================================

SET NAMES utf8mb4;
USE marketplace;

CREATE TABLE IF NOT EXISTS marketplace.favorito (
  usuario_id     INT UNSIGNED NOT NULL,
  publicacion_id INT UNSIGNED NOT NULL,
  creado_en      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (usuario_id, publicacion_id),
  INDEX ix_favorito_publicacion (publicacion_id),
  CONSTRAINT fk_favorito_usuario     FOREIGN KEY (usuario_id)     REFERENCES marketplace.usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_favorito_publicacion FOREIGN KEY (publicacion_id) REFERENCES marketplace.publicacion (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Huéspedes de prueba
INSERT INTO usuario (nombre, email, password_hash, rol, estado)
SELECT d.nombre, d.email, '$2a$10$Tql3s424VuQO5ngHKlvTheULgN6OzX5.jtqPcgQhIF5TFb181gDtK', 'HUESPED', 'ACTIVA'
FROM (
  SELECT 'Valentina Rojas' AS nombre, 'huesped1@huespedes.stayhub.co' AS email UNION ALL
  SELECT 'Andrés Medina',   'huesped2@huespedes.stayhub.co'  UNION ALL
  SELECT 'Camila Herrera',  'huesped3@huespedes.stayhub.co'  UNION ALL
  SELECT 'Julián Castaño',  'huesped4@huespedes.stayhub.co'  UNION ALL
  SELECT 'Daniela Montoya', 'huesped5@huespedes.stayhub.co'  UNION ALL
  SELECT 'Santiago Ríos',   'huesped6@huespedes.stayhub.co'  UNION ALL
  SELECT 'Laura Patiño',    'huesped7@huespedes.stayhub.co'  UNION ALL
  SELECT 'Felipe Arango',   'huesped8@huespedes.stayhub.co'  UNION ALL
  SELECT 'Mariana Duque',   'huesped9@huespedes.stayhub.co'  UNION ALL
  SELECT 'Tomás Becerra',   'huesped10@huespedes.stayhub.co'
) d
WHERE NOT EXISTS (SELECT 1 FROM usuario u WHERE u.email = d.email);

START TRANSACTION;

-- Estadías pasadas: 6 de cada 10 alojamientos tienen entre 1 y 5 reseñas
INSERT INTO reserva
  (codigo, publicacion_id, huesped_id, fecha_llegada, fecha_salida,
   cantidad_huespedes, estado, clave_idempotencia)
SELECT CONCAT('RSV-H', p.id, '-', n.n),
       p.id,
       (SELECT u.id FROM usuario u
         WHERE u.email = CONCAT('huesped', 1 + MOD(p.id + n.n * 3, 10), '@huespedes.stayhub.co')),
       DATE_SUB(CURDATE(), INTERVAL (15 + n.n * 37 + MOD(p.id, 20)) DAY),
       DATE_ADD(DATE_SUB(CURDATE(), INTERVAL (15 + n.n * 37 + MOD(p.id, 20)) DAY),
                INTERVAL (2 + MOD(p.id + n.n, 3)) DAY),
       LEAST(p.capacidad, 1 + MOD(p.id + n.n, 4)),
       'COMPLETADA',
       UUID()
FROM publicacion p
JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
      UNION ALL SELECT 4 UNION ALL SELECT 5) n
  ON n.n <= 1 + MOD(p.id, 5)
WHERE p.etapa = 'ACTIVA'
  AND MOD(p.id, 10) < 6
  AND NOT EXISTS (SELECT 1 FROM reserva r WHERE r.codigo = CONCAT('RSV-H', p.id, '-', n.n));

-- Estadía terminada de huesped@stayhub.co, sin reseña, para probar el botón
INSERT INTO reserva
  (codigo, publicacion_id, huesped_id, fecha_llegada, fecha_salida,
   cantidad_huespedes, estado, clave_idempotencia)
SELECT 'RSV-PRUEBA-1', p.id, u.id,
       DATE_SUB(CURDATE(), INTERVAL 12 DAY), DATE_SUB(CURDATE(), INTERVAL 9 DAY),
       2, 'COMPLETADA', UUID()
FROM publicacion p
JOIN usuario u ON u.email = 'huesped@stayhub.co'
WHERE p.etapa = 'ACTIVA'
  AND NOT EXISTS (SELECT 1 FROM reserva r WHERE r.codigo = 'RSV-PRUEBA-1')
ORDER BY (p.titulo = 'Cabaña frente al lago') DESC, p.id
LIMIT 1;

-- Cotización de cada estadía (precios congelados)
INSERT INTO cotizacion
  (reserva_id, precio_noche, tarifa_limpieza, tarifa_servicio, descuentos, total, moneda, configuracion_id)
SELECT r.id,
       p.precio_noche,
       p.tarifa_limpieza,
       ROUND(p.precio_noche * DATEDIFF(r.fecha_salida, r.fecha_llegada) * c.porcentaje_servicio / 100),
       0,
       p.precio_noche * DATEDIFF(r.fecha_salida, r.fecha_llegada) + p.tarifa_limpieza
         + ROUND(p.precio_noche * DATEDIFF(r.fecha_salida, r.fecha_llegada) * c.porcentaje_servicio / 100),
       'COP',
       c.id
FROM reserva r
JOIN publicacion p ON p.id = r.publicacion_id
JOIN configuracion_tarifas c ON c.vigente = TRUE
WHERE (r.codigo LIKE 'RSV-H%' OR r.codigo = 'RSV-PRUEBA-1')
  AND NOT EXISTS (SELECT 1 FROM cotizacion x WHERE x.reserva_id = r.id);

-- Pago aprobado (de prueba) de cada estadía
INSERT INTO pago
  (reserva_id, monto, estado, referencia_stripe, ultimos4, clave_idempotencia)
SELECT r.id, c.total, 'APROBADO', CONCAT('PRUEBA-', r.codigo), '4242', UUID()
FROM reserva r
JOIN cotizacion c ON c.reserva_id = r.id
WHERE (r.codigo LIKE 'RSV-H%' OR r.codigo = 'RSV-PRUEBA-1')
  AND NOT EXISTS (SELECT 1 FROM pago x WHERE x.reserva_id = r.id);

-- Reseñas: la mayoría de 4 y 5 estrellas, algunas de 3
INSERT INTO resena (reserva_id, calificacion, comentario, fecha)
SELECT r.id,
       CASE
         WHEN MOD(r.publicacion_id * 7 + r.id * 3, 10) < 6 THEN 5
         WHEN MOD(r.publicacion_id * 7 + r.id * 3, 10) < 9 THEN 4
         ELSE 3
       END,
       ELT(1 + MOD(r.publicacion_id + r.id, 14),
         'El lugar es increíble, la vista es aún más linda que en las fotos. Todo muy limpio y el anfitrión súper atento.',
         'Perfecto para desconectarse. Es cómodo, bien ubicado y tiene todo lo necesario.',
         'Nos encantó la experiencia. Volveríamos sin pensarlo, súper recomendado.',
         'Muy buena atención desde que llegamos. La cama es comodísima y el lugar muy tranquilo.',
         'Excelente ubicación, cerca de todo. El check-in fue rápido y sin complicaciones.',
         'Un sitio muy acogedor. Ideal para ir en familia; los niños la pasaron feliz.',
         'La relación calidad-precio es muy buena. Todo estaba tal como en la descripción.',
         'Hermoso lugar, los atardeceres son espectaculares. Gracias por todo.',
         'Buena estadía en general. El wifi a veces fallaba, pero el resto estuvo muy bien.',
         'El anfitrión nos recomendó lugares para comer que fueron lo mejor del viaje.',
         'Limpio, cómodo y silencioso. Dormimos muy bien todas las noches.',
         'Llegamos tarde y aun así nos recibieron con mucha amabilidad. Muy recomendado.',
         'Está bien, aunque el baño podría estar un poco mejor. Volvería por la ubicación.',
         'Una experiencia única, se nota el cariño con el que cuidan cada detalle.'),
       DATE_ADD(r.fecha_salida, INTERVAL 1 DAY)
FROM reserva r
WHERE r.codigo LIKE 'RSV-H%'
  AND NOT EXISTS (SELECT 1 FROM resena x WHERE x.reserva_id = r.id);

COMMIT;

SELECT COUNT(*) AS resenas, ROUND(AVG(calificacion), 2) AS promedio FROM resena;
