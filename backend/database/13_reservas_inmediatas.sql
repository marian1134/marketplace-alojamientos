-- Todas las reservas se confirman al instante: ningún alojamiento
-- necesita que el anfitrión acepte al huésped.
-- Se puede ejecutar varias veces sin problema.
USE marketplace;
SET SQL_SAFE_UPDATES = 0;

UPDATE publicacion
SET modo_reserva = 'INMEDIATA'
WHERE modo_reserva <> 'INMEDIATA';

SET SQL_SAFE_UPDATES = 1;
SELECT modo_reserva, COUNT(*) AS alojamientos FROM publicacion GROUP BY modo_reserva;
