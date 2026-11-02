-- =====================================================================
-- HABITACIONES, BAÑOS Y MEJORES DESCRIPCIONES: marketplace
-- Ejecutar después de 06_resenas_favoritos.sql.
-- OBLIGATORIO: agrega las columnas habitaciones y banos a publicacion;
-- sin ellas el backend no arranca.
-- Se puede ejecutar más de una vez sin problema.
--
-- 1. Agrega las columnas habitaciones y banos (si no existen).
-- 2. Les pone un valor según el tipo y la capacidad del alojamiento.
-- 3. Mejora la descripción de los 1.080 alojamientos de 05.
-- =====================================================================

SET NAMES utf8mb4;
USE marketplace;

SET @existe = (SELECT COUNT(*) FROM information_schema.columns
               WHERE table_schema = 'marketplace' AND table_name = 'publicacion'
                 AND column_name = 'habitaciones');
SET @sql = IF(@existe = 0,
  'ALTER TABLE publicacion ADD COLUMN habitaciones SMALLINT NOT NULL DEFAULT 1 AFTER capacidad, ADD COLUMN banos SMALLINT NOT NULL DEFAULT 1 AFTER habitaciones, ADD CONSTRAINT ck_publicacion_habitaciones CHECK (habitaciones > 0), ADD CONSTRAINT ck_publicacion_banos CHECK (banos > 0)',
  'SELECT 1');
PREPARE agregar FROM @sql;
EXECUTE agregar;
DEALLOCATE PREPARE agregar;

START TRANSACTION;

-- Valor inicial para todos los alojamientos (los creados por anfitriones
-- pueden cambiarlo desde el formulario)
UPDATE publicacion
SET habitaciones = CASE
      WHEN tipo IN ('HABITACION', 'GLAMPING') THEN 1
      WHEN tipo = 'APARTAMENTO' THEN LEAST(3, GREATEST(1, CEIL(capacidad / 2)))
      WHEN tipo = 'CASA' THEN GREATEST(2, CEIL(capacidad / 2))
      WHEN tipo = 'CABANA' THEN GREATEST(1, CEIL(capacidad / 2.5))
      ELSE GREATEST(3, CEIL(capacidad / 2.5))
    END
WHERE habitaciones = 1;

UPDATE publicacion
SET banos = CASE
      WHEN tipo IN ('HABITACION', 'GLAMPING') THEN 1
      WHEN tipo = 'APARTAMENTO' THEN IF(habitaciones = 1, 1, 2)
      WHEN tipo = 'CASA' THEN GREATEST(1, FLOOR((habitaciones + 1) / 2))
      WHEN tipo = 'CABANA' THEN GREATEST(1, FLOOR(habitaciones / 2))
      ELSE GREATEST(2, FLOOR((habitaciones + 1) / 2))
    END
WHERE banos = 1;

-- Descripciones nuevas de los alojamientos de 05_alojamientos_colombia.sql
UPDATE publicacion SET descripcion = 'En Punta Gallinas, Cabo de la Vela, te espera un glamping familiar con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: el mar Caribe a pocos pasos y chinchorros wayuu. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping familiar en Punta Gallinas' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Descubre Cabo de la Vela desde una cabaña acogedora en Punta Gallinas, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: el mar Caribe a pocos pasos y kitesurf. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña acogedora en Punta Gallinas' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta habitación encantadora en Ojo de Agua es el punto de partida perfecto para conocer Cabo de la Vela y lo mejor de La Guajira.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: chinchorros wayuu y kitesurf. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación encantadora en Ojo de Agua' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta casa encantadora está ubicada en Playa del Pilón de Azúcar, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: kitesurf y chinchorros wayuu. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa encantadora en Playa del Pilón de Azúcar' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Este glamping exclusivo está ubicado en Frente a la bahía, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: el mar Caribe a pocos pasos y chinchorros wayuu. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping exclusivo en Frente a la bahía' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta cabaña tranquila está ubicada en Punta Gallinas, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: kitesurf y atardeceres en el desierto. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña tranquila en Punta Gallinas' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'En Ranchería Wayuu, Cabo de la Vela, te espera una habitación familiar con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: chinchorros wayuu y kitesurf. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Ranchería Wayuu' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta casa familiar está ubicada en Ranchería Wayuu, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: el mar Caribe a pocos pasos y kitesurf. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa familiar en Ranchería Wayuu' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Descubre Cabo de la Vela desde un glamping rústico en Punta Gallinas, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: el mar Caribe a pocos pasos y atardeceres en el desierto. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping rústico en Punta Gallinas' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta cabaña tranquila está ubicada en Ojo de Agua, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: el mar Caribe a pocos pasos y kitesurf. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña tranquila en Ojo de Agua' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta habitación sencilla está ubicada en Ranchería Wayuu, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: el mar Caribe a pocos pasos y atardeceres en el desierto. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación sencilla en Ranchería Wayuu' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta casa elegante en Playa del Pilón de Azúcar es el punto de partida perfecto para conocer Cabo de la Vela y lo mejor de La Guajira.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: el mar Caribe a pocos pasos y kitesurf. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa elegante en Playa del Pilón de Azúcar' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Este glamping colorido está ubicado en Punta Gallinas, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: el mar Caribe a pocos pasos y chinchorros wayuu. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping colorido en Punta Gallinas' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Descubre Cabo de la Vela desde una cabaña romántica en Frente a la bahía, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: atardeceres en el desierto y el mar Caribe a pocos pasos. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña romántica en Frente a la bahía' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta habitación sencilla está ubicada en Playa del Pilón de Azúcar, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: atardeceres en el desierto y chinchorros wayuu. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación sencilla en Playa del Pilón de Azúcar' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta casa familiar en Playa del Pilón de Azúcar es el punto de partida perfecto para conocer Cabo de la Vela y lo mejor de La Guajira.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: kitesurf y chinchorros wayuu. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa familiar en Playa del Pilón de Azúcar' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Este glamping acogedor está ubicado en Frente a la bahía, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: atardeceres en el desierto y el mar Caribe a pocos pasos. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping acogedor en Frente a la bahía' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta cabaña familiar está ubicada en Ojo de Agua, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: atardeceres en el desierto y chinchorros wayuu. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña familiar en Ojo de Agua' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Descubre Cabo de la Vela desde una habitación fresca en Punta Gallinas, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: atardeceres en el desierto y el mar Caribe a pocos pasos. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación fresca en Punta Gallinas' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta casa acogedora está ubicada en Playa del Pilón de Azúcar, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: kitesurf y chinchorros wayuu. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa acogedora en Playa del Pilón de Azúcar' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Este glamping acogedor en Punta Gallinas es el punto de partida perfecto para conocer Cabo de la Vela y lo mejor de La Guajira.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: el mar Caribe a pocos pasos y atardeceres en el desierto. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping acogedor en Punta Gallinas' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta cabaña familiar está ubicada en Punta Gallinas, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: el mar Caribe a pocos pasos y kitesurf. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña familiar en Punta Gallinas' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Descubre Cabo de la Vela desde una habitación luminosa en Playa del Pilón de Azúcar, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: chinchorros wayuu y atardeceres en el desierto. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Playa del Pilón de Azúcar' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Descubre Cabo de la Vela desde una casa exclusiva en Ojo de Agua, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: atardeceres en el desierto y kitesurf. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa exclusiva en Ojo de Agua' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'En Ojo de Agua, Cabo de la Vela, te espera un glamping sencillo con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: el mar Caribe a pocos pasos y chinchorros wayuu. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping sencillo en Ojo de Agua' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta cabaña tranquila en Frente a la bahía es el punto de partida perfecto para conocer Cabo de la Vela y lo mejor de La Guajira.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: kitesurf y atardeceres en el desierto. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña tranquila en Frente a la bahía' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Descubre Cabo de la Vela desde una habitación tradicional en Frente a la bahía, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: atardeceres en el desierto y chinchorros wayuu. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tradicional en Frente a la bahía' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Esta casa moderna está ubicada en Ranchería Wayuu, uno de los sectores más agradables de Cabo de la Vela, La Guajira.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: atardeceres en el desierto y el mar Caribe a pocos pasos. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa moderna en Ranchería Wayuu' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'En Punta Gallinas, Cabo de la Vela, te espera un glamping elegante con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: atardeceres en el desierto y kitesurf. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping elegante en Punta Gallinas' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Descubre Cabo de la Vela desde una cabaña espaciosa en Punta Gallinas, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: chinchorros wayuu y atardeceres en el desierto. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña espaciosa en Punta Gallinas' AND ciudad = 'Cabo de la Vela';
UPDATE publicacion SET descripcion = 'Este apartamento romántico está ubicado en Malecón, uno de los sectores más agradables de Riohacha, La Guajira.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: artesanías wayuu y cocina típica guajira. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento romántico en Malecón' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Descubre Riohacha desde una casa espaciosa en Malecón, ideal para descansar después de un día de paseo.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: vista al malecón y cocina típica guajira. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa espaciosa en Malecón' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'En Malecón, Riohacha, te espera una habitación luminosa con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: vista al malecón y artesanías wayuu. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Malecón' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Esta cabaña encantadora está ubicada en Camarones, uno de los sectores más agradables de Riohacha, La Guajira.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: brisa marina y cocina típica guajira. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña encantadora en Camarones' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Este apartamento romántico está ubicado en Playa de Riohacha, uno de los sectores más agradables de Riohacha, La Guajira.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cocina típica guajira y vista al malecón. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento romántico en Playa de Riohacha' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Descubre Riohacha desde una casa espaciosa en Playa de Riohacha, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: brisa marina y cocina típica guajira. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa espaciosa en Playa de Riohacha' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Esta habitación sencilla en Malecón es el punto de partida perfecto para conocer Riohacha y lo mejor de La Guajira.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: artesanías wayuu y brisa marina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación sencilla en Malecón' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Esta cabaña moderna en Malecón es el punto de partida perfecto para conocer Riohacha y lo mejor de La Guajira.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: brisa marina y vista al malecón. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña moderna en Malecón' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'En Camarones, Riohacha, te espera un apartamento tranquilo con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: artesanías wayuu y vista al malecón. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tranquilo en Camarones' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Esta casa tradicional en Camarones es el punto de partida perfecto para conocer Riohacha y lo mejor de La Guajira.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: artesanías wayuu y vista al malecón. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa tradicional en Camarones' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Esta habitación acogedora en Playa de Riohacha es el punto de partida perfecto para conocer Riohacha y lo mejor de La Guajira.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: vista al malecón y cocina típica guajira. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación acogedora en Playa de Riohacha' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'En Malecón, Riohacha, te espera una cabaña elegante con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: brisa marina y vista al malecón. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña elegante en Malecón' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Descubre Riohacha desde un apartamento romántico en Centro, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cocina típica guajira y brisa marina. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento romántico en Centro' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Descubre Riohacha desde una casa encantadora en Centro, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: brisa marina y artesanías wayuu. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa encantadora en Centro' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Descubre Riohacha desde una habitación romántica en Barrio Nuevo Faro, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cocina típica guajira y vista al malecón. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación romántica en Barrio Nuevo Faro' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'En Malecón, Riohacha, te espera una cabaña rústica con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: artesanías wayuu y vista al malecón. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña rústica en Malecón' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Este apartamento espacioso en Playa de Riohacha es el punto de partida perfecto para conocer Riohacha y lo mejor de La Guajira.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: artesanías wayuu y brisa marina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento espacioso en Playa de Riohacha' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'En Playa de Riohacha, Riohacha, te espera una casa familiar con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: artesanías wayuu y brisa marina. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa familiar en Playa de Riohacha' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Esta habitación moderna en Malecón es el punto de partida perfecto para conocer Riohacha y lo mejor de La Guajira.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: vista al malecón y brisa marina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Malecón' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Esta cabaña familiar está ubicada en Centro, uno de los sectores más agradables de Riohacha, La Guajira.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: artesanías wayuu y cocina típica guajira. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña familiar en Centro' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Este apartamento luminoso está ubicado en Malecón, uno de los sectores más agradables de Riohacha, La Guajira.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: artesanías wayuu y brisa marina. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento luminoso en Malecón' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Esta casa elegante en Malecón es el punto de partida perfecto para conocer Riohacha y lo mejor de La Guajira.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: vista al malecón y artesanías wayuu. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa elegante en Malecón' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Descubre Riohacha desde una habitación moderna en Playa de Riohacha, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: artesanías wayuu y vista al malecón. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Playa de Riohacha' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Descubre Riohacha desde una cabaña encantadora en Barrio Nuevo Faro, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: brisa marina y cocina típica guajira. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña encantadora en Barrio Nuevo Faro' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Este apartamento moderno en Playa de Riohacha es el punto de partida perfecto para conocer Riohacha y lo mejor de La Guajira.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: brisa marina y cocina típica guajira. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento moderno en Playa de Riohacha' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva en Barrio Nuevo Faro es el punto de partida perfecto para conocer Riohacha y lo mejor de La Guajira.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: cocina típica guajira y artesanías wayuu. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa exclusiva en Barrio Nuevo Faro' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Esta habitación espaciosa está ubicada en Centro, uno de los sectores más agradables de Riohacha, La Guajira.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cocina típica guajira y artesanías wayuu. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación espaciosa en Centro' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'Esta cabaña encantadora está ubicada en Centro, uno de los sectores más agradables de Riohacha, La Guajira.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: brisa marina y artesanías wayuu. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña encantadora en Centro' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'En Camarones, Riohacha, te espera un apartamento exclusivo con todo lo necesario para una estadía tranquila.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: artesanías wayuu y cocina típica guajira. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento exclusivo en Camarones' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'En Malecón, Riohacha, te espera una casa exclusiva con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: brisa marina y vista al malecón. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa exclusiva en Malecón' AND ciudad = 'Riohacha';
UPDATE publicacion SET descripcion = 'En Centro Histórico, Santa Marta, te espera un apartamento romántico con todo lo necesario para una estadía tranquila.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: acceso al Parque Tayrona y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento romántico en Centro Histórico' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Esta casa fresca en Centro Histórico es el punto de partida perfecto para conocer Santa Marta y lo mejor de Magdalena.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y acceso al Parque Tayrona. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa fresca en Centro Histórico' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Esta cabaña sencilla en Centro Histórico es el punto de partida perfecto para conocer Santa Marta y lo mejor de Magdalena.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: vista a la Sierra Nevada y playas tranquilas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña sencilla en Centro Histórico' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Este glamping familiar está ubicado en Bahía Concha, uno de los sectores más agradables de Santa Marta, Magdalena.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: piscina y acceso al Parque Tayrona. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping familiar en Bahía Concha' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Esta finca acogedora está ubicada en Taganga, uno de los sectores más agradables de Santa Marta, Magdalena.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: playas tranquilas y piscina. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca acogedora en Taganga' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'En Minca, Santa Marta, te espera un apartamento espacioso con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: acceso al Parque Tayrona y playas tranquilas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento espacioso en Minca' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Esta casa encantadora en Taganga es el punto de partida perfecto para conocer Santa Marta y lo mejor de Magdalena.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: playas tranquilas y piscina. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa encantadora en Taganga' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Esta cabaña elegante está ubicada en Bahía Concha, uno de los sectores más agradables de Santa Marta, Magdalena.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: acceso al Parque Tayrona y playas tranquilas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña elegante en Bahía Concha' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Este glamping elegante está ubicado en Bahía Concha, uno de los sectores más agradables de Santa Marta, Magdalena.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: piscina y vista a la Sierra Nevada. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping elegante en Bahía Concha' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'En Minca, Santa Marta, te espera una finca encantadora con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: playas tranquilas y acceso al Parque Tayrona. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca encantadora en Minca' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Este apartamento acogedor en Centro Histórico es el punto de partida perfecto para conocer Santa Marta y lo mejor de Magdalena.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: playas tranquilas y vista a la Sierra Nevada. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento acogedor en Centro Histórico' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'En Minca, Santa Marta, te espera una casa luminosa con todo lo necesario para una estadía tranquila.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y vista a la Sierra Nevada. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa luminosa en Minca' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Esta cabaña familiar en El Rodadero es el punto de partida perfecto para conocer Santa Marta y lo mejor de Magdalena.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: piscina y vista a la Sierra Nevada. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña familiar en El Rodadero' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'En El Rodadero, Santa Marta, te espera un glamping tradicional con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: playas tranquilas y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping tradicional en El Rodadero' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Esta finca moderna está ubicada en Minca, uno de los sectores más agradables de Santa Marta, Magdalena.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: vista a la Sierra Nevada y piscina. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca moderna en Minca' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Este apartamento luminoso en Pozos Colorados es el punto de partida perfecto para conocer Santa Marta y lo mejor de Magdalena.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: playas tranquilas y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento luminoso en Pozos Colorados' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'En Bahía Concha, Santa Marta, te espera una casa familiar con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: acceso al Parque Tayrona y piscina. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa familiar en Bahía Concha' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Descubre Santa Marta desde una cabaña exclusiva en El Rodadero, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: piscina y acceso al Parque Tayrona. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña exclusiva en El Rodadero' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Este glamping rústico está ubicado en Taganga, uno de los sectores más agradables de Santa Marta, Magdalena.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: playas tranquilas y piscina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping rústico en Taganga' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Esta finca acogedora en Pozos Colorados es el punto de partida perfecto para conocer Santa Marta y lo mejor de Magdalena.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: playas tranquilas y acceso al Parque Tayrona. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca acogedora en Pozos Colorados' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Este apartamento sencillo está ubicado en Pozos Colorados, uno de los sectores más agradables de Santa Marta, Magdalena.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: acceso al Parque Tayrona y vista a la Sierra Nevada. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento sencillo en Pozos Colorados' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Descubre Santa Marta desde una casa colorida en Pozos Colorados, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: playas tranquilas y piscina. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa colorida en Pozos Colorados' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'En Taganga, Santa Marta, te espera una cabaña tranquila con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: vista a la Sierra Nevada y playas tranquilas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña tranquila en Taganga' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Descubre Santa Marta desde un glamping tradicional en Minca, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: vista a la Sierra Nevada y playas tranquilas. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping tradicional en Minca' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Descubre Santa Marta desde una finca romántica en Bahía Concha, ideal para descansar después de un día de paseo.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: vista a la Sierra Nevada y acceso al Parque Tayrona. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca romántica en Bahía Concha' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Este apartamento fresco en El Rodadero es el punto de partida perfecto para conocer Santa Marta y lo mejor de Magdalena.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: playas tranquilas y acceso al Parque Tayrona. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento fresco en El Rodadero' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Esta casa sencilla en Centro Histórico es el punto de partida perfecto para conocer Santa Marta y lo mejor de Magdalena.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y vista a la Sierra Nevada. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa sencilla en Centro Histórico' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Esta cabaña colorida en Pozos Colorados es el punto de partida perfecto para conocer Santa Marta y lo mejor de Magdalena.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: playas tranquilas y acceso al Parque Tayrona. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña colorida en Pozos Colorados' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Este glamping moderno está ubicado en Taganga, uno de los sectores más agradables de Santa Marta, Magdalena.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: acceso al Parque Tayrona y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping moderno en Taganga' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Descubre Santa Marta desde una finca romántica en Minca, ideal para descansar después de un día de paseo.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 11 personas.

Lo mejor del entorno: acceso al Parque Tayrona y vista a la Sierra Nevada. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca romántica en Minca' AND ciudad = 'Santa Marta';
UPDATE publicacion SET descripcion = 'Este apartamento moderno en Manga es el punto de partida perfecto para conocer Cartagena y lo mejor de Bolívar.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: terraza con vista al mar y balcones coloniales. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento moderno en Manga' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Esta casa moderna en Manga es el punto de partida perfecto para conocer Cartagena y lo mejor de Bolívar.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: balcones coloniales y piscina en la azotea. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa moderna en Manga' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'En Ciudad Amurallada, Cartagena, te espera una habitación elegante con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: piscina en la azotea y calles llenas de color. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación elegante en Ciudad Amurallada' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Este apartamento sencillo en Manga es el punto de partida perfecto para conocer Cartagena y lo mejor de Bolívar.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: terraza con vista al mar y piscina en la azotea. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento sencillo en Manga' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'En Manga, Cartagena, te espera una casa tradicional con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: balcones coloniales y terraza con vista al mar. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa tradicional en Manga' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Esta habitación luminosa en Manga es el punto de partida perfecto para conocer Cartagena y lo mejor de Bolívar.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: piscina en la azotea y terraza con vista al mar. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Manga' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Este apartamento fresco en Manga es el punto de partida perfecto para conocer Cartagena y lo mejor de Bolívar.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina en la azotea y balcones coloniales. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento fresco en Manga' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Descubre Cartagena desde una casa familiar en Ciudad Amurallada, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: calles llenas de color y terraza con vista al mar. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa familiar en Ciudad Amurallada' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Descubre Cartagena desde una habitación acogedora en Getsemaní, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: balcones coloniales y terraza con vista al mar. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación acogedora en Getsemaní' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Descubre Cartagena desde un apartamento tradicional en Ciudad Amurallada, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: balcones coloniales y terraza con vista al mar. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tradicional en Ciudad Amurallada' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Descubre Cartagena desde una casa sencilla en Barú, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: calles llenas de color y balcones coloniales. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa sencilla en Barú' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Descubre Cartagena desde una habitación espaciosa en Ciudad Amurallada, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: balcones coloniales y terraza con vista al mar. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación espaciosa en Ciudad Amurallada' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Descubre Cartagena desde un apartamento sencillo en Bocagrande, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: terraza con vista al mar y calles llenas de color. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento sencillo en Bocagrande' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva está ubicada en Ciudad Amurallada, uno de los sectores más agradables de Cartagena, Bolívar.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: balcones coloniales y calles llenas de color. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa exclusiva en Ciudad Amurallada' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Esta habitación tranquila en Manga es el punto de partida perfecto para conocer Cartagena y lo mejor de Bolívar.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: terraza con vista al mar y piscina en la azotea. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tranquila en Manga' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Descubre Cartagena desde un apartamento fresco en Bocagrande, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina en la azotea y balcones coloniales. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento fresco en Bocagrande' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'En Getsemaní, Cartagena, te espera una casa colorida con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: terraza con vista al mar y piscina en la azotea. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa colorida en Getsemaní' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'En Bocagrande, Cartagena, te espera una habitación fresca con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: balcones coloniales y piscina en la azotea. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación fresca en Bocagrande' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Descubre Cartagena desde un apartamento rústico en Barú, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: balcones coloniales y piscina en la azotea. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento rústico en Barú' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Esta casa romántica en Castillogrande es el punto de partida perfecto para conocer Cartagena y lo mejor de Bolívar.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: piscina en la azotea y calles llenas de color. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa romántica en Castillogrande' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'En Castillogrande, Cartagena, te espera una habitación romántica con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: terraza con vista al mar y piscina en la azotea. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación romántica en Castillogrande' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'En Castillogrande, Cartagena, te espera un apartamento rústico con todo lo necesario para una estadía tranquila.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: calles llenas de color y balcones coloniales. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento rústico en Castillogrande' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Descubre Cartagena desde una casa moderna en Getsemaní, ideal para descansar después de un día de paseo.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: balcones coloniales y terraza con vista al mar. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa moderna en Getsemaní' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Esta habitación familiar está ubicada en Bocagrande, uno de los sectores más agradables de Cartagena, Bolívar.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: balcones coloniales y calles llenas de color. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Bocagrande' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Este apartamento exclusivo en Bocagrande es el punto de partida perfecto para conocer Cartagena y lo mejor de Bolívar.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: calles llenas de color y piscina en la azotea. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento exclusivo en Bocagrande' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva en Bocagrande es el punto de partida perfecto para conocer Cartagena y lo mejor de Bolívar.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: terraza con vista al mar y balcones coloniales. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa exclusiva en Bocagrande' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Esta habitación familiar en Castillogrande es el punto de partida perfecto para conocer Cartagena y lo mejor de Bolívar.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: terraza con vista al mar y piscina en la azotea. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Castillogrande' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Este apartamento romántico está ubicado en Bocagrande, uno de los sectores más agradables de Cartagena, Bolívar.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina en la azotea y calles llenas de color. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento romántico en Bocagrande' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Esta casa elegante en Manga es el punto de partida perfecto para conocer Cartagena y lo mejor de Bolívar.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: calles llenas de color y piscina en la azotea. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa elegante en Manga' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Esta habitación espaciosa en Bocagrande es el punto de partida perfecto para conocer Cartagena y lo mejor de Bolívar.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: terraza con vista al mar y calles llenas de color. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación espaciosa en Bocagrande' AND ciudad = 'Cartagena';
UPDATE publicacion SET descripcion = 'Descubre Mompox desde una casa romántica en Albarrada, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: filigrana momposina y patios con árboles frutales. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa romántica en Albarrada' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Esta habitación espaciosa está ubicada en Calle Real del Medio, uno de los sectores más agradables de Mompox, Bolívar.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: filigrana momposina y paseos por el río Magdalena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación espaciosa en Calle Real del Medio' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Este apartamento fresco en Calle Real del Medio es el punto de partida perfecto para conocer Mompox y lo mejor de Bolívar.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: paseos por el río Magdalena y filigrana momposina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento fresco en Calle Real del Medio' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Descubre Mompox desde una casa familiar en Calle Real del Medio, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: paseos por el río Magdalena y patios con árboles frutales. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa familiar en Calle Real del Medio' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Esta habitación familiar está ubicada en Calle Real del Medio, uno de los sectores más agradables de Mompox, Bolívar.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: filigrana momposina y arquitectura colonial. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Calle Real del Medio' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Este apartamento elegante está ubicado en Albarrada, uno de los sectores más agradables de Mompox, Bolívar.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: filigrana momposina y patios con árboles frutales. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento elegante en Albarrada' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Esta casa elegante está ubicada en Albarrada, uno de los sectores más agradables de Mompox, Bolívar.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: arquitectura colonial y paseos por el río Magdalena. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa elegante en Albarrada' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Esta habitación romántica está ubicada en Centro Histórico, uno de los sectores más agradables de Mompox, Bolívar.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: patios con árboles frutales y paseos por el río Magdalena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación romántica en Centro Histórico' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Descubre Mompox desde un apartamento familiar en Centro Histórico, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: arquitectura colonial y filigrana momposina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento familiar en Centro Histórico' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Esta casa fresca está ubicada en Calle Real del Medio, uno de los sectores más agradables de Mompox, Bolívar.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: patios con árboles frutales y arquitectura colonial. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa fresca en Calle Real del Medio' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'En Calle Real del Medio, Mompox, te espera una habitación rústica con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: patios con árboles frutales y arquitectura colonial. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación rústica en Calle Real del Medio' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Este apartamento tranquilo está ubicado en Albarrada, uno de los sectores más agradables de Mompox, Bolívar.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: paseos por el río Magdalena y arquitectura colonial. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tranquilo en Albarrada' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva está ubicada en Centro Histórico, uno de los sectores más agradables de Mompox, Bolívar.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: arquitectura colonial y filigrana momposina. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa exclusiva en Centro Histórico' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Descubre Mompox desde una habitación luminosa en Plaza de Santa Bárbara, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: filigrana momposina y paseos por el río Magdalena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Plaza de Santa Bárbara' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Este apartamento tranquilo en Plaza de Santa Bárbara es el punto de partida perfecto para conocer Mompox y lo mejor de Bolívar.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: arquitectura colonial y filigrana momposina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tranquilo en Plaza de Santa Bárbara' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Descubre Mompox desde una casa familiar en Plaza de Santa Bárbara, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: paseos por el río Magdalena y filigrana momposina. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa familiar en Plaza de Santa Bárbara' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'En Calle Real del Medio, Mompox, te espera una habitación sencilla con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: arquitectura colonial y filigrana momposina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación sencilla en Calle Real del Medio' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'En Albarrada, Mompox, te espera un apartamento luminoso con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: arquitectura colonial y filigrana momposina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento luminoso en Albarrada' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Esta casa encantadora en Calle Real del Medio es el punto de partida perfecto para conocer Mompox y lo mejor de Bolívar.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: arquitectura colonial y paseos por el río Magdalena. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa encantadora en Calle Real del Medio' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Esta habitación exclusiva está ubicada en Calle Real del Medio, uno de los sectores más agradables de Mompox, Bolívar.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: patios con árboles frutales y filigrana momposina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación exclusiva en Calle Real del Medio' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Este apartamento encantador en Plaza de Santa Bárbara es el punto de partida perfecto para conocer Mompox y lo mejor de Bolívar.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: arquitectura colonial y filigrana momposina. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento encantador en Plaza de Santa Bárbara' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Esta casa espaciosa en Albarrada es el punto de partida perfecto para conocer Mompox y lo mejor de Bolívar.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: filigrana momposina y arquitectura colonial. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa espaciosa en Albarrada' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Esta habitación luminosa en Centro Histórico es el punto de partida perfecto para conocer Mompox y lo mejor de Bolívar.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: patios con árboles frutales y arquitectura colonial. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Centro Histórico' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'En Albarrada, Mompox, te espera un apartamento romántico con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: arquitectura colonial y patios con árboles frutales. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento romántico en Albarrada' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Esta casa fresca está ubicada en Albarrada, uno de los sectores más agradables de Mompox, Bolívar.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: arquitectura colonial y paseos por el río Magdalena. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa fresca en Albarrada' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Descubre Mompox desde una habitación tranquila en Plaza de Santa Bárbara, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: filigrana momposina y patios con árboles frutales. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tranquila en Plaza de Santa Bárbara' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'En Centro Histórico, Mompox, te espera un apartamento sencillo con todo lo necesario para una estadía tranquila.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: patios con árboles frutales y paseos por el río Magdalena. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento sencillo en Centro Histórico' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'En Centro Histórico, Mompox, te espera una casa rústica con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: paseos por el río Magdalena y patios con árboles frutales. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa rústica en Centro Histórico' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Esta habitación colorida en Calle Real del Medio es el punto de partida perfecto para conocer Mompox y lo mejor de Bolívar.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: filigrana momposina y arquitectura colonial. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación colorida en Calle Real del Medio' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Descubre Mompox desde un apartamento sencillo en Albarrada, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: arquitectura colonial y paseos por el río Magdalena. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento sencillo en Albarrada' AND ciudad = 'Mompox';
UPDATE publicacion SET descripcion = 'Este apartamento moderno está ubicado en Riomar, uno de los sectores más agradables de Barranquilla, Atlántico.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: aire acondicionado y cerca al Gran Malecón. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento moderno en Riomar' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Descubre Barranquilla desde una casa tradicional en Alto Prado, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: zona gastronómica y ambiente de Carnaval. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa tradicional en Alto Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'En Alto Prado, Barranquilla, te espera una habitación luminosa con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: ambiente de Carnaval y aire acondicionado. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Alto Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Este apartamento espacioso está ubicado en Villa Santos, uno de los sectores más agradables de Barranquilla, Atlántico.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: aire acondicionado y ambiente de Carnaval. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento espacioso en Villa Santos' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'En El Prado, Barranquilla, te espera una casa romántica con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: cerca al Gran Malecón y zona gastronómica. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa romántica en El Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Esta habitación espaciosa está ubicada en El Prado, uno de los sectores más agradables de Barranquilla, Atlántico.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: aire acondicionado y ambiente de Carnaval. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación espaciosa en El Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'En El Prado, Barranquilla, te espera un apartamento tradicional con todo lo necesario para una estadía tranquila.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: ambiente de Carnaval y aire acondicionado. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento tradicional en El Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'En El Prado, Barranquilla, te espera una casa acogedora con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: zona gastronómica y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa acogedora en El Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Descubre Barranquilla desde una habitación encantadora en Villa Santos, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: zona gastronómica y cerca al Gran Malecón. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación encantadora en Villa Santos' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Descubre Barranquilla desde un apartamento romántico en Riomar, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: aire acondicionado y ambiente de Carnaval. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento romántico en Riomar' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'En El Prado, Barranquilla, te espera una casa elegante con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: cerca al Gran Malecón y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa elegante en El Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Descubre Barranquilla desde una habitación familiar en El Prado, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: aire acondicionado y cerca al Gran Malecón. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en El Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Descubre Barranquilla desde un apartamento espacioso en El Prado, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona gastronómica y aire acondicionado. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento espacioso en El Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Descubre Barranquilla desde una casa acogedora en Villa Santos, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: ambiente de Carnaval y cerca al Gran Malecón. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa acogedora en Villa Santos' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Esta habitación colorida en Villa Santos es el punto de partida perfecto para conocer Barranquilla y lo mejor de Atlántico.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: zona gastronómica y cerca al Gran Malecón. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación colorida en Villa Santos' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Descubre Barranquilla desde un apartamento moderno en Gran Malecón, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona gastronómica y ambiente de Carnaval. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento moderno en Gran Malecón' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Descubre Barranquilla desde una casa fresca en Riomar, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: aire acondicionado y cerca al Gran Malecón. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa fresca en Riomar' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Esta habitación moderna en Gran Malecón es el punto de partida perfecto para conocer Barranquilla y lo mejor de Atlántico.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: zona gastronómica y ambiente de Carnaval. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Gran Malecón' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Este apartamento exclusivo está ubicado en Gran Malecón, uno de los sectores más agradables de Barranquilla, Atlántico.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca al Gran Malecón y ambiente de Carnaval. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento exclusivo en Gran Malecón' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva está ubicada en Gran Malecón, uno de los sectores más agradables de Barranquilla, Atlántico.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: zona gastronómica y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa exclusiva en Gran Malecón' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'En Gran Malecón, Barranquilla, te espera una habitación encantadora con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: ambiente de Carnaval y cerca al Gran Malecón. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación encantadora en Gran Malecón' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'En Villa Santos, Barranquilla, te espera un apartamento encantador con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca al Gran Malecón y aire acondicionado. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento encantador en Villa Santos' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Descubre Barranquilla desde una casa espaciosa en Alto Prado, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: cerca al Gran Malecón y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa espaciosa en Alto Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'En Riomar, Barranquilla, te espera una habitación tradicional con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: aire acondicionado y ambiente de Carnaval. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tradicional en Riomar' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'En Villa Santos, Barranquilla, te espera un apartamento fresco con todo lo necesario para una estadía tranquila.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca al Gran Malecón y aire acondicionado. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento fresco en Villa Santos' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'En Alto Prado, Barranquilla, te espera una casa encantadora con todo lo necesario para una estadía tranquila.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: cerca al Gran Malecón y ambiente de Carnaval. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa encantadora en Alto Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Esta habitación fresca está ubicada en El Prado, uno de los sectores más agradables de Barranquilla, Atlántico.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cerca al Gran Malecón y ambiente de Carnaval. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación fresca en El Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Este apartamento rústico está ubicado en El Prado, uno de los sectores más agradables de Barranquilla, Atlántico.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca al Gran Malecón y ambiente de Carnaval. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento rústico en El Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Descubre Barranquilla desde una casa colorida en Gran Malecón, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: aire acondicionado y cerca al Gran Malecón. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa colorida en Gran Malecón' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'Esta habitación moderna en El Prado es el punto de partida perfecto para conocer Barranquilla y lo mejor de Atlántico.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: aire acondicionado y cerca al Gran Malecón. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en El Prado' AND ciudad = 'Barranquilla';
UPDATE publicacion SET descripcion = 'En North End, San Andrés, te espera una casa rústica con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: snorkel y mar de siete colores. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa rústica en North End' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Descubre San Andrés desde un apartamento moderno en San Luis, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cultura raizal y snorkel. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento moderno en San Luis' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Esta cabaña acogedora en La Loma es el punto de partida perfecto para conocer San Andrés y lo mejor de San Andrés y Providencia.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: snorkel y mar de siete colores. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña acogedora en La Loma' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Esta habitación familiar está ubicada en Rocky Cay, uno de los sectores más agradables de San Andrés, San Andrés y Providencia.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: snorkel y cultura raizal. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Rocky Cay' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'En North End, San Andrés, te espera una casa romántica con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: snorkel y playa a pasos. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa romántica en North End' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Este apartamento exclusivo está ubicado en Rocky Cay, uno de los sectores más agradables de San Andrés, San Andrés y Providencia.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cultura raizal y snorkel. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento exclusivo en Rocky Cay' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Esta cabaña exclusiva está ubicada en La Loma, uno de los sectores más agradables de San Andrés, San Andrés y Providencia.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: snorkel y cultura raizal. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña exclusiva en La Loma' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Esta habitación moderna en Spratt Bight es el punto de partida perfecto para conocer San Andrés y lo mejor de San Andrés y Providencia.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cultura raizal y mar de siete colores. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Spratt Bight' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Descubre San Andrés desde una casa espaciosa en Rocky Cay, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: snorkel y cultura raizal. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa espaciosa en Rocky Cay' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Este apartamento espacioso en San Luis es el punto de partida perfecto para conocer San Andrés y lo mejor de San Andrés y Providencia.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: mar de siete colores y playa a pasos. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento espacioso en San Luis' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Descubre San Andrés desde una cabaña exclusiva en Rocky Cay, ideal para descansar después de un día de paseo.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: snorkel y playa a pasos. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña exclusiva en Rocky Cay' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Esta habitación colorida en La Loma es el punto de partida perfecto para conocer San Andrés y lo mejor de San Andrés y Providencia.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cultura raizal y mar de siete colores. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación colorida en La Loma' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'En San Luis, San Andrés, te espera una casa elegante con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: playa a pasos y mar de siete colores. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa elegante en San Luis' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Este apartamento tranquilo está ubicado en North End, uno de los sectores más agradables de San Andrés, San Andrés y Providencia.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: playa a pasos y mar de siete colores. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento tranquilo en North End' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Esta cabaña rústica en Rocky Cay es el punto de partida perfecto para conocer San Andrés y lo mejor de San Andrés y Providencia.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: snorkel y cultura raizal. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña rústica en Rocky Cay' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Esta habitación exclusiva en San Luis es el punto de partida perfecto para conocer San Andrés y lo mejor de San Andrés y Providencia.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cultura raizal y playa a pasos. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación exclusiva en San Luis' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva está ubicada en San Luis, uno de los sectores más agradables de San Andrés, San Andrés y Providencia.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: mar de siete colores y playa a pasos. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa exclusiva en San Luis' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Descubre San Andrés desde un apartamento tradicional en North End, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: mar de siete colores y cultura raizal. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tradicional en North End' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Descubre San Andrés desde una cabaña tradicional en San Luis, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: snorkel y cultura raizal. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña tradicional en San Luis' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Descubre San Andrés desde una habitación luminosa en San Luis, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: mar de siete colores y cultura raizal. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en San Luis' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Descubre San Andrés desde una casa luminosa en La Loma, ideal para descansar después de un día de paseo.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: cultura raizal y mar de siete colores. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa luminosa en La Loma' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Este apartamento colorido en Spratt Bight es el punto de partida perfecto para conocer San Andrés y lo mejor de San Andrés y Providencia.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: snorkel y mar de siete colores. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento colorido en Spratt Bight' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Descubre San Andrés desde una cabaña romántica en La Loma, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: cultura raizal y playa a pasos. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña romántica en La Loma' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Esta habitación acogedora en North End es el punto de partida perfecto para conocer San Andrés y lo mejor de San Andrés y Providencia.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: snorkel y playa a pasos. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación acogedora en North End' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'En North End, San Andrés, te espera una casa sencilla con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: snorkel y mar de siete colores. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa sencilla en North End' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Descubre San Andrés desde un apartamento encantador en North End, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: mar de siete colores y playa a pasos. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento encantador en North End' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Descubre San Andrés desde una cabaña luminosa en La Loma, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: cultura raizal y playa a pasos. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña luminosa en La Loma' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Esta habitación romántica está ubicada en North End, uno de los sectores más agradables de San Andrés, San Andrés y Providencia.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: snorkel y mar de siete colores. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación romántica en North End' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Esta casa tradicional está ubicada en San Luis, uno de los sectores más agradables de San Andrés, San Andrés y Providencia.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: cultura raizal y snorkel. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa tradicional en San Luis' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Descubre San Andrés desde un apartamento espacioso en North End, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: playa a pasos y snorkel. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento espacioso en North End' AND ciudad = 'San Andrés';
UPDATE publicacion SET descripcion = 'Esta cabaña sencilla en Avenida La Playa es el punto de partida perfecto para conocer Tolú y lo mejor de Sucre.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: pescado fresco y playa tranquila. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña sencilla en Avenida La Playa' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Descubre Tolú desde una casa tranquila en Avenida La Playa, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: playa tranquila y pescado fresco. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa tranquila en Avenida La Playa' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Descubre Tolú desde un apartamento colorido en Avenida La Playa, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: pescado fresco y paseos a las islas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento colorido en Avenida La Playa' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Esta finca familiar está ubicada en Centro, uno de los sectores más agradables de Tolú, Sucre.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 6 personas.

Lo mejor del entorno: playa tranquila y manglares. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca familiar en Centro' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'En Coveñas, Tolú, te espera una cabaña rústica con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: pescado fresco y playa tranquila. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña rústica en Coveñas' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Descubre Tolú desde una casa espaciosa en Islas de San Bernardo, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: playa tranquila y pescado fresco. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa espaciosa en Islas de San Bernardo' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'En Avenida La Playa, Tolú, te espera un apartamento tradicional con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: pescado fresco y playa tranquila. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tradicional en Avenida La Playa' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Descubre Tolú desde una finca romántica en Avenida La Playa, ideal para descansar después de un día de paseo.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: manglares y pescado fresco. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca romántica en Avenida La Playa' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'En Centro, Tolú, te espera una cabaña acogedora con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: pescado fresco y paseos a las islas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña acogedora en Centro' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'En Coveñas, Tolú, te espera una casa fresca con todo lo necesario para una estadía tranquila.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: playa tranquila y manglares. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa fresca en Coveñas' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Este apartamento sencillo en Centro es el punto de partida perfecto para conocer Tolú y lo mejor de Sucre.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: pescado fresco y playa tranquila. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento sencillo en Centro' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Descubre Tolú desde una finca acogedora en Coveñas, ideal para descansar después de un día de paseo.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 14 personas.

Lo mejor del entorno: paseos a las islas y pescado fresco. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca acogedora en Coveñas' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Esta cabaña romántica está ubicada en Centro, uno de los sectores más agradables de Tolú, Sucre.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: playa tranquila y paseos a las islas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña romántica en Centro' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'En Centro, Tolú, te espera una casa colorida con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: playa tranquila y paseos a las islas. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa colorida en Centro' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Este apartamento exclusivo en Centro es el punto de partida perfecto para conocer Tolú y lo mejor de Sucre.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: playa tranquila y paseos a las islas. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento exclusivo en Centro' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Esta finca tranquila en Centro es el punto de partida perfecto para conocer Tolú y lo mejor de Sucre.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: manglares y paseos a las islas. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca tranquila en Centro' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Descubre Tolú desde una cabaña exclusiva en Islas de San Bernardo, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: manglares y paseos a las islas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña exclusiva en Islas de San Bernardo' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Descubre Tolú desde una casa moderna en Avenida La Playa, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: pescado fresco y manglares. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa moderna en Avenida La Playa' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Este apartamento tranquilo está ubicado en Centro, uno de los sectores más agradables de Tolú, Sucre.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: playa tranquila y manglares. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tranquilo en Centro' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Esta finca luminosa en Avenida La Playa es el punto de partida perfecto para conocer Tolú y lo mejor de Sucre.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 8 personas.

Lo mejor del entorno: paseos a las islas y playa tranquila. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca luminosa en Avenida La Playa' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Descubre Tolú desde una cabaña romántica en Avenida La Playa, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: paseos a las islas y playa tranquila. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña romántica en Avenida La Playa' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Esta casa espaciosa está ubicada en Coveñas, uno de los sectores más agradables de Tolú, Sucre.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: playa tranquila y pescado fresco. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa espaciosa en Coveñas' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Descubre Tolú desde un apartamento moderno en Centro, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: pescado fresco y manglares. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento moderno en Centro' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Descubre Tolú desde una finca espaciosa en Islas de San Bernardo, ideal para descansar después de un día de paseo.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 6 personas.

Lo mejor del entorno: manglares y playa tranquila. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca espaciosa en Islas de San Bernardo' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Descubre Tolú desde una cabaña encantadora en Islas de San Bernardo, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: manglares y pescado fresco. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña encantadora en Islas de San Bernardo' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Esta casa elegante en Islas de San Bernardo es el punto de partida perfecto para conocer Tolú y lo mejor de Sucre.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: playa tranquila y paseos a las islas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa elegante en Islas de San Bernardo' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Este apartamento moderno está ubicado en Islas de San Bernardo, uno de los sectores más agradables de Tolú, Sucre.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: pescado fresco y manglares. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento moderno en Islas de San Bernardo' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Esta finca colorida está ubicada en Avenida La Playa, uno de los sectores más agradables de Tolú, Sucre.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: paseos a las islas y pescado fresco. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca colorida en Avenida La Playa' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'En Islas de San Bernardo, Tolú, te espera una cabaña moderna con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: pescado fresco y paseos a las islas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña moderna en Islas de San Bernardo' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Esta casa encantadora en Avenida La Playa es el punto de partida perfecto para conocer Tolú y lo mejor de Sucre.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: playa tranquila y paseos a las islas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa encantadora en Avenida La Playa' AND ciudad = 'Tolú';
UPDATE publicacion SET descripcion = 'Este apartamento exclusivo está ubicado en El Recreo, uno de los sectores más agradables de Montería, Córdoba.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: aire acondicionado y cerca a la Ronda del Sinú. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento exclusivo en El Recreo' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Esta casa sencilla está ubicada en Ronda del Sinú, uno de los sectores más agradables de Montería, Córdoba.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: tradición ganadera y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa sencilla en Ronda del Sinú' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Descubre Montería desde una finca tranquila en Centro, ideal para descansar después de un día de paseo.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: aire acondicionado y cerca a la Ronda del Sinú. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca tranquila en Centro' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Descubre Montería desde un apartamento espacioso en Centro, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca a la Ronda del Sinú y aire acondicionado. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento espacioso en Centro' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'En La Castellana, Montería, te espera una casa tranquila con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: tradición ganadera y zona tranquila. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa tranquila en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Esta finca tradicional está ubicada en La Castellana, uno de los sectores más agradables de Montería, Córdoba.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 11 personas.

Lo mejor del entorno: zona tranquila y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca tradicional en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Este apartamento luminoso está ubicado en La Castellana, uno de los sectores más agradables de Montería, Córdoba.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona tranquila y tradición ganadera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento luminoso en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Esta casa acogedora en Centro es el punto de partida perfecto para conocer Montería y lo mejor de Córdoba.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: cerca a la Ronda del Sinú y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa acogedora en Centro' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Esta finca espaciosa está ubicada en El Recreo, uno de los sectores más agradables de Montería, Córdoba.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: cerca a la Ronda del Sinú y tradición ganadera. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca espaciosa en El Recreo' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Este apartamento rústico está ubicado en Centro, uno de los sectores más agradables de Montería, Córdoba.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca a la Ronda del Sinú y tradición ganadera. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento rústico en Centro' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Esta casa colorida en La Castellana es el punto de partida perfecto para conocer Montería y lo mejor de Córdoba.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: aire acondicionado y cerca a la Ronda del Sinú. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa colorida en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'En Centro, Montería, te espera una finca sencilla con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: aire acondicionado y cerca a la Ronda del Sinú. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca sencilla en Centro' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Descubre Montería desde un apartamento exclusivo en La Castellana, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona tranquila y tradición ganadera. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento exclusivo en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'En Centro, Montería, te espera una casa tranquila con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: aire acondicionado y zona tranquila. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa tranquila en Centro' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Esta finca espaciosa en Ronda del Sinú es el punto de partida perfecto para conocer Montería y lo mejor de Córdoba.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 8 personas.

Lo mejor del entorno: aire acondicionado y cerca a la Ronda del Sinú. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca espaciosa en Ronda del Sinú' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Este apartamento romántico en La Castellana es el punto de partida perfecto para conocer Montería y lo mejor de Córdoba.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona tranquila y aire acondicionado. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento romántico en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Descubre Montería desde una casa moderna en Centro, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: zona tranquila y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa moderna en Centro' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'En Centro, Montería, te espera una finca moderna con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: zona tranquila y tradición ganadera. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca moderna en Centro' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Descubre Montería desde un apartamento acogedor en La Castellana, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona tranquila y tradición ganadera. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento acogedor en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Esta casa elegante en La Castellana es el punto de partida perfecto para conocer Montería y lo mejor de Córdoba.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: zona tranquila y cerca a la Ronda del Sinú. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa elegante en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Descubre Montería desde una finca rústica en Centro, ideal para descansar después de un día de paseo.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: cerca a la Ronda del Sinú y zona tranquila. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca rústica en Centro' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Este apartamento tradicional en Ronda del Sinú es el punto de partida perfecto para conocer Montería y lo mejor de Córdoba.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca a la Ronda del Sinú y zona tranquila. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento tradicional en Ronda del Sinú' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Esta casa fresca está ubicada en La Castellana, uno de los sectores más agradables de Montería, Córdoba.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: zona tranquila y tradición ganadera. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa fresca en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Esta finca elegante en La Castellana es el punto de partida perfecto para conocer Montería y lo mejor de Córdoba.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: tradición ganadera y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca elegante en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Este apartamento luminoso en El Recreo es el punto de partida perfecto para conocer Montería y lo mejor de Córdoba.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: aire acondicionado y cerca a la Ronda del Sinú. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento luminoso en El Recreo' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'En La Castellana, Montería, te espera una casa luminosa con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: zona tranquila y cerca a la Ronda del Sinú. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa luminosa en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Esta finca rústica está ubicada en La Castellana, uno de los sectores más agradables de Montería, Córdoba.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: cerca a la Ronda del Sinú y zona tranquila. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca rústica en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Descubre Montería desde un apartamento fresco en La Castellana, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: tradición ganadera y aire acondicionado. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento fresco en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Esta casa rústica en La Castellana es el punto de partida perfecto para conocer Montería y lo mejor de Córdoba.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: zona tranquila y tradición ganadera. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa rústica en La Castellana' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Esta finca tradicional está ubicada en El Recreo, uno de los sectores más agradables de Montería, Córdoba.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: tradición ganadera y cerca a la Ronda del Sinú. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca tradicional en El Recreo' AND ciudad = 'Montería';
UPDATE publicacion SET descripcion = 'Descubre Valledupar desde una casa elegante en Río Guatapurí, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: patio con hamacas y cuna del vallenato. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa elegante en Río Guatapurí' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'En Novalito, Valledupar, te espera un apartamento fresco con todo lo necesario para una estadía tranquila.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: patio con hamacas y festival vallenato. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento fresco en Novalito' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Esta finca tradicional está ubicada en Río Guatapurí, uno de los sectores más agradables de Valledupar, Cesar.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: cuna del vallenato y patio con hamacas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca tradicional en Río Guatapurí' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Descubre Valledupar desde una casa romántica en Los Mayales, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: cuna del vallenato y festival vallenato. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa romántica en Los Mayales' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'En Río Guatapurí, Valledupar, te espera un apartamento rústico con todo lo necesario para una estadía tranquila.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: patio con hamacas y festival vallenato. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento rústico en Río Guatapurí' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Descubre Valledupar desde una finca familiar en Novalito, ideal para descansar después de un día de paseo.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 12 personas.

Lo mejor del entorno: baños en el río Guatapurí y cuna del vallenato. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca familiar en Novalito' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'En Río Guatapurí, Valledupar, te espera una casa acogedora con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: patio con hamacas y baños en el río Guatapurí. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa acogedora en Río Guatapurí' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Descubre Valledupar desde un apartamento fresco en Centro, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: baños en el río Guatapurí y cuna del vallenato. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento fresco en Centro' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Esta finca sencilla en Centro es el punto de partida perfecto para conocer Valledupar y lo mejor de Cesar.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 8 personas.

Lo mejor del entorno: baños en el río Guatapurí y cuna del vallenato. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca sencilla en Centro' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Descubre Valledupar desde una casa luminosa en Novalito, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: cuna del vallenato y patio con hamacas. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa luminosa en Novalito' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Este apartamento tranquilo está ubicado en Río Guatapurí, uno de los sectores más agradables de Valledupar, Cesar.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: patio con hamacas y baños en el río Guatapurí. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tranquilo en Río Guatapurí' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Esta finca elegante en Centro es el punto de partida perfecto para conocer Valledupar y lo mejor de Cesar.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: cuna del vallenato y patio con hamacas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca elegante en Centro' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Esta casa sencilla en Novalito es el punto de partida perfecto para conocer Valledupar y lo mejor de Cesar.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: baños en el río Guatapurí y patio con hamacas. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa sencilla en Novalito' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Descubre Valledupar desde un apartamento sencillo en Río Guatapurí, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: baños en el río Guatapurí y patio con hamacas. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento sencillo en Río Guatapurí' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Descubre Valledupar desde una finca elegante en Los Mayales, ideal para descansar después de un día de paseo.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: festival vallenato y patio con hamacas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca elegante en Los Mayales' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Descubre Valledupar desde una casa acogedora en Novalito, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: cuna del vallenato y patio con hamacas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa acogedora en Novalito' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Este apartamento fresco en Los Mayales es el punto de partida perfecto para conocer Valledupar y lo mejor de Cesar.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: baños en el río Guatapurí y festival vallenato. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento fresco en Los Mayales' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Esta finca rústica en Novalito es el punto de partida perfecto para conocer Valledupar y lo mejor de Cesar.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: cuna del vallenato y patio con hamacas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca rústica en Novalito' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'En Los Mayales, Valledupar, te espera una casa acogedora con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: patio con hamacas y baños en el río Guatapurí. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa acogedora en Los Mayales' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Este apartamento tradicional en Los Mayales es el punto de partida perfecto para conocer Valledupar y lo mejor de Cesar.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: patio con hamacas y cuna del vallenato. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tradicional en Los Mayales' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Descubre Valledupar desde una finca moderna en Río Guatapurí, ideal para descansar después de un día de paseo.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: cuna del vallenato y baños en el río Guatapurí. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca moderna en Río Guatapurí' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'En Centro, Valledupar, te espera una casa romántica con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: cuna del vallenato y baños en el río Guatapurí. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa romántica en Centro' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'En Novalito, Valledupar, te espera un apartamento romántico con todo lo necesario para una estadía tranquila.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: festival vallenato y cuna del vallenato. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento romántico en Novalito' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Esta finca encantadora está ubicada en Río Guatapurí, uno de los sectores más agradables de Valledupar, Cesar.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 14 personas.

Lo mejor del entorno: baños en el río Guatapurí y patio con hamacas. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca encantadora en Río Guatapurí' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'En Centro, Valledupar, te espera una casa luminosa con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: festival vallenato y cuna del vallenato. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa luminosa en Centro' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Este apartamento familiar está ubicado en Río Guatapurí, uno de los sectores más agradables de Valledupar, Cesar.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: festival vallenato y cuna del vallenato. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento familiar en Río Guatapurí' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'En Los Mayales, Valledupar, te espera una finca moderna con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: patio con hamacas y baños en el río Guatapurí. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca moderna en Los Mayales' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Esta casa familiar en Los Mayales es el punto de partida perfecto para conocer Valledupar y lo mejor de Cesar.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: cuna del vallenato y baños en el río Guatapurí. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa familiar en Los Mayales' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Este apartamento colorido en Los Mayales es el punto de partida perfecto para conocer Valledupar y lo mejor de Cesar.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: baños en el río Guatapurí y festival vallenato. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento colorido en Los Mayales' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Esta finca encantadora está ubicada en Los Mayales, uno de los sectores más agradables de Valledupar, Cesar.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 12 personas.

Lo mejor del entorno: festival vallenato y baños en el río Guatapurí. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca encantadora en Los Mayales' AND ciudad = 'Valledupar';
UPDATE publicacion SET descripcion = 'Esta casa romántica en Camino Real a Guane es el punto de partida perfecto para conocer Barichara y lo mejor de Santander.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: camino real a Guane y arquitectura en tapia. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa romántica en Camino Real a Guane' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'En Parque para las Artes, Barichara, te espera una habitación romántica con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: calles empedradas y arquitectura en tapia. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación romántica en Parque para las Artes' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'En Camino Real a Guane, Barichara, te espera una cabaña exclusiva con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: vista al cañón y calles empedradas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña exclusiva en Camino Real a Guane' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Este glamping romántico está ubicado en Mirador, uno de los sectores más agradables de Barichara, Santander.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: arquitectura en tapia y calles empedradas. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping romántico en Mirador' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Esta casa rústica está ubicada en Mirador, uno de los sectores más agradables de Barichara, Santander.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: calles empedradas y camino real a Guane. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa rústica en Mirador' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Descubre Barichara desde una habitación luminosa en Parque para las Artes, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: camino real a Guane y arquitectura en tapia. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Parque para las Artes' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Esta cabaña encantadora está ubicada en Mirador, uno de los sectores más agradables de Barichara, Santander.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: vista al cañón y camino real a Guane. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña encantadora en Mirador' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'En Parque para las Artes, Barichara, te espera un glamping tradicional con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: camino real a Guane y arquitectura en tapia. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping tradicional en Parque para las Artes' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'En Camino Real a Guane, Barichara, te espera una casa tranquila con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: arquitectura en tapia y camino real a Guane. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa tranquila en Camino Real a Guane' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Esta habitación sencilla está ubicada en Parque para las Artes, uno de los sectores más agradables de Barichara, Santander.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: camino real a Guane y calles empedradas. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación sencilla en Parque para las Artes' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'En Mirador, Barichara, te espera una cabaña tranquila con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: vista al cañón y calles empedradas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña tranquila en Mirador' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Descubre Barichara desde un glamping familiar en Camino Real a Guane, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: vista al cañón y arquitectura en tapia. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping familiar en Camino Real a Guane' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Esta casa tradicional en Mirador es el punto de partida perfecto para conocer Barichara y lo mejor de Santander.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: calles empedradas y vista al cañón. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa tradicional en Mirador' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'En Centro Histórico, Barichara, te espera una habitación espaciosa con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: vista al cañón y camino real a Guane. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación espaciosa en Centro Histórico' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Descubre Barichara desde una cabaña acogedora en Mirador, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: vista al cañón y calles empedradas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña acogedora en Mirador' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Este glamping tradicional en Mirador es el punto de partida perfecto para conocer Barichara y lo mejor de Santander.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: camino real a Guane y vista al cañón. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping tradicional en Mirador' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'En Parque para las Artes, Barichara, te espera una casa sencilla con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: vista al cañón y camino real a Guane. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa sencilla en Parque para las Artes' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Esta habitación acogedora está ubicada en Parque para las Artes, uno de los sectores más agradables de Barichara, Santander.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: vista al cañón y arquitectura en tapia. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación acogedora en Parque para las Artes' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Esta cabaña romántica está ubicada en Parque para las Artes, uno de los sectores más agradables de Barichara, Santander.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: camino real a Guane y arquitectura en tapia. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña romántica en Parque para las Artes' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Descubre Barichara desde un glamping colorido en Camino Real a Guane, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: calles empedradas y camino real a Guane. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping colorido en Camino Real a Guane' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Esta casa elegante en Parque para las Artes es el punto de partida perfecto para conocer Barichara y lo mejor de Santander.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: vista al cañón y arquitectura en tapia. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa elegante en Parque para las Artes' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Esta habitación encantadora está ubicada en Camino Real a Guane, uno de los sectores más agradables de Barichara, Santander.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: vista al cañón y calles empedradas. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación encantadora en Camino Real a Guane' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Esta cabaña fresca está ubicada en Mirador, uno de los sectores más agradables de Barichara, Santander.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: vista al cañón y calles empedradas. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña fresca en Mirador' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Este glamping espacioso está ubicado en Camino Real a Guane, uno de los sectores más agradables de Barichara, Santander.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: arquitectura en tapia y vista al cañón. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping espacioso en Camino Real a Guane' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'En Mirador, Barichara, te espera una casa luminosa con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: camino real a Guane y calles empedradas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa luminosa en Mirador' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Esta habitación sencilla está ubicada en Centro Histórico, uno de los sectores más agradables de Barichara, Santander.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: camino real a Guane y arquitectura en tapia. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación sencilla en Centro Histórico' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Descubre Barichara desde una cabaña rústica en Parque para las Artes, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: arquitectura en tapia y vista al cañón. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña rústica en Parque para las Artes' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Este glamping exclusivo está ubicado en Parque para las Artes, uno de los sectores más agradables de Barichara, Santander.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: calles empedradas y arquitectura en tapia. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping exclusivo en Parque para las Artes' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'En Centro Histórico, Barichara, te espera una casa elegante con todo lo necesario para una estadía tranquila.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: camino real a Guane y calles empedradas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa elegante en Centro Histórico' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Esta habitación tranquila está ubicada en Mirador, uno de los sectores más agradables de Barichara, Santander.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: calles empedradas y arquitectura en tapia. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tranquila en Mirador' AND ciudad = 'Barichara';
UPDATE publicacion SET descripcion = 'Este apartamento rústico está ubicado en Caobos, uno de los sectores más agradables de Cúcuta, Norte de Santander.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: aire acondicionado y zona comercial. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento rústico en Caobos' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'En Centro, Cúcuta, te espera una casa tranquila con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: aire acondicionado y zona comercial. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa tranquila en Centro' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Esta habitación rústica en Quinta Oriental es el punto de partida perfecto para conocer Cúcuta y lo mejor de Norte de Santander.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: aire acondicionado y cerca a la frontera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación rústica en Quinta Oriental' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Descubre Cúcuta desde un apartamento acogedor en Quinta Oriental, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca a la frontera y aire acondicionado. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento acogedor en Quinta Oriental' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Esta casa sencilla está ubicada en Caobos, uno de los sectores más agradables de Cúcuta, Norte de Santander.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y cerca a la frontera. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa sencilla en Caobos' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Descubre Cúcuta desde una habitación colorida en Centro, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: aire acondicionado y piscina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación colorida en Centro' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Descubre Cúcuta desde un apartamento encantador en Caobos, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona comercial y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento encantador en Caobos' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'En Quinta Oriental, Cúcuta, te espera una casa espaciosa con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: cerca a la frontera y piscina. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa espaciosa en Quinta Oriental' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Esta habitación elegante está ubicada en Caobos, uno de los sectores más agradables de Cúcuta, Norte de Santander.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: aire acondicionado y zona comercial. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación elegante en Caobos' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Descubre Cúcuta desde un apartamento exclusivo en Caobos, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: aire acondicionado y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento exclusivo en Caobos' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'En Caobos, Cúcuta, te espera una casa espaciosa con todo lo necesario para una estadía tranquila.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: cerca a la frontera y aire acondicionado. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa espaciosa en Caobos' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'En Quinta Oriental, Cúcuta, te espera una habitación colorida con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: piscina y cerca a la frontera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación colorida en Quinta Oriental' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Descubre Cúcuta desde un apartamento fresco en Quinta Oriental, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca a la frontera y aire acondicionado. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento fresco en Quinta Oriental' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'En Centro, Cúcuta, te espera una casa tradicional con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y cerca a la frontera. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa tradicional en Centro' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Esta habitación tradicional en Los Patios es el punto de partida perfecto para conocer Cúcuta y lo mejor de Norte de Santander.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: aire acondicionado y zona comercial. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tradicional en Los Patios' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Descubre Cúcuta desde un apartamento exclusivo en Quinta Oriental, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona comercial y aire acondicionado. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento exclusivo en Quinta Oriental' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'En Los Patios, Cúcuta, te espera una casa elegante con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: cerca a la frontera y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa elegante en Los Patios' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'En Caobos, Cúcuta, te espera una habitación acogedora con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cerca a la frontera y zona comercial. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación acogedora en Caobos' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'En Los Patios, Cúcuta, te espera un apartamento romántico con todo lo necesario para una estadía tranquila.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona comercial y piscina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento romántico en Los Patios' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva está ubicada en Los Patios, uno de los sectores más agradables de Cúcuta, Norte de Santander.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: zona comercial y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa exclusiva en Los Patios' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Esta habitación elegante está ubicada en Centro, uno de los sectores más agradables de Cúcuta, Norte de Santander.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: zona comercial y piscina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación elegante en Centro' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Descubre Cúcuta desde un apartamento familiar en Centro, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca a la frontera y aire acondicionado. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento familiar en Centro' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Esta casa espaciosa en Centro es el punto de partida perfecto para conocer Cúcuta y lo mejor de Norte de Santander.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: cerca a la frontera y piscina. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa espaciosa en Centro' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Descubre Cúcuta desde una habitación acogedora en Los Patios, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: zona comercial y piscina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación acogedora en Los Patios' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Este apartamento moderno está ubicado en Centro, uno de los sectores más agradables de Cúcuta, Norte de Santander.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona comercial y aire acondicionado. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento moderno en Centro' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Esta casa acogedora en Centro es el punto de partida perfecto para conocer Cúcuta y lo mejor de Norte de Santander.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y cerca a la frontera. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa acogedora en Centro' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Esta habitación exclusiva en Centro es el punto de partida perfecto para conocer Cúcuta y lo mejor de Norte de Santander.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: piscina y zona comercial. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación exclusiva en Centro' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Este apartamento tradicional en Los Patios es el punto de partida perfecto para conocer Cúcuta y lo mejor de Norte de Santander.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca a la frontera y aire acondicionado. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tradicional en Los Patios' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'En Caobos, Cúcuta, te espera una casa tradicional con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: zona comercial y piscina. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa tradicional en Caobos' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'Descubre Cúcuta desde una habitación colorida en Caobos, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: zona comercial y cerca a la frontera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación colorida en Caobos' AND ciudad = 'Cúcuta';
UPDATE publicacion SET descripcion = 'En Plaza Mayor, Villa de Leyva, te espera una casa tranquila con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: cielos estrellados y desierto de la Candelaria. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa tranquila en Plaza Mayor' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Descubre Villa de Leyva desde una cabaña exclusiva en Vía a Ráquira, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: plaza colonial y chimenea. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña exclusiva en Vía a Ráquira' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Descubre Villa de Leyva desde un glamping familiar en Sutamarchán, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: desierto de la Candelaria y chimenea. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping familiar en Sutamarchán' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Esta finca tradicional en Sutamarchán es el punto de partida perfecto para conocer Villa de Leyva y lo mejor de Boyacá.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: plaza colonial y desierto de la Candelaria. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca tradicional en Sutamarchán' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'En Pozos Azules, Villa de Leyva, te espera una habitación exclusiva con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: chimenea y desierto de la Candelaria. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación exclusiva en Pozos Azules' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Descubre Villa de Leyva desde una casa tradicional en Pozos Azules, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: chimenea y cielos estrellados. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa tradicional en Pozos Azules' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Esta cabaña espaciosa está ubicada en Sutamarchán, uno de los sectores más agradables de Villa de Leyva, Boyacá.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: plaza colonial y chimenea. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña espaciosa en Sutamarchán' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Este glamping familiar está ubicado en Vía a Ráquira, uno de los sectores más agradables de Villa de Leyva, Boyacá.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: cielos estrellados y desierto de la Candelaria. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping familiar en Vía a Ráquira' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'En Vía a Ráquira, Villa de Leyva, te espera una finca acogedora con todo lo necesario para una estadía tranquila.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 11 personas.

Lo mejor del entorno: plaza colonial y cielos estrellados. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca acogedora en Vía a Ráquira' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Esta habitación colorida en Sutamarchán es el punto de partida perfecto para conocer Villa de Leyva y lo mejor de Boyacá.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: chimenea y desierto de la Candelaria. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación colorida en Sutamarchán' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva está ubicada en Sutamarchán, uno de los sectores más agradables de Villa de Leyva, Boyacá.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: cielos estrellados y desierto de la Candelaria. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa exclusiva en Sutamarchán' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Esta cabaña romántica está ubicada en Vía a Ráquira, uno de los sectores más agradables de Villa de Leyva, Boyacá.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: plaza colonial y chimenea. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña romántica en Vía a Ráquira' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Este glamping rústico en Vía a Ráquira es el punto de partida perfecto para conocer Villa de Leyva y lo mejor de Boyacá.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: desierto de la Candelaria y plaza colonial. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping rústico en Vía a Ráquira' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'En Vereda Monquirá, Villa de Leyva, te espera una finca luminosa con todo lo necesario para una estadía tranquila.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: desierto de la Candelaria y chimenea. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca luminosa en Vereda Monquirá' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Descubre Villa de Leyva desde una habitación elegante en Vereda Monquirá, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: chimenea y desierto de la Candelaria. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación elegante en Vereda Monquirá' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'En Vereda Monquirá, Villa de Leyva, te espera una casa exclusiva con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: chimenea y desierto de la Candelaria. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa exclusiva en Vereda Monquirá' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Esta cabaña familiar está ubicada en Vía a Ráquira, uno de los sectores más agradables de Villa de Leyva, Boyacá.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: chimenea y desierto de la Candelaria. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña familiar en Vía a Ráquira' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Este glamping sencillo en Vereda Monquirá es el punto de partida perfecto para conocer Villa de Leyva y lo mejor de Boyacá.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: chimenea y plaza colonial. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping sencillo en Vereda Monquirá' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Descubre Villa de Leyva desde una finca rústica en Pozos Azules, ideal para descansar después de un día de paseo.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 11 personas.

Lo mejor del entorno: chimenea y desierto de la Candelaria. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca rústica en Pozos Azules' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Descubre Villa de Leyva desde una habitación familiar en Plaza Mayor, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: chimenea y cielos estrellados. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Plaza Mayor' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Esta casa encantadora en Vereda Monquirá es el punto de partida perfecto para conocer Villa de Leyva y lo mejor de Boyacá.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: chimenea y desierto de la Candelaria. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa encantadora en Vereda Monquirá' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Esta cabaña familiar está ubicada en Vereda Monquirá, uno de los sectores más agradables de Villa de Leyva, Boyacá.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: desierto de la Candelaria y cielos estrellados. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña familiar en Vereda Monquirá' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'En Vereda Monquirá, Villa de Leyva, te espera un glamping acogedor con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: plaza colonial y chimenea. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping acogedor en Vereda Monquirá' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'En Plaza Mayor, Villa de Leyva, te espera una finca tradicional con todo lo necesario para una estadía tranquila.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: chimenea y cielos estrellados. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca tradicional en Plaza Mayor' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'En Pozos Azules, Villa de Leyva, te espera una habitación fresca con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: desierto de la Candelaria y plaza colonial. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación fresca en Pozos Azules' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'En Plaza Mayor, Villa de Leyva, te espera una casa sencilla con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: desierto de la Candelaria y chimenea. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa sencilla en Plaza Mayor' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Descubre Villa de Leyva desde una cabaña romántica en Vereda Monquirá, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: chimenea y desierto de la Candelaria. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña romántica en Vereda Monquirá' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Este glamping elegante está ubicado en Pozos Azules, uno de los sectores más agradables de Villa de Leyva, Boyacá.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: cielos estrellados y plaza colonial. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping elegante en Pozos Azules' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'En Vía a Ráquira, Villa de Leyva, te espera una finca sencilla con todo lo necesario para una estadía tranquila.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 7 personas.

Lo mejor del entorno: chimenea y desierto de la Candelaria. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca sencilla en Vía a Ráquira' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Descubre Villa de Leyva desde una habitación tranquila en Vereda Monquirá, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: plaza colonial y desierto de la Candelaria. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tranquila en Vereda Monquirá' AND ciudad = 'Villa de Leyva';
UPDATE publicacion SET descripcion = 'Descubre Guatavita desde una cabaña espaciosa en Pueblo, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: vista al embalse de Tominé y deportes náuticos. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña espaciosa en Pueblo' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta finca acogedora está ubicada en Vereda Monquentiva, uno de los sectores más agradables de Guatavita, Cundinamarca.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: vista al embalse de Tominé y deportes náuticos. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca acogedora en Vereda Monquentiva' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'En Laguna de Guatavita, Guatavita, te espera un glamping encantador con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: chimenea y deportes náuticos. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping encantador en Laguna de Guatavita' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta casa sencilla en Laguna de Guatavita es el punto de partida perfecto para conocer Guatavita y lo mejor de Cundinamarca.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: vista al embalse de Tominé y chimenea. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa sencilla en Laguna de Guatavita' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta cabaña acogedora está ubicada en Pueblo, uno de los sectores más agradables de Guatavita, Cundinamarca.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: deportes náuticos y vista al embalse de Tominé. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña acogedora en Pueblo' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta finca rústica en Embalse de Tominé es el punto de partida perfecto para conocer Guatavita y lo mejor de Cundinamarca.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: leyenda de El Dorado y vista al embalse de Tominé. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca rústica en Embalse de Tominé' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'En Pueblo, Guatavita, te espera un glamping elegante con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: vista al embalse de Tominé y deportes náuticos. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping elegante en Pueblo' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Descubre Guatavita desde una casa encantadora en Pueblo, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: deportes náuticos y chimenea. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa encantadora en Pueblo' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Descubre Guatavita desde una cabaña fresca en Pueblo, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: leyenda de El Dorado y vista al embalse de Tominé. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña fresca en Pueblo' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta finca espaciosa está ubicada en Laguna de Guatavita, uno de los sectores más agradables de Guatavita, Cundinamarca.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: vista al embalse de Tominé y deportes náuticos. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca espaciosa en Laguna de Guatavita' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Este glamping colorido está ubicado en Embalse de Tominé, uno de los sectores más agradables de Guatavita, Cundinamarca.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: deportes náuticos y chimenea. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping colorido en Embalse de Tominé' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'En Pueblo, Guatavita, te espera una casa romántica con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: deportes náuticos y vista al embalse de Tominé. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa romántica en Pueblo' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta cabaña elegante está ubicada en Vereda Monquentiva, uno de los sectores más agradables de Guatavita, Cundinamarca.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: chimenea y deportes náuticos. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña elegante en Vereda Monquentiva' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Descubre Guatavita desde una finca tranquila en Embalse de Tominé, ideal para descansar después de un día de paseo.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: vista al embalse de Tominé y chimenea. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca tranquila en Embalse de Tominé' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Este glamping rústico en Pueblo es el punto de partida perfecto para conocer Guatavita y lo mejor de Cundinamarca.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: deportes náuticos y leyenda de El Dorado. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping rústico en Pueblo' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta casa elegante está ubicada en Pueblo, uno de los sectores más agradables de Guatavita, Cundinamarca.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: leyenda de El Dorado y deportes náuticos. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa elegante en Pueblo' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta cabaña elegante en Embalse de Tominé es el punto de partida perfecto para conocer Guatavita y lo mejor de Cundinamarca.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: leyenda de El Dorado y chimenea. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña elegante en Embalse de Tominé' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta finca tranquila está ubicada en Laguna de Guatavita, uno de los sectores más agradables de Guatavita, Cundinamarca.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: vista al embalse de Tominé y leyenda de El Dorado. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca tranquila en Laguna de Guatavita' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'En Vereda Monquentiva, Guatavita, te espera un glamping sencillo con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: chimenea y leyenda de El Dorado. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping sencillo en Vereda Monquentiva' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'En Laguna de Guatavita, Guatavita, te espera una casa espaciosa con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: vista al embalse de Tominé y leyenda de El Dorado. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa espaciosa en Laguna de Guatavita' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Descubre Guatavita desde una cabaña familiar en Laguna de Guatavita, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: deportes náuticos y vista al embalse de Tominé. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña familiar en Laguna de Guatavita' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta finca familiar está ubicada en Laguna de Guatavita, uno de los sectores más agradables de Guatavita, Cundinamarca.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: leyenda de El Dorado y chimenea. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca familiar en Laguna de Guatavita' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Descubre Guatavita desde un glamping exclusivo en Vereda Monquentiva, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: deportes náuticos y leyenda de El Dorado. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping exclusivo en Vereda Monquentiva' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta casa tradicional en Vereda Monquentiva es el punto de partida perfecto para conocer Guatavita y lo mejor de Cundinamarca.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: vista al embalse de Tominé y chimenea. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa tradicional en Vereda Monquentiva' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'En Pueblo, Guatavita, te espera una cabaña colorida con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: leyenda de El Dorado y chimenea. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña colorida en Pueblo' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta finca moderna en Embalse de Tominé es el punto de partida perfecto para conocer Guatavita y lo mejor de Cundinamarca.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: vista al embalse de Tominé y chimenea. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca moderna en Embalse de Tominé' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Descubre Guatavita desde un glamping encantador en Vereda Monquentiva, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: deportes náuticos y chimenea. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping encantador en Vereda Monquentiva' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'En Laguna de Guatavita, Guatavita, te espera una casa tranquila con todo lo necesario para una estadía tranquila.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: chimenea y deportes náuticos. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa tranquila en Laguna de Guatavita' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Descubre Guatavita desde una cabaña tradicional en Laguna de Guatavita, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: deportes náuticos y chimenea. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña tradicional en Laguna de Guatavita' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Esta finca colorida está ubicada en Laguna de Guatavita, uno de los sectores más agradables de Guatavita, Cundinamarca.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 11 personas.

Lo mejor del entorno: leyenda de El Dorado y vista al embalse de Tominé. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca colorida en Laguna de Guatavita' AND ciudad = 'Guatavita';
UPDATE publicacion SET descripcion = 'Este apartamento tradicional en Zona G es el punto de partida perfecto para conocer Bogotá y lo mejor de Bogotá D.C..

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona gastronómica y cerca a museos. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento tradicional en Zona G' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Descubre Bogotá desde una habitación tranquila en Usaquén, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: transporte cercano y zona gastronómica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tranquila en Usaquén' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta casa acogedora está ubicada en Teusaquillo, uno de los sectores más agradables de Bogotá, Bogotá D.C..

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: zona gastronómica y vista a Monserrate. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa acogedora en Teusaquillo' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Descubre Bogotá desde un apartamento sencillo en Usaquén, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: vista a Monserrate y zona gastronómica. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento sencillo en Usaquén' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta habitación sencilla está ubicada en Parque 93, uno de los sectores más agradables de Bogotá, Bogotá D.C..

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: zona gastronómica y cerca a museos. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación sencilla en Parque 93' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta casa sencilla está ubicada en Zona G, uno de los sectores más agradables de Bogotá, Bogotá D.C..

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: zona gastronómica y cerca a museos. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa sencilla en Zona G' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Descubre Bogotá desde un apartamento tradicional en Usaquén, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona gastronómica y transporte cercano. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tradicional en Usaquén' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'En Chapinero, Bogotá, te espera una habitación moderna con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: zona gastronómica y cerca a museos. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Chapinero' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta casa encantadora en Chapinero es el punto de partida perfecto para conocer Bogotá y lo mejor de Bogotá D.C..

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: cerca a museos y zona gastronómica. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa encantadora en Chapinero' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Este apartamento sencillo en Chapinero es el punto de partida perfecto para conocer Bogotá y lo mejor de Bogotá D.C..

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca a museos y vista a Monserrate. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento sencillo en Chapinero' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta habitación elegante está ubicada en Chapinero, uno de los sectores más agradables de Bogotá, Bogotá D.C..

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: transporte cercano y zona gastronómica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación elegante en Chapinero' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta casa luminosa está ubicada en La Candelaria, uno de los sectores más agradables de Bogotá, Bogotá D.C..

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: vista a Monserrate y transporte cercano. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa luminosa en La Candelaria' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Descubre Bogotá desde un apartamento encantador en Teusaquillo, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: transporte cercano y zona gastronómica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento encantador en Teusaquillo' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta habitación acogedora en Teusaquillo es el punto de partida perfecto para conocer Bogotá y lo mejor de Bogotá D.C..

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cerca a museos y zona gastronómica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación acogedora en Teusaquillo' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta casa familiar está ubicada en La Candelaria, uno de los sectores más agradables de Bogotá, Bogotá D.C..

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: zona gastronómica y vista a Monserrate. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa familiar en La Candelaria' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Este apartamento colorido en Chapinero es el punto de partida perfecto para conocer Bogotá y lo mejor de Bogotá D.C..

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: transporte cercano y cerca a museos. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento colorido en Chapinero' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta habitación tranquila está ubicada en La Candelaria, uno de los sectores más agradables de Bogotá, Bogotá D.C..

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: transporte cercano y zona gastronómica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tranquila en La Candelaria' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta casa espaciosa está ubicada en La Candelaria, uno de los sectores más agradables de Bogotá, Bogotá D.C..

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: transporte cercano y vista a Monserrate. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa espaciosa en La Candelaria' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Este apartamento sencillo está ubicado en Zona G, uno de los sectores más agradables de Bogotá, Bogotá D.C..

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: transporte cercano y vista a Monserrate. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento sencillo en Zona G' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta habitación encantadora en Chapinero es el punto de partida perfecto para conocer Bogotá y lo mejor de Bogotá D.C..

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: vista a Monserrate y transporte cercano. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación encantadora en Chapinero' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta casa sencilla está ubicada en Usaquén, uno de los sectores más agradables de Bogotá, Bogotá D.C..

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: cerca a museos y vista a Monserrate. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa sencilla en Usaquén' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'En La Candelaria, Bogotá, te espera un apartamento moderno con todo lo necesario para una estadía tranquila.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona gastronómica y transporte cercano. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento moderno en La Candelaria' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Descubre Bogotá desde una habitación familiar en Teusaquillo, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cerca a museos y vista a Monserrate. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Teusaquillo' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Descubre Bogotá desde una casa tranquila en Teusaquillo, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: zona gastronómica y transporte cercano. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa tranquila en Teusaquillo' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Descubre Bogotá desde un apartamento luminoso en Zona G, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca a museos y vista a Monserrate. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento luminoso en Zona G' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta habitación familiar en Parque 93 es el punto de partida perfecto para conocer Bogotá y lo mejor de Bogotá D.C..

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: zona gastronómica y vista a Monserrate. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Parque 93' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta casa moderna en Parque 93 es el punto de partida perfecto para conocer Bogotá y lo mejor de Bogotá D.C..

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: cerca a museos y vista a Monserrate. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa moderna en Parque 93' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Este apartamento colorido está ubicado en Parque 93, uno de los sectores más agradables de Bogotá, Bogotá D.C..

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona gastronómica y transporte cercano. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento colorido en Parque 93' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Esta habitación fresca en La Candelaria es el punto de partida perfecto para conocer Bogotá y lo mejor de Bogotá D.C..

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cerca a museos y vista a Monserrate. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación fresca en La Candelaria' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'En Zona G, Bogotá, te espera una casa rústica con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: zona gastronómica y cerca a museos. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa rústica en Zona G' AND ciudad = 'Bogotá';
UPDATE publicacion SET descripcion = 'Este apartamento romántico está ubicado en Provenza, uno de los sectores más agradables de Medellín, Antioquia.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: clima de eterna primavera y vida nocturna. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento romántico en Provenza' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Descubre Medellín desde una habitación tradicional en Laureles, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: vida nocturna y clima de eterna primavera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tradicional en Laureles' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Descubre Medellín desde una casa fresca en Envigado, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: balcón con vista y clima de eterna primavera. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa fresca en Envigado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'En Envigado, Medellín, te espera un apartamento familiar con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca al metro y clima de eterna primavera. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento familiar en Envigado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'En Provenza, Medellín, te espera una habitación exclusiva con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: balcón con vista y clima de eterna primavera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación exclusiva en Provenza' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'En Provenza, Medellín, te espera una casa sencilla con todo lo necesario para una estadía tranquila.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: vida nocturna y clima de eterna primavera. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa sencilla en Provenza' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Descubre Medellín desde un apartamento exclusivo en Laureles, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: vida nocturna y balcón con vista. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento exclusivo en Laureles' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Esta habitación familiar está ubicada en Envigado, uno de los sectores más agradables de Medellín, Antioquia.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: balcón con vista y vida nocturna. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Envigado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Esta casa espaciosa está ubicada en Belén, uno de los sectores más agradables de Medellín, Antioquia.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: balcón con vista y clima de eterna primavera. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa espaciosa en Belén' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Este apartamento romántico en Envigado es el punto de partida perfecto para conocer Medellín y lo mejor de Antioquia.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: vida nocturna y cerca al metro. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento romántico en Envigado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'En Envigado, Medellín, te espera una habitación colorida con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: clima de eterna primavera y vida nocturna. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación colorida en Envigado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Esta casa sencilla está ubicada en Laureles, uno de los sectores más agradables de Medellín, Antioquia.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: cerca al metro y clima de eterna primavera. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa sencilla en Laureles' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Descubre Medellín desde un apartamento acogedor en Belén, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca al metro y vida nocturna. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento acogedor en Belén' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Esta habitación elegante en Belén es el punto de partida perfecto para conocer Medellín y lo mejor de Antioquia.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cerca al metro y balcón con vista. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación elegante en Belén' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'En Envigado, Medellín, te espera una casa romántica con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: vida nocturna y clima de eterna primavera. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa romántica en Envigado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Este apartamento moderno en Belén es el punto de partida perfecto para conocer Medellín y lo mejor de Antioquia.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca al metro y clima de eterna primavera. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento moderno en Belén' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Esta habitación espaciosa en Belén es el punto de partida perfecto para conocer Medellín y lo mejor de Antioquia.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: clima de eterna primavera y cerca al metro. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación espaciosa en Belén' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Esta casa tranquila está ubicada en Laureles, uno de los sectores más agradables de Medellín, Antioquia.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: balcón con vista y cerca al metro. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa tranquila en Laureles' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Descubre Medellín desde un apartamento colorido en Envigado, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: balcón con vista y vida nocturna. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento colorido en Envigado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'En Envigado, Medellín, te espera una habitación espaciosa con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: balcón con vista y clima de eterna primavera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación espaciosa en Envigado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Esta casa rústica en Envigado es el punto de partida perfecto para conocer Medellín y lo mejor de Antioquia.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: balcón con vista y cerca al metro. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa rústica en Envigado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Este apartamento sencillo está ubicado en Laureles, uno de los sectores más agradables de Medellín, Antioquia.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: clima de eterna primavera y balcón con vista. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento sencillo en Laureles' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'En Envigado, Medellín, te espera una habitación luminosa con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: balcón con vista y cerca al metro. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Envigado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Esta casa elegante está ubicada en Belén, uno de los sectores más agradables de Medellín, Antioquia.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: balcón con vista y vida nocturna. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa elegante en Belén' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Este apartamento tranquilo en Laureles es el punto de partida perfecto para conocer Medellín y lo mejor de Antioquia.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: clima de eterna primavera y vida nocturna. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento tranquilo en Laureles' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'En Laureles, Medellín, te espera una habitación romántica con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cerca al metro y clima de eterna primavera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación romántica en Laureles' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Descubre Medellín desde una casa colorida en Envigado, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: vida nocturna y balcón con vista. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa colorida en Envigado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Descubre Medellín desde un apartamento elegante en Envigado, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: clima de eterna primavera y vida nocturna. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento elegante en Envigado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Esta habitación fresca está ubicada en El Poblado, uno de los sectores más agradables de Medellín, Antioquia.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: cerca al metro y vida nocturna. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación fresca en El Poblado' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva está ubicada en Provenza, uno de los sectores más agradables de Medellín, Antioquia.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: cerca al metro y clima de eterna primavera. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa exclusiva en Provenza' AND ciudad = 'Medellín';
UPDATE publicacion SET descripcion = 'Descubre Guatapé desde una cabaña acogedora en Zócalos, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: muelle privado y kayak. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña acogedora en Zócalos' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'En Vereda La Piedra, Guatapé, te espera una finca colorida con todo lo necesario para una estadía tranquila.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: vista al embalse y muelle privado. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca colorida en Vereda La Piedra' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'En Piedra del Peñol, Guatapé, te espera un glamping espacioso con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: zócalos de colores y muelle privado. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping espacioso en Piedra del Peñol' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Descubre Guatapé desde una casa exclusiva en Malecón, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: vista al embalse y zócalos de colores. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa exclusiva en Malecón' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'En Embalse, Guatapé, te espera una cabaña romántica con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: zócalos de colores y kayak. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña romántica en Embalse' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta finca exclusiva está ubicada en Zócalos, uno de los sectores más agradables de Guatapé, Antioquia.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 14 personas.

Lo mejor del entorno: zócalos de colores y muelle privado. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca exclusiva en Zócalos' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'En Malecón, Guatapé, te espera un glamping romántico con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: kayak y muelle privado. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping romántico en Malecón' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Descubre Guatapé desde una casa acogedora en Zócalos, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: zócalos de colores y vista al embalse. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa acogedora en Zócalos' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta cabaña encantadora en Embalse es el punto de partida perfecto para conocer Guatapé y lo mejor de Antioquia.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: kayak y muelle privado. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña encantadora en Embalse' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta finca encantadora en Embalse es el punto de partida perfecto para conocer Guatapé y lo mejor de Antioquia.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 6 personas.

Lo mejor del entorno: vista al embalse y zócalos de colores. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca encantadora en Embalse' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Este glamping acogedor en Malecón es el punto de partida perfecto para conocer Guatapé y lo mejor de Antioquia.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: muelle privado y kayak. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping acogedor en Malecón' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta casa moderna está ubicada en Piedra del Peñol, uno de los sectores más agradables de Guatapé, Antioquia.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: zócalos de colores y vista al embalse. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa moderna en Piedra del Peñol' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Descubre Guatapé desde una cabaña moderna en Zócalos, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: zócalos de colores y muelle privado. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña moderna en Zócalos' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta finca romántica está ubicada en Vereda La Piedra, uno de los sectores más agradables de Guatapé, Antioquia.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 6 personas.

Lo mejor del entorno: kayak y muelle privado. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca romántica en Vereda La Piedra' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Este glamping encantador en Malecón es el punto de partida perfecto para conocer Guatapé y lo mejor de Antioquia.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: vista al embalse y kayak. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping encantador en Malecón' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta casa elegante en Malecón es el punto de partida perfecto para conocer Guatapé y lo mejor de Antioquia.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: zócalos de colores y muelle privado. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa elegante en Malecón' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta cabaña romántica en Vereda La Piedra es el punto de partida perfecto para conocer Guatapé y lo mejor de Antioquia.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: zócalos de colores y muelle privado. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña romántica en Vereda La Piedra' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'En Zócalos, Guatapé, te espera una finca espaciosa con todo lo necesario para una estadía tranquila.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: zócalos de colores y kayak. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca espaciosa en Zócalos' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Descubre Guatapé desde un glamping luminoso en Malecón, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: muelle privado y vista al embalse. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping luminoso en Malecón' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta casa espaciosa en Vereda La Piedra es el punto de partida perfecto para conocer Guatapé y lo mejor de Antioquia.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: muelle privado y zócalos de colores. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa espaciosa en Vereda La Piedra' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'En Piedra del Peñol, Guatapé, te espera una cabaña encantadora con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: kayak y muelle privado. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña encantadora en Piedra del Peñol' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta finca rústica en Vereda La Piedra es el punto de partida perfecto para conocer Guatapé y lo mejor de Antioquia.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 11 personas.

Lo mejor del entorno: muelle privado y zócalos de colores. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca rústica en Vereda La Piedra' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'En Embalse, Guatapé, te espera un glamping sencillo con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: zócalos de colores y kayak. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping sencillo en Embalse' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta casa fresca está ubicada en Malecón, uno de los sectores más agradables de Guatapé, Antioquia.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: zócalos de colores y kayak. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa fresca en Malecón' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'En Malecón, Guatapé, te espera una cabaña sencilla con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: zócalos de colores y muelle privado. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña sencilla en Malecón' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta finca exclusiva está ubicada en Vereda La Piedra, uno de los sectores más agradables de Guatapé, Antioquia.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 6 personas.

Lo mejor del entorno: muelle privado y zócalos de colores. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca exclusiva en Vereda La Piedra' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'En Zócalos, Guatapé, te espera un glamping sencillo con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: zócalos de colores y kayak. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping sencillo en Zócalos' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'En Malecón, Guatapé, te espera una casa rústica con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: kayak y vista al embalse. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa rústica en Malecón' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta cabaña elegante en Zócalos es el punto de partida perfecto para conocer Guatapé y lo mejor de Antioquia.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: kayak y muelle privado. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña elegante en Zócalos' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Esta finca fresca está ubicada en Piedra del Peñol, uno de los sectores más agradables de Guatapé, Antioquia.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 8 personas.

Lo mejor del entorno: kayak y muelle privado. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca fresca en Piedra del Peñol' AND ciudad = 'Guatapé';
UPDATE publicacion SET descripcion = 'Descubre Manizales desde un apartamento exclusivo en Termales, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: café de origen y vista al Nevado del Ruiz. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento exclusivo en Termales' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Esta casa familiar está ubicada en Termales, uno de los sectores más agradables de Manizales, Caldas.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: vista al Nevado del Ruiz y café de origen. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa familiar en Termales' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'En Cable, Manizales, te espera una finca moderna con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: termales cercanos y vista al Nevado del Ruiz. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca moderna en Cable' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'En Chipre, Manizales, te espera una cabaña fresca con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: atardeceres de Chipre y termales cercanos. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña fresca en Chipre' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'En Termales, Manizales, te espera un apartamento romántico con todo lo necesario para una estadía tranquila.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: termales cercanos y vista al Nevado del Ruiz. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento romántico en Termales' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva está ubicada en Recinto del Pensamiento, uno de los sectores más agradables de Manizales, Caldas.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: vista al Nevado del Ruiz y atardeceres de Chipre. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa exclusiva en Recinto del Pensamiento' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Esta finca acogedora en Cable es el punto de partida perfecto para conocer Manizales y lo mejor de Caldas.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: café de origen y vista al Nevado del Ruiz. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca acogedora en Cable' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Esta cabaña rústica en Recinto del Pensamiento es el punto de partida perfecto para conocer Manizales y lo mejor de Caldas.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: café de origen y termales cercanos. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña rústica en Recinto del Pensamiento' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Este apartamento tradicional está ubicado en Cable, uno de los sectores más agradables de Manizales, Caldas.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: atardeceres de Chipre y vista al Nevado del Ruiz. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento tradicional en Cable' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'En Cable, Manizales, te espera una casa moderna con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: atardeceres de Chipre y café de origen. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa moderna en Cable' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Esta finca elegante en Recinto del Pensamiento es el punto de partida perfecto para conocer Manizales y lo mejor de Caldas.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: atardeceres de Chipre y café de origen. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca elegante en Recinto del Pensamiento' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'En Recinto del Pensamiento, Manizales, te espera una cabaña acogedora con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: vista al Nevado del Ruiz y atardeceres de Chipre. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña acogedora en Recinto del Pensamiento' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Este apartamento espacioso está ubicado en Milán, uno de los sectores más agradables de Manizales, Caldas.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: vista al Nevado del Ruiz y termales cercanos. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento espacioso en Milán' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'En Termales, Manizales, te espera una casa moderna con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: termales cercanos y vista al Nevado del Ruiz. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa moderna en Termales' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Esta finca tranquila está ubicada en Cable, uno de los sectores más agradables de Manizales, Caldas.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: atardeceres de Chipre y termales cercanos. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca tranquila en Cable' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Esta cabaña encantadora está ubicada en Cable, uno de los sectores más agradables de Manizales, Caldas.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: termales cercanos y vista al Nevado del Ruiz. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña encantadora en Cable' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'En Termales, Manizales, te espera un apartamento espacioso con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: vista al Nevado del Ruiz y atardeceres de Chipre. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento espacioso en Termales' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Descubre Manizales desde una casa familiar en Milán, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: termales cercanos y atardeceres de Chipre. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa familiar en Milán' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Descubre Manizales desde una finca exclusiva en Termales, ideal para descansar después de un día de paseo.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: termales cercanos y atardeceres de Chipre. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca exclusiva en Termales' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'En Cable, Manizales, te espera una cabaña rústica con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: café de origen y vista al Nevado del Ruiz. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña rústica en Cable' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Este apartamento exclusivo en Chipre es el punto de partida perfecto para conocer Manizales y lo mejor de Caldas.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: café de origen y vista al Nevado del Ruiz. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento exclusivo en Chipre' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'En Recinto del Pensamiento, Manizales, te espera una casa encantadora con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: vista al Nevado del Ruiz y café de origen. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa encantadora en Recinto del Pensamiento' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Descubre Manizales desde una finca exclusiva en Chipre, ideal para descansar después de un día de paseo.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: café de origen y vista al Nevado del Ruiz. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca exclusiva en Chipre' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'En Chipre, Manizales, te espera una cabaña romántica con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: café de origen y vista al Nevado del Ruiz. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña romántica en Chipre' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Este apartamento moderno en Chipre es el punto de partida perfecto para conocer Manizales y lo mejor de Caldas.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: café de origen y vista al Nevado del Ruiz. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento moderno en Chipre' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Esta casa colorida está ubicada en Cable, uno de los sectores más agradables de Manizales, Caldas.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: café de origen y vista al Nevado del Ruiz. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa colorida en Cable' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Esta finca rústica en Cable es el punto de partida perfecto para conocer Manizales y lo mejor de Caldas.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: atardeceres de Chipre y termales cercanos. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca rústica en Cable' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Descubre Manizales desde una cabaña tradicional en Recinto del Pensamiento, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: café de origen y atardeceres de Chipre. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña tradicional en Recinto del Pensamiento' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Este apartamento fresco está ubicado en Recinto del Pensamiento, uno de los sectores más agradables de Manizales, Caldas.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: vista al Nevado del Ruiz y atardeceres de Chipre. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento fresco en Recinto del Pensamiento' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Esta casa fresca está ubicada en Recinto del Pensamiento, uno de los sectores más agradables de Manizales, Caldas.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: termales cercanos y café de origen. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa fresca en Recinto del Pensamiento' AND ciudad = 'Manizales';
UPDATE publicacion SET descripcion = 'Este apartamento rústico en Santa Rosa de Cabal es el punto de partida perfecto para conocer Pereira y lo mejor de Risaralda.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca al aeropuerto y fincas cafeteras. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento rústico en Santa Rosa de Cabal' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Esta finca colorida en Cerritos es el punto de partida perfecto para conocer Pereira y lo mejor de Risaralda.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 8 personas.

Lo mejor del entorno: fincas cafeteras y termales de Santa Rosa. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca colorida en Cerritos' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Descubre Pereira desde una casa encantadora en Circunvalar, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: termales de Santa Rosa y cerca al aeropuerto. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa encantadora en Circunvalar' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'En Pinares, Pereira, te espera una cabaña romántica con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: termales de Santa Rosa y fincas cafeteras. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña romántica en Pinares' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Este apartamento colorido en Circunvalar es el punto de partida perfecto para conocer Pereira y lo mejor de Risaralda.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: termales de Santa Rosa y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento colorido en Circunvalar' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Esta finca exclusiva está ubicada en Circunvalar, uno de los sectores más agradables de Pereira, Risaralda.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: cerca al aeropuerto y fincas cafeteras. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca exclusiva en Circunvalar' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Descubre Pereira desde una casa acogedora en Cerritos, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: cerca al aeropuerto y piscina. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa acogedora en Cerritos' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Descubre Pereira desde una cabaña encantadora en Cerritos, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: piscina y cerca al aeropuerto. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña encantadora en Cerritos' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Este apartamento tradicional en Circunvalar es el punto de partida perfecto para conocer Pereira y lo mejor de Risaralda.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina y termales de Santa Rosa. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento tradicional en Circunvalar' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Esta finca tranquila en Pinares es el punto de partida perfecto para conocer Pereira y lo mejor de Risaralda.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 7 personas.

Lo mejor del entorno: fincas cafeteras y piscina. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca tranquila en Pinares' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'En Cerritos, Pereira, te espera una casa sencilla con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: cerca al aeropuerto y fincas cafeteras. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa sencilla en Cerritos' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'En Pinares, Pereira, te espera una cabaña rústica con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: termales de Santa Rosa y piscina. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña rústica en Pinares' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'En Santa Rosa de Cabal, Pereira, te espera un apartamento sencillo con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: fincas cafeteras y cerca al aeropuerto. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento sencillo en Santa Rosa de Cabal' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'En Pinares, Pereira, te espera una finca moderna con todo lo necesario para una estadía tranquila.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 8 personas.

Lo mejor del entorno: termales de Santa Rosa y cerca al aeropuerto. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca moderna en Pinares' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'En Cerritos, Pereira, te espera una casa tranquila con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: termales de Santa Rosa y cerca al aeropuerto. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa tranquila en Cerritos' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Esta cabaña familiar en Santa Rosa de Cabal es el punto de partida perfecto para conocer Pereira y lo mejor de Risaralda.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: piscina y cerca al aeropuerto. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña familiar en Santa Rosa de Cabal' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Descubre Pereira desde un apartamento romántico en Pinares, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: termales de Santa Rosa y fincas cafeteras. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento romántico en Pinares' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'En Circunvalar, Pereira, te espera una finca rústica con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: cerca al aeropuerto y fincas cafeteras. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca rústica en Circunvalar' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Esta casa tranquila en Santa Rosa de Cabal es el punto de partida perfecto para conocer Pereira y lo mejor de Risaralda.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: fincas cafeteras y cerca al aeropuerto. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa tranquila en Santa Rosa de Cabal' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Esta cabaña colorida en Pinares es el punto de partida perfecto para conocer Pereira y lo mejor de Risaralda.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: piscina y cerca al aeropuerto. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña colorida en Pinares' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Este apartamento elegante está ubicado en Cerritos, uno de los sectores más agradables de Pereira, Risaralda.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina y termales de Santa Rosa. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento elegante en Cerritos' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Descubre Pereira desde una finca sencilla en Circunvalar, ideal para descansar después de un día de paseo.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 11 personas.

Lo mejor del entorno: fincas cafeteras y cerca al aeropuerto. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca sencilla en Circunvalar' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Descubre Pereira desde una casa romántica en Santa Rosa de Cabal, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y cerca al aeropuerto. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa romántica en Santa Rosa de Cabal' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Esta cabaña acogedora está ubicada en Santa Rosa de Cabal, uno de los sectores más agradables de Pereira, Risaralda.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: termales de Santa Rosa y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña acogedora en Santa Rosa de Cabal' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Descubre Pereira desde un apartamento fresco en Circunvalar, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cerca al aeropuerto y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento fresco en Circunvalar' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Esta finca familiar en Cerritos es el punto de partida perfecto para conocer Pereira y lo mejor de Risaralda.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 11 personas.

Lo mejor del entorno: termales de Santa Rosa y cerca al aeropuerto. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca familiar en Cerritos' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Descubre Pereira desde una casa tradicional en Circunvalar, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y fincas cafeteras. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa tradicional en Circunvalar' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Esta cabaña romántica en Santa Rosa de Cabal es el punto de partida perfecto para conocer Pereira y lo mejor de Risaralda.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: cerca al aeropuerto y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña romántica en Santa Rosa de Cabal' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'En Santa Rosa de Cabal, Pereira, te espera un apartamento moderno con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: fincas cafeteras y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento moderno en Santa Rosa de Cabal' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Esta finca fresca en Circunvalar es el punto de partida perfecto para conocer Pereira y lo mejor de Risaralda.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: termales de Santa Rosa y cerca al aeropuerto. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca fresca en Circunvalar' AND ciudad = 'Pereira';
UPDATE publicacion SET descripcion = 'Esta cabaña espaciosa en Valle de Cocora es el punto de partida perfecto para conocer Salento y lo mejor de Quindío.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: caminatas por el Cocora y palmas de cera. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña espaciosa en Valle de Cocora' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Descubre Salento desde un glamping romántico en Vereda Palestina, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: chimenea y palmas de cera. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping romántico en Vereda Palestina' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Descubre Salento desde una finca tradicional en Calle Real, ideal para descansar después de un día de paseo.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: chimenea y recorridos cafeteros. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca tradicional en Calle Real' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Descubre Salento desde una casa elegante en Vereda Palestina, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: caminatas por el Cocora y palmas de cera. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa elegante en Vereda Palestina' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Esta habitación moderna está ubicada en Filandia, uno de los sectores más agradables de Salento, Quindío.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: caminatas por el Cocora y palmas de cera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Filandia' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'En Calle Real, Salento, te espera una cabaña rústica con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: chimenea y palmas de cera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña rústica en Calle Real' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Este glamping fresco está ubicado en Vereda Palestina, uno de los sectores más agradables de Salento, Quindío.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: palmas de cera y caminatas por el Cocora. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping fresco en Vereda Palestina' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'En Mirador, Salento, te espera una finca colorida con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: palmas de cera y chimenea. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca colorida en Mirador' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Descubre Salento desde una casa acogedora en Valle de Cocora, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: chimenea y palmas de cera. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa acogedora en Valle de Cocora' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'En Valle de Cocora, Salento, te espera una habitación romántica con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: caminatas por el Cocora y chimenea. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación romántica en Valle de Cocora' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Descubre Salento desde una cabaña colorida en Valle de Cocora, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: chimenea y caminatas por el Cocora. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña colorida en Valle de Cocora' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Este glamping colorido está ubicado en Vereda Palestina, uno de los sectores más agradables de Salento, Quindío.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: chimenea y caminatas por el Cocora. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping colorido en Vereda Palestina' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Esta finca espaciosa en Vereda Palestina es el punto de partida perfecto para conocer Salento y lo mejor de Quindío.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: chimenea y recorridos cafeteros. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca espaciosa en Vereda Palestina' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Esta casa fresca en Filandia es el punto de partida perfecto para conocer Salento y lo mejor de Quindío.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: caminatas por el Cocora y palmas de cera. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa fresca en Filandia' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Esta habitación tradicional en Valle de Cocora es el punto de partida perfecto para conocer Salento y lo mejor de Quindío.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: recorridos cafeteros y palmas de cera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tradicional en Valle de Cocora' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Descubre Salento desde una cabaña luminosa en Valle de Cocora, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: palmas de cera y caminatas por el Cocora. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña luminosa en Valle de Cocora' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Este glamping romántico en Valle de Cocora es el punto de partida perfecto para conocer Salento y lo mejor de Quindío.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: palmas de cera y caminatas por el Cocora. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping romántico en Valle de Cocora' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'En Vereda Palestina, Salento, te espera una finca elegante con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: chimenea y palmas de cera. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca elegante en Vereda Palestina' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'En Valle de Cocora, Salento, te espera una casa fresca con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: palmas de cera y caminatas por el Cocora. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa fresca en Valle de Cocora' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Esta habitación tranquila está ubicada en Mirador, uno de los sectores más agradables de Salento, Quindío.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: chimenea y palmas de cera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tranquila en Mirador' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'En Mirador, Salento, te espera una cabaña tradicional con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: chimenea y recorridos cafeteros. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña tradicional en Mirador' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'En Mirador, Salento, te espera un glamping acogedor con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: recorridos cafeteros y caminatas por el Cocora. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping acogedor en Mirador' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Descubre Salento desde una finca encantadora en Filandia, ideal para descansar después de un día de paseo.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 14 personas.

Lo mejor del entorno: palmas de cera y recorridos cafeteros. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca encantadora en Filandia' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Descubre Salento desde una casa encantadora en Mirador, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: chimenea y recorridos cafeteros. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa encantadora en Mirador' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Esta habitación rústica está ubicada en Valle de Cocora, uno de los sectores más agradables de Salento, Quindío.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: chimenea y palmas de cera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación rústica en Valle de Cocora' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Descubre Salento desde una cabaña rústica en Valle de Cocora, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: chimenea y caminatas por el Cocora. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña rústica en Valle de Cocora' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Este glamping rústico en Valle de Cocora es el punto de partida perfecto para conocer Salento y lo mejor de Quindío.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: caminatas por el Cocora y palmas de cera. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping rústico en Valle de Cocora' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Esta finca familiar en Vereda Palestina es el punto de partida perfecto para conocer Salento y lo mejor de Quindío.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: palmas de cera y recorridos cafeteros. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca familiar en Vereda Palestina' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Esta casa encantadora en Calle Real es el punto de partida perfecto para conocer Salento y lo mejor de Quindío.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: palmas de cera y caminatas por el Cocora. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa encantadora en Calle Real' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Esta habitación tradicional en Mirador es el punto de partida perfecto para conocer Salento y lo mejor de Quindío.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: palmas de cera y chimenea. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tradicional en Mirador' AND ciudad = 'Salento';
UPDATE publicacion SET descripcion = 'Esta casa espaciosa está ubicada en Río Magdalena, uno de los sectores más agradables de Honda, Tolima.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: arquitectura republicana y clima cálido. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa espaciosa en Río Magdalena' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Descubre Honda desde una habitación elegante en Centro Histórico, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: piscina y arquitectura republicana. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación elegante en Centro Histórico' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta finca fresca en Puente Navarro es el punto de partida perfecto para conocer Honda y lo mejor de Tolima.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: clima cálido y arquitectura republicana. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca fresca en Puente Navarro' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta casa rústica en Calle de las Trampas es el punto de partida perfecto para conocer Honda y lo mejor de Tolima.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: clima cálido y río Magdalena. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa rústica en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta habitación moderna en Calle de las Trampas es el punto de partida perfecto para conocer Honda y lo mejor de Tolima.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: piscina y clima cálido. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta finca romántica está ubicada en Calle de las Trampas, uno de los sectores más agradables de Honda, Tolima.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 12 personas.

Lo mejor del entorno: arquitectura republicana y río Magdalena. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca romántica en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta casa espaciosa en Centro Histórico es el punto de partida perfecto para conocer Honda y lo mejor de Tolima.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y arquitectura republicana. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa espaciosa en Centro Histórico' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta habitación exclusiva en Calle de las Trampas es el punto de partida perfecto para conocer Honda y lo mejor de Tolima.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: clima cálido y piscina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación exclusiva en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Descubre Honda desde una finca fresca en Calle de las Trampas, ideal para descansar después de un día de paseo.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: río Magdalena y piscina. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca fresca en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta casa tranquila está ubicada en Calle de las Trampas, uno de los sectores más agradables de Honda, Tolima.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: arquitectura republicana y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa tranquila en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Descubre Honda desde una habitación tradicional en Puente Navarro, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: arquitectura republicana y río Magdalena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tradicional en Puente Navarro' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Descubre Honda desde una finca sencilla en Río Magdalena, ideal para descansar después de un día de paseo.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 12 personas.

Lo mejor del entorno: arquitectura republicana y clima cálido. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca sencilla en Río Magdalena' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta casa encantadora está ubicada en Calle de las Trampas, uno de los sectores más agradables de Honda, Tolima.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: arquitectura republicana y piscina. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa encantadora en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta habitación familiar en Puente Navarro es el punto de partida perfecto para conocer Honda y lo mejor de Tolima.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: piscina y clima cálido. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Puente Navarro' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta finca colorida está ubicada en Calle de las Trampas, uno de los sectores más agradables de Honda, Tolima.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: piscina y arquitectura republicana. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca colorida en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta casa encantadora está ubicada en Centro Histórico, uno de los sectores más agradables de Honda, Tolima.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y arquitectura republicana. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa encantadora en Centro Histórico' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Descubre Honda desde una habitación espaciosa en Calle de las Trampas, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: río Magdalena y piscina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación espaciosa en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta finca tradicional está ubicada en Centro Histórico, uno de los sectores más agradables de Honda, Tolima.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 8 personas.

Lo mejor del entorno: clima cálido y río Magdalena. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca tradicional en Centro Histórico' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'En Calle de las Trampas, Honda, te espera una casa acogedora con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: río Magdalena y clima cálido. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa acogedora en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Descubre Honda desde una habitación tradicional en Centro Histórico, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: piscina y río Magdalena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tradicional en Centro Histórico' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'En Centro Histórico, Honda, te espera una finca acogedora con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: río Magdalena y piscina. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca acogedora en Centro Histórico' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta casa luminosa en Puente Navarro es el punto de partida perfecto para conocer Honda y lo mejor de Tolima.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: arquitectura republicana y clima cálido. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa luminosa en Puente Navarro' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta habitación rústica está ubicada en Río Magdalena, uno de los sectores más agradables de Honda, Tolima.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: río Magdalena y clima cálido. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación rústica en Río Magdalena' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta finca fresca está ubicada en Río Magdalena, uno de los sectores más agradables de Honda, Tolima.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 14 personas.

Lo mejor del entorno: clima cálido y piscina. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca fresca en Río Magdalena' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'En Calle de las Trampas, Honda, te espera una casa espaciosa con todo lo necesario para una estadía tranquila.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y clima cálido. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa espaciosa en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Descubre Honda desde una habitación fresca en Calle de las Trampas, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: arquitectura republicana y piscina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación fresca en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'En Calle de las Trampas, Honda, te espera una finca exclusiva con todo lo necesario para una estadía tranquila.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: río Magdalena y clima cálido. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca exclusiva en Calle de las Trampas' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Descubre Honda desde una casa acogedora en Centro Histórico, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y río Magdalena. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa acogedora en Centro Histórico' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta habitación moderna está ubicada en Centro Histórico, uno de los sectores más agradables de Honda, Tolima.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: piscina y río Magdalena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Centro Histórico' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'En Puente Navarro, Honda, te espera una finca acogedora con todo lo necesario para una estadía tranquila.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 8 personas.

Lo mejor del entorno: río Magdalena y piscina. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca acogedora en Puente Navarro' AND ciudad = 'Honda';
UPDATE publicacion SET descripcion = 'Esta cabaña colorida en Parque Arqueológico es el punto de partida perfecto para conocer San Agustín y lo mejor de Huila.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: río Magdalena y café huilense. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña colorida en Parque Arqueológico' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'En Estrecho del Magdalena, San Agustín, te espera un glamping exclusivo con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: montañas verdes y estatuas agustinianas. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping exclusivo en Estrecho del Magdalena' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'En Parque Arqueológico, San Agustín, te espera una finca moderna con todo lo necesario para una estadía tranquila.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 11 personas.

Lo mejor del entorno: estatuas agustinianas y café huilense. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca moderna en Parque Arqueológico' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Descubre San Agustín desde una habitación familiar en Estrecho del Magdalena, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: café huilense y estatuas agustinianas. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Estrecho del Magdalena' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Descubre San Agustín desde una cabaña sencilla en Parque Arqueológico, ideal para descansar después de un día de paseo.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: río Magdalena y café huilense. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña sencilla en Parque Arqueológico' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Descubre San Agustín desde un glamping fresco en Centro, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: café huilense y montañas verdes. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping fresco en Centro' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Esta finca rústica está ubicada en Vereda El Tablón, uno de los sectores más agradables de San Agustín, Huila.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: montañas verdes y café huilense. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca rústica en Vereda El Tablón' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Esta habitación encantadora en Parque Arqueológico es el punto de partida perfecto para conocer San Agustín y lo mejor de Huila.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: café huilense y montañas verdes. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación encantadora en Parque Arqueológico' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'En Parque Arqueológico, San Agustín, te espera una cabaña fresca con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: estatuas agustinianas y café huilense. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña fresca en Parque Arqueológico' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Este glamping familiar está ubicado en Estrecho del Magdalena, uno de los sectores más agradables de San Agustín, Huila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: café huilense y estatuas agustinianas. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping familiar en Estrecho del Magdalena' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Esta finca tradicional está ubicada en Estrecho del Magdalena, uno de los sectores más agradables de San Agustín, Huila.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: río Magdalena y estatuas agustinianas. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca tradicional en Estrecho del Magdalena' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Descubre San Agustín desde una habitación luminosa en Estrecho del Magdalena, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: estatuas agustinianas y café huilense. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Estrecho del Magdalena' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Esta cabaña exclusiva en Vereda El Tablón es el punto de partida perfecto para conocer San Agustín y lo mejor de Huila.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: café huilense y estatuas agustinianas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña exclusiva en Vereda El Tablón' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Este glamping encantador está ubicado en Estrecho del Magdalena, uno de los sectores más agradables de San Agustín, Huila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: café huilense y estatuas agustinianas. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping encantador en Estrecho del Magdalena' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'En Vereda El Tablón, San Agustín, te espera una finca moderna con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: montañas verdes y estatuas agustinianas. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca moderna en Vereda El Tablón' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Descubre San Agustín desde una habitación espaciosa en Vereda El Tablón, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: café huilense y montañas verdes. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación espaciosa en Vereda El Tablón' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Esta cabaña acogedora en Centro es el punto de partida perfecto para conocer San Agustín y lo mejor de Huila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: café huilense y río Magdalena. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña acogedora en Centro' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'En Estrecho del Magdalena, San Agustín, te espera un glamping luminoso con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: café huilense y montañas verdes. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping luminoso en Estrecho del Magdalena' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Descubre San Agustín desde una finca elegante en Centro, ideal para descansar después de un día de paseo.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: río Magdalena y estatuas agustinianas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca elegante en Centro' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Esta habitación elegante en Vereda El Tablón es el punto de partida perfecto para conocer San Agustín y lo mejor de Huila.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: montañas verdes y río Magdalena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación elegante en Vereda El Tablón' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'En Estrecho del Magdalena, San Agustín, te espera una cabaña elegante con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: estatuas agustinianas y café huilense. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña elegante en Estrecho del Magdalena' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Este glamping tradicional en Parque Arqueológico es el punto de partida perfecto para conocer San Agustín y lo mejor de Huila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: montañas verdes y estatuas agustinianas. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping tradicional en Parque Arqueológico' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'En Centro, San Agustín, te espera una finca familiar con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 14 personas.

Lo mejor del entorno: río Magdalena y montañas verdes. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca familiar en Centro' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Esta habitación luminosa en Vereda El Tablón es el punto de partida perfecto para conocer San Agustín y lo mejor de Huila.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: café huilense y montañas verdes. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Vereda El Tablón' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Esta cabaña luminosa está ubicada en Parque Arqueológico, uno de los sectores más agradables de San Agustín, Huila.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: café huilense y montañas verdes. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña luminosa en Parque Arqueológico' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'En Vereda El Tablón, San Agustín, te espera un glamping rústico con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: café huilense y río Magdalena. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping rústico en Vereda El Tablón' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Esta finca colorida está ubicada en Vereda El Tablón, uno de los sectores más agradables de San Agustín, Huila.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 11 personas.

Lo mejor del entorno: estatuas agustinianas y río Magdalena. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca colorida en Vereda El Tablón' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Descubre San Agustín desde una habitación moderna en Parque Arqueológico, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: café huilense y río Magdalena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Parque Arqueológico' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Descubre San Agustín desde una cabaña fresca en Vereda El Tablón, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: montañas verdes y café huilense. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña fresca en Vereda El Tablón' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'En Estrecho del Magdalena, San Agustín, te espera un glamping espacioso con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: montañas verdes y río Magdalena. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping espacioso en Estrecho del Magdalena' AND ciudad = 'San Agustín';
UPDATE publicacion SET descripcion = 'Descubre Cali desde un apartamento exclusivo en Juanchito, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina y aire acondicionado. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento exclusivo en Juanchito' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Descubre Cali desde una casa exclusiva en Granada, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: zona gastronómica y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa exclusiva en Granada' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Esta habitación familiar en Granada es el punto de partida perfecto para conocer Cali y lo mejor de Valle del Cauca.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: capital de la salsa y zona gastronómica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Granada' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'En San Antonio, Cali, te espera un apartamento tradicional con todo lo necesario para una estadía tranquila.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina y capital de la salsa. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento tradicional en San Antonio' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'En Ciudad Jardín, Cali, te espera una casa encantadora con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: aire acondicionado y piscina. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa encantadora en Ciudad Jardín' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Esta habitación rústica está ubicada en El Peñón, uno de los sectores más agradables de Cali, Valle del Cauca.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: zona gastronómica y capital de la salsa. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación rústica en El Peñón' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Este apartamento sencillo en San Antonio es el punto de partida perfecto para conocer Cali y lo mejor de Valle del Cauca.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona gastronómica y aire acondicionado. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento sencillo en San Antonio' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Descubre Cali desde una casa tranquila en El Peñón, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: zona gastronómica y aire acondicionado. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa tranquila en El Peñón' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Descubre Cali desde una habitación sencilla en San Antonio, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: piscina y zona gastronómica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación sencilla en San Antonio' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Este apartamento acogedor en Juanchito es el punto de partida perfecto para conocer Cali y lo mejor de Valle del Cauca.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: capital de la salsa y zona gastronómica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento acogedor en Juanchito' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Esta casa tranquila está ubicada en Granada, uno de los sectores más agradables de Cali, Valle del Cauca.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: aire acondicionado y zona gastronómica. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa tranquila en Granada' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Descubre Cali desde una habitación encantadora en San Antonio, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: capital de la salsa y aire acondicionado. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación encantadora en San Antonio' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Este apartamento tranquilo está ubicado en Ciudad Jardín, uno de los sectores más agradables de Cali, Valle del Cauca.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: aire acondicionado y capital de la salsa. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tranquilo en Ciudad Jardín' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Descubre Cali desde una casa sencilla en Ciudad Jardín, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y capital de la salsa. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa sencilla en Ciudad Jardín' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Esta habitación fresca está ubicada en Ciudad Jardín, uno de los sectores más agradables de Cali, Valle del Cauca.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: aire acondicionado y zona gastronómica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación fresca en Ciudad Jardín' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Descubre Cali desde un apartamento moderno en Juanchito, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: capital de la salsa y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento moderno en Juanchito' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Esta casa fresca en Ciudad Jardín es el punto de partida perfecto para conocer Cali y lo mejor de Valle del Cauca.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y capital de la salsa. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa fresca en Ciudad Jardín' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Esta habitación sencilla está ubicada en Ciudad Jardín, uno de los sectores más agradables de Cali, Valle del Cauca.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: piscina y zona gastronómica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación sencilla en Ciudad Jardín' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Este apartamento rústico está ubicado en El Peñón, uno de los sectores más agradables de Cali, Valle del Cauca.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina y zona gastronómica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento rústico en El Peñón' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Descubre Cali desde una casa romántica en Juanchito, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: capital de la salsa y zona gastronómica. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa romántica en Juanchito' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Esta habitación tradicional en San Antonio es el punto de partida perfecto para conocer Cali y lo mejor de Valle del Cauca.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: zona gastronómica y aire acondicionado. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tradicional en San Antonio' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'En San Antonio, Cali, te espera un apartamento luminoso con todo lo necesario para una estadía tranquila.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: zona gastronómica y capital de la salsa. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento luminoso en San Antonio' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Esta casa romántica está ubicada en Ciudad Jardín, uno de los sectores más agradables de Cali, Valle del Cauca.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y zona gastronómica. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa romántica en Ciudad Jardín' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Esta habitación fresca está ubicada en Granada, uno de los sectores más agradables de Cali, Valle del Cauca.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: capital de la salsa y aire acondicionado. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación fresca en Granada' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'En El Peñón, Cali, te espera un apartamento luminoso con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina y aire acondicionado. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento luminoso en El Peñón' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Descubre Cali desde una casa fresca en Granada, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: aire acondicionado y capital de la salsa. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa fresca en Granada' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Descubre Cali desde una habitación moderna en El Peñón, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: piscina y capital de la salsa. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en El Peñón' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Este apartamento encantador en El Peñón es el punto de partida perfecto para conocer Cali y lo mejor de Valle del Cauca.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: aire acondicionado y zona gastronómica. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento encantador en El Peñón' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Esta casa familiar está ubicada en Ciudad Jardín, uno de los sectores más agradables de Cali, Valle del Cauca.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: capital de la salsa y zona gastronómica. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa familiar en Ciudad Jardín' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'En El Peñón, Cali, te espera una habitación familiar con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: aire acondicionado y capital de la salsa. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en El Peñón' AND ciudad = 'Cali';
UPDATE publicacion SET descripcion = 'Esta casa moderna en Centro Histórico es el punto de partida perfecto para conocer Popayán y lo mejor de Cauca.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: gastronomía caucana y procesiones de Semana Santa. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa moderna en Centro Histórico' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'En Puente del Humilladero, Popayán, te espera un apartamento fresco con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: gastronomía caucana y procesiones de Semana Santa. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento fresco en Puente del Humilladero' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'En Morro de Tulcán, Popayán, te espera una habitación familiar con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: casonas coloniales y procesiones de Semana Santa. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Morro de Tulcán' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Descubre Popayán desde una casa romántica en Pueblillo, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: gastronomía caucana y casonas coloniales. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa romántica en Pueblillo' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Este apartamento tranquilo está ubicado en Puente del Humilladero, uno de los sectores más agradables de Popayán, Cauca.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: gastronomía caucana y casonas coloniales. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento tranquilo en Puente del Humilladero' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Esta habitación moderna está ubicada en Puente del Humilladero, uno de los sectores más agradables de Popayán, Cauca.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: casonas coloniales y gastronomía caucana. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Puente del Humilladero' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'En Morro de Tulcán, Popayán, te espera una casa tranquila con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: casonas coloniales y procesiones de Semana Santa. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa tranquila en Morro de Tulcán' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Este apartamento sencillo está ubicado en Puente del Humilladero, uno de los sectores más agradables de Popayán, Cauca.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: gastronomía caucana y casonas coloniales. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento sencillo en Puente del Humilladero' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'En Pueblillo, Popayán, te espera una habitación moderna con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: gastronomía caucana y procesiones de Semana Santa. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Pueblillo' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Esta casa tradicional está ubicada en Puente del Humilladero, uno de los sectores más agradables de Popayán, Cauca.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: ciudad blanca y procesiones de Semana Santa. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa tradicional en Puente del Humilladero' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Descubre Popayán desde un apartamento romántico en Pueblillo, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: gastronomía caucana y procesiones de Semana Santa. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento romántico en Pueblillo' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Esta habitación elegante en Pueblillo es el punto de partida perfecto para conocer Popayán y lo mejor de Cauca.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: casonas coloniales y gastronomía caucana. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación elegante en Pueblillo' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'En Pueblillo, Popayán, te espera una casa luminosa con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: gastronomía caucana y ciudad blanca. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa luminosa en Pueblillo' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Este apartamento sencillo en Morro de Tulcán es el punto de partida perfecto para conocer Popayán y lo mejor de Cauca.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: gastronomía caucana y ciudad blanca. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento sencillo en Morro de Tulcán' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Esta habitación exclusiva está ubicada en Morro de Tulcán, uno de los sectores más agradables de Popayán, Cauca.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: procesiones de Semana Santa y ciudad blanca. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación exclusiva en Morro de Tulcán' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Esta casa rústica en Morro de Tulcán es el punto de partida perfecto para conocer Popayán y lo mejor de Cauca.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: procesiones de Semana Santa y casonas coloniales. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa rústica en Morro de Tulcán' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Descubre Popayán desde un apartamento rústico en Morro de Tulcán, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: gastronomía caucana y ciudad blanca. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento rústico en Morro de Tulcán' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'En Puente del Humilladero, Popayán, te espera una habitación tradicional con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: ciudad blanca y gastronomía caucana. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tradicional en Puente del Humilladero' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva en Morro de Tulcán es el punto de partida perfecto para conocer Popayán y lo mejor de Cauca.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: gastronomía caucana y procesiones de Semana Santa. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa exclusiva en Morro de Tulcán' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Descubre Popayán desde un apartamento exclusivo en Centro Histórico, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: casonas coloniales y ciudad blanca. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento exclusivo en Centro Histórico' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'En Pueblillo, Popayán, te espera una habitación encantadora con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: ciudad blanca y gastronomía caucana. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación encantadora en Pueblillo' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Esta casa tradicional en Centro Histórico es el punto de partida perfecto para conocer Popayán y lo mejor de Cauca.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: procesiones de Semana Santa y casonas coloniales. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa tradicional en Centro Histórico' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Este apartamento familiar está ubicado en Centro Histórico, uno de los sectores más agradables de Popayán, Cauca.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: casonas coloniales y ciudad blanca. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento familiar en Centro Histórico' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Esta habitación exclusiva en Centro Histórico es el punto de partida perfecto para conocer Popayán y lo mejor de Cauca.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: gastronomía caucana y procesiones de Semana Santa. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación exclusiva en Centro Histórico' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Esta casa familiar en Puente del Humilladero es el punto de partida perfecto para conocer Popayán y lo mejor de Cauca.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: ciudad blanca y gastronomía caucana. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa familiar en Puente del Humilladero' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Este apartamento elegante está ubicado en Puente del Humilladero, uno de los sectores más agradables de Popayán, Cauca.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: casonas coloniales y procesiones de Semana Santa. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento elegante en Puente del Humilladero' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Esta habitación familiar en Puente del Humilladero es el punto de partida perfecto para conocer Popayán y lo mejor de Cauca.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: casonas coloniales y gastronomía caucana. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Puente del Humilladero' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Esta casa romántica en Morro de Tulcán es el punto de partida perfecto para conocer Popayán y lo mejor de Cauca.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: procesiones de Semana Santa y casonas coloniales. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa romántica en Morro de Tulcán' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Este apartamento familiar está ubicado en Morro de Tulcán, uno de los sectores más agradables de Popayán, Cauca.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: casonas coloniales y ciudad blanca. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento familiar en Morro de Tulcán' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Esta habitación romántica está ubicada en Centro Histórico, uno de los sectores más agradables de Popayán, Cauca.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: ciudad blanca y gastronomía caucana. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación romántica en Centro Histórico' AND ciudad = 'Popayán';
UPDATE publicacion SET descripcion = 'Descubre Pasto desde un apartamento espacioso en Laguna de la Cocha, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: Santuario de Las Lajas y Carnaval de Negros y Blancos. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento espacioso en Laguna de la Cocha' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Esta casa familiar está ubicada en Las Lajas, uno de los sectores más agradables de Pasto, Nariño.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: Laguna de la Cocha y Carnaval de Negros y Blancos. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa familiar en Las Lajas' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'En Las Lajas, Pasto, te espera una cabaña tranquila con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: Carnaval de Negros y Blancos y Santuario de Las Lajas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña tranquila en Las Lajas' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'En Volcán Galeras, Pasto, te espera un apartamento rústico con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: Laguna de la Cocha y Santuario de Las Lajas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento rústico en Volcán Galeras' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'En Centro, Pasto, te espera una casa espaciosa con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: chimenea y Laguna de la Cocha. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa espaciosa en Centro' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'En Volcán Galeras, Pasto, te espera una cabaña tradicional con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: Laguna de la Cocha y chimenea. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña tradicional en Volcán Galeras' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Este apartamento colorido está ubicado en Laguna de la Cocha, uno de los sectores más agradables de Pasto, Nariño.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: Santuario de Las Lajas y chimenea. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento colorido en Laguna de la Cocha' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'En Volcán Galeras, Pasto, te espera una casa acogedora con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: Santuario de Las Lajas y Carnaval de Negros y Blancos. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa acogedora en Volcán Galeras' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'En Volcán Galeras, Pasto, te espera una cabaña espaciosa con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: Carnaval de Negros y Blancos y Laguna de la Cocha. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña espaciosa en Volcán Galeras' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'En Volcán Galeras, Pasto, te espera un apartamento elegante con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: Laguna de la Cocha y Santuario de Las Lajas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento elegante en Volcán Galeras' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'En Volcán Galeras, Pasto, te espera una casa familiar con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: Santuario de Las Lajas y Laguna de la Cocha. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa familiar en Volcán Galeras' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Esta cabaña acogedora está ubicada en Centro, uno de los sectores más agradables de Pasto, Nariño.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: chimenea y Laguna de la Cocha. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña acogedora en Centro' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Este apartamento encantador está ubicado en Volcán Galeras, uno de los sectores más agradables de Pasto, Nariño.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: Laguna de la Cocha y Santuario de Las Lajas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento encantador en Volcán Galeras' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Esta casa colorida está ubicada en Laguna de la Cocha, uno de los sectores más agradables de Pasto, Nariño.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: Laguna de la Cocha y Carnaval de Negros y Blancos. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa colorida en Laguna de la Cocha' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Descubre Pasto desde una cabaña sencilla en Las Lajas, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: Santuario de Las Lajas y Laguna de la Cocha. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña sencilla en Las Lajas' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Este apartamento exclusivo está ubicado en Laguna de la Cocha, uno de los sectores más agradables de Pasto, Nariño.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: Laguna de la Cocha y Santuario de Las Lajas. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento exclusivo en Laguna de la Cocha' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Esta casa elegante en Centro es el punto de partida perfecto para conocer Pasto y lo mejor de Nariño.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: Carnaval de Negros y Blancos y chimenea. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa elegante en Centro' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Esta cabaña romántica en Centro es el punto de partida perfecto para conocer Pasto y lo mejor de Nariño.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: Santuario de Las Lajas y Carnaval de Negros y Blancos. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña romántica en Centro' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Este apartamento fresco en Laguna de la Cocha es el punto de partida perfecto para conocer Pasto y lo mejor de Nariño.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: Laguna de la Cocha y Carnaval de Negros y Blancos. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento fresco en Laguna de la Cocha' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'En Las Lajas, Pasto, te espera una casa tradicional con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: chimenea y Santuario de Las Lajas. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa tradicional en Las Lajas' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Esta cabaña luminosa en Las Lajas es el punto de partida perfecto para conocer Pasto y lo mejor de Nariño.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: Laguna de la Cocha y Carnaval de Negros y Blancos. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña luminosa en Las Lajas' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Este apartamento sencillo en Centro es el punto de partida perfecto para conocer Pasto y lo mejor de Nariño.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: Carnaval de Negros y Blancos y Santuario de Las Lajas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento sencillo en Centro' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Descubre Pasto desde una casa moderna en Centro, ideal para descansar después de un día de paseo.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: Santuario de Las Lajas y Carnaval de Negros y Blancos. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa moderna en Centro' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Esta cabaña familiar en Volcán Galeras es el punto de partida perfecto para conocer Pasto y lo mejor de Nariño.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: Laguna de la Cocha y Carnaval de Negros y Blancos. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña familiar en Volcán Galeras' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Descubre Pasto desde un apartamento fresco en Centro, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: Laguna de la Cocha y Santuario de Las Lajas. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento fresco en Centro' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Esta casa fresca está ubicada en Centro, uno de los sectores más agradables de Pasto, Nariño.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: Carnaval de Negros y Blancos y Santuario de Las Lajas. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa fresca en Centro' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'En Volcán Galeras, Pasto, te espera una cabaña acogedora con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: Santuario de Las Lajas y chimenea. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña acogedora en Volcán Galeras' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Descubre Pasto desde un apartamento acogedor en Volcán Galeras, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: chimenea y Santuario de Las Lajas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento acogedor en Volcán Galeras' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'Descubre Pasto desde una casa elegante en Volcán Galeras, ideal para descansar después de un día de paseo.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: chimenea y Laguna de la Cocha. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa elegante en Volcán Galeras' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'En Las Lajas, Pasto, te espera una cabaña tradicional con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: Carnaval de Negros y Blancos y Laguna de la Cocha. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña tradicional en Las Lajas' AND ciudad = 'Pasto';
UPDATE publicacion SET descripcion = 'En Joví, Nuquí, te espera una cabaña familiar con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: surf y selva y mar. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña familiar en Joví' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Este glamping exclusivo en Termales es el punto de partida perfecto para conocer Nuquí y lo mejor de Chocó.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: termales naturales y avistamiento de ballenas. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping exclusivo en Termales' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'En Playa Guachalito, Nuquí, te espera una habitación sencilla con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: avistamiento de ballenas y selva y mar. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación sencilla en Playa Guachalito' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Esta casa sencilla está ubicada en Termales, uno de los sectores más agradables de Nuquí, Chocó.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: surf y termales naturales. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa sencilla en Termales' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Descubre Nuquí desde una cabaña moderna en Coquí, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: termales naturales y surf. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña moderna en Coquí' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Este glamping encantador en Playa Guachalito es el punto de partida perfecto para conocer Nuquí y lo mejor de Chocó.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: surf y selva y mar. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping encantador en Playa Guachalito' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Descubre Nuquí desde una habitación encantadora en Joví, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: avistamiento de ballenas y surf. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación encantadora en Joví' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Esta casa elegante en Coquí es el punto de partida perfecto para conocer Nuquí y lo mejor de Chocó.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: termales naturales y surf. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa elegante en Coquí' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Esta cabaña espaciosa está ubicada en Termales, uno de los sectores más agradables de Nuquí, Chocó.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: surf y selva y mar. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña espaciosa en Termales' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Este glamping tradicional está ubicado en Playa Guachalito, uno de los sectores más agradables de Nuquí, Chocó.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: surf y selva y mar. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping tradicional en Playa Guachalito' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Esta habitación moderna en Playa Guachalito es el punto de partida perfecto para conocer Nuquí y lo mejor de Chocó.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: surf y selva y mar. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Playa Guachalito' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'En Joví, Nuquí, te espera una casa tranquila con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: termales naturales y selva y mar. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa tranquila en Joví' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Descubre Nuquí desde una cabaña colorida en Coquí, ideal para descansar después de un día de paseo.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: termales naturales y selva y mar. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña colorida en Coquí' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Este glamping rústico en Termales es el punto de partida perfecto para conocer Nuquí y lo mejor de Chocó.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: avistamiento de ballenas y surf. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping rústico en Termales' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Esta habitación exclusiva está ubicada en Playa Guachalito, uno de los sectores más agradables de Nuquí, Chocó.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: selva y mar y surf. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación exclusiva en Playa Guachalito' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'En Coquí, Nuquí, te espera una casa moderna con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: termales naturales y avistamiento de ballenas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa moderna en Coquí' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Esta cabaña encantadora está ubicada en Termales, uno de los sectores más agradables de Nuquí, Chocó.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: avistamiento de ballenas y termales naturales. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña encantadora en Termales' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Descubre Nuquí desde un glamping sencillo en Joví, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: surf y avistamiento de ballenas. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping sencillo en Joví' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Esta habitación tranquila está ubicada en Coquí, uno de los sectores más agradables de Nuquí, Chocó.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: avistamiento de ballenas y termales naturales. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tranquila en Coquí' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Esta casa luminosa en Playa Guachalito es el punto de partida perfecto para conocer Nuquí y lo mejor de Chocó.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: selva y mar y termales naturales. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa luminosa en Playa Guachalito' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Esta cabaña moderna en Termales es el punto de partida perfecto para conocer Nuquí y lo mejor de Chocó.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: surf y termales naturales. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña moderna en Termales' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Descubre Nuquí desde un glamping familiar en Coquí, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: avistamiento de ballenas y selva y mar. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping familiar en Coquí' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Descubre Nuquí desde una habitación luminosa en Coquí, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: avistamiento de ballenas y selva y mar. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Coquí' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Esta casa encantadora en Playa Guachalito es el punto de partida perfecto para conocer Nuquí y lo mejor de Chocó.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: avistamiento de ballenas y surf. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa encantadora en Playa Guachalito' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Esta cabaña luminosa en Playa Guachalito es el punto de partida perfecto para conocer Nuquí y lo mejor de Chocó.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: selva y mar y termales naturales. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña luminosa en Playa Guachalito' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Descubre Nuquí desde un glamping luminoso en Termales, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: selva y mar y avistamiento de ballenas. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping luminoso en Termales' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'Esta habitación tranquila está ubicada en Playa Guachalito, uno de los sectores más agradables de Nuquí, Chocó.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: surf y selva y mar. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tranquila en Playa Guachalito' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'En Termales, Nuquí, te espera una casa familiar con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: avistamiento de ballenas y surf. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa familiar en Termales' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'En Joví, Nuquí, te espera una cabaña encantadora con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: avistamiento de ballenas y selva y mar. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña encantadora en Joví' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'En Termales, Nuquí, te espera un glamping acogedor con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: termales naturales y surf. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping acogedor en Termales' AND ciudad = 'Nuquí';
UPDATE publicacion SET descripcion = 'En Vía a Restrepo, Villavicencio, te espera una finca romántica con todo lo necesario para una estadía tranquila.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 12 personas.

Lo mejor del entorno: música llanera y atardecer llanero. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca romántica en Vía a Restrepo' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'En Centro, Villavicencio, te espera una casa familiar con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: música llanera y atardecer llanero. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa familiar en Centro' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'En Vía a Restrepo, Villavicencio, te espera un apartamento fresco con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: atardecer llanero y música llanera. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento fresco en Vía a Restrepo' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Descubre Villavicencio desde una cabaña elegante en Vía a Puerto López, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: atardecer llanero y piscina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña elegante en Vía a Puerto López' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Esta finca tradicional en Vía a Puerto López es el punto de partida perfecto para conocer Villavicencio y lo mejor de Meta.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 12 personas.

Lo mejor del entorno: piscina y atardecer llanero. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca tradicional en Vía a Puerto López' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Descubre Villavicencio desde una casa espaciosa en Vía a Puerto López, ideal para descansar después de un día de paseo.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: música llanera y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa espaciosa en Vía a Puerto López' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Descubre Villavicencio desde un apartamento romántico en Barrio La Grama, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: atardecer llanero y música llanera. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento romántico en Barrio La Grama' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Descubre Villavicencio desde una cabaña sencilla en Vía a Restrepo, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: mamona y carne a la llanera y música llanera. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña sencilla en Vía a Restrepo' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Descubre Villavicencio desde una finca tradicional en Centro, ideal para descansar después de un día de paseo.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: atardecer llanero y mamona y carne a la llanera. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca tradicional en Centro' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Descubre Villavicencio desde una casa familiar en Barrio La Grama, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: mamona y carne a la llanera y atardecer llanero. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa familiar en Barrio La Grama' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'En Barrio La Grama, Villavicencio, te espera un apartamento luminoso con todo lo necesario para una estadía tranquila.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: música llanera y atardecer llanero. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento luminoso en Barrio La Grama' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Descubre Villavicencio desde una cabaña acogedora en Vía a Puerto López, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: atardecer llanero y piscina. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña acogedora en Vía a Puerto López' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'En Vía a Restrepo, Villavicencio, te espera una finca fresca con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 14 personas.

Lo mejor del entorno: mamona y carne a la llanera y piscina. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca fresca en Vía a Restrepo' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Esta casa colorida está ubicada en Centro, uno de los sectores más agradables de Villavicencio, Meta.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: atardecer llanero y mamona y carne a la llanera. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa colorida en Centro' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Este apartamento exclusivo en Vía a Puerto López es el punto de partida perfecto para conocer Villavicencio y lo mejor de Meta.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina y música llanera. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento exclusivo en Vía a Puerto López' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'En Barrio La Grama, Villavicencio, te espera una cabaña romántica con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: atardecer llanero y mamona y carne a la llanera. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña romántica en Barrio La Grama' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Descubre Villavicencio desde una finca espaciosa en Vía a Puerto López, ideal para descansar después de un día de paseo.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 6 personas.

Lo mejor del entorno: atardecer llanero y música llanera. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca espaciosa en Vía a Puerto López' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Descubre Villavicencio desde una casa encantadora en Barrio La Grama, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: música llanera y atardecer llanero. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa encantadora en Barrio La Grama' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Este apartamento tradicional está ubicado en Vía a Puerto López, uno de los sectores más agradables de Villavicencio, Meta.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: atardecer llanero y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento tradicional en Vía a Puerto López' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Esta cabaña sencilla en Centro es el punto de partida perfecto para conocer Villavicencio y lo mejor de Meta.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: música llanera y atardecer llanero. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña sencilla en Centro' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Esta finca exclusiva está ubicada en Barrio La Grama, uno de los sectores más agradables de Villavicencio, Meta.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: piscina y mamona y carne a la llanera. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca exclusiva en Barrio La Grama' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Esta casa luminosa está ubicada en Barrio La Grama, uno de los sectores más agradables de Villavicencio, Meta.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: música llanera y mamona y carne a la llanera. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa luminosa en Barrio La Grama' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Este apartamento rústico está ubicado en Vía a Restrepo, uno de los sectores más agradables de Villavicencio, Meta.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: mamona y carne a la llanera y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento rústico en Vía a Restrepo' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Esta cabaña fresca en Centro es el punto de partida perfecto para conocer Villavicencio y lo mejor de Meta.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: piscina y atardecer llanero. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña fresca en Centro' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Descubre Villavicencio desde una finca colorida en Vía a Puerto López, ideal para descansar después de un día de paseo.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: piscina y música llanera. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca colorida en Vía a Puerto López' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Esta casa sencilla en Centro es el punto de partida perfecto para conocer Villavicencio y lo mejor de Meta.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: atardecer llanero y piscina. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa sencilla en Centro' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'En Vía a Puerto López, Villavicencio, te espera un apartamento encantador con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: mamona y carne a la llanera y atardecer llanero. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento encantador en Vía a Puerto López' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Esta cabaña colorida está ubicada en Barrio La Grama, uno de los sectores más agradables de Villavicencio, Meta.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: atardecer llanero y piscina. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña colorida en Barrio La Grama' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'En Barrio La Grama, Villavicencio, te espera una finca sencilla con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: piscina y mamona y carne a la llanera. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca sencilla en Barrio La Grama' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Descubre Villavicencio desde una casa moderna en Vía a Puerto López, ideal para descansar después de un día de paseo.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y mamona y carne a la llanera. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa moderna en Vía a Puerto López' AND ciudad = 'Villavicencio';
UPDATE publicacion SET descripcion = 'Esta finca familiar está ubicada en La Campiña, uno de los sectores más agradables de Yopal, Casanare.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 14 personas.

Lo mejor del entorno: cabalgatas y piscina. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca familiar en La Campiña' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Esta casa espaciosa está ubicada en Centro, uno de los sectores más agradables de Yopal, Casanare.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y cabalgatas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa espaciosa en Centro' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Descubre Yopal desde un apartamento fresco en La Campiña, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: vida de hato llanero y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento fresco en La Campiña' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Descubre Yopal desde una finca tradicional en Vía a Aguazul, ideal para descansar después de un día de paseo.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 7 personas.

Lo mejor del entorno: cabalgatas y piscina. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca tradicional en Vía a Aguazul' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Esta casa encantadora está ubicada en La Campiña, uno de los sectores más agradables de Yopal, Casanare.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y cabalgatas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa encantadora en La Campiña' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'En Hatos llaneros, Yopal, te espera un apartamento rústico con todo lo necesario para una estadía tranquila.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cabalgatas y avistamiento de aves. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento rústico en Hatos llaneros' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Descubre Yopal desde una finca luminosa en La Campiña, ideal para descansar después de un día de paseo.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: cabalgatas y vida de hato llanero. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca luminosa en La Campiña' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Esta casa rústica en Hatos llaneros es el punto de partida perfecto para conocer Yopal y lo mejor de Casanare.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: cabalgatas y avistamiento de aves. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa rústica en Hatos llaneros' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'En La Campiña, Yopal, te espera un apartamento tranquilo con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: vida de hato llanero y cabalgatas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento tranquilo en La Campiña' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Esta finca tranquila está ubicada en Vía a Aguazul, uno de los sectores más agradables de Yopal, Casanare.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 9 personas.

Lo mejor del entorno: vida de hato llanero y cabalgatas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca tranquila en Vía a Aguazul' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Esta casa espaciosa está ubicada en Vía a Aguazul, uno de los sectores más agradables de Yopal, Casanare.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y avistamiento de aves. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa espaciosa en Vía a Aguazul' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'En La Campiña, Yopal, te espera un apartamento colorido con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cabalgatas y avistamiento de aves. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento colorido en La Campiña' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Descubre Yopal desde una finca tranquila en Centro, ideal para descansar después de un día de paseo.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: vida de hato llanero y piscina. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca tranquila en Centro' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Esta casa romántica está ubicada en Hatos llaneros, uno de los sectores más agradables de Yopal, Casanare.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y avistamiento de aves. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa romántica en Hatos llaneros' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'En La Campiña, Yopal, te espera un apartamento elegante con todo lo necesario para una estadía tranquila.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: avistamiento de aves y cabalgatas. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento elegante en La Campiña' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'En Hatos llaneros, Yopal, te espera una finca exclusiva con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: cabalgatas y piscina. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca exclusiva en Hatos llaneros' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Descubre Yopal desde una casa elegante en La Campiña, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: vida de hato llanero y cabalgatas. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa elegante en La Campiña' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Este apartamento espacioso está ubicado en Hatos llaneros, uno de los sectores más agradables de Yopal, Casanare.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: vida de hato llanero y avistamiento de aves. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento espacioso en Hatos llaneros' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Descubre Yopal desde una finca romántica en Vía a Aguazul, ideal para descansar después de un día de paseo.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: cabalgatas y vida de hato llanero. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca romántica en Vía a Aguazul' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'En Vía a Aguazul, Yopal, te espera una casa romántica con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: avistamiento de aves y cabalgatas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa romántica en Vía a Aguazul' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Este apartamento sencillo está ubicado en La Campiña, uno de los sectores más agradables de Yopal, Casanare.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cabalgatas y avistamiento de aves. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento sencillo en La Campiña' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Descubre Yopal desde una finca encantadora en Vía a Aguazul, ideal para descansar después de un día de paseo.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: piscina y avistamiento de aves. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca encantadora en Vía a Aguazul' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Esta casa fresca está ubicada en Centro, uno de los sectores más agradables de Yopal, Casanare.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y avistamiento de aves. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa fresca en Centro' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'En Hatos llaneros, Yopal, te espera un apartamento romántico con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: cabalgatas y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento romántico en Hatos llaneros' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Esta finca rústica en La Campiña es el punto de partida perfecto para conocer Yopal y lo mejor de Casanare.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: vida de hato llanero y piscina. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca rústica en La Campiña' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'En Vía a Aguazul, Yopal, te espera una casa elegante con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y cabalgatas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa elegante en Vía a Aguazul' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Descubre Yopal desde un apartamento elegante en Centro, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina y avistamiento de aves. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento elegante en Centro' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'En Vía a Aguazul, Yopal, te espera una finca sencilla con todo lo necesario para una estadía tranquila.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 7 personas.

Lo mejor del entorno: vida de hato llanero y piscina. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca sencilla en Vía a Aguazul' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Esta casa rústica está ubicada en La Campiña, uno de los sectores más agradables de Yopal, Casanare.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: vida de hato llanero y avistamiento de aves. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa rústica en La Campiña' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Descubre Yopal desde un apartamento colorido en Hatos llaneros, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: vida de hato llanero y avistamiento de aves. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento colorido en Hatos llaneros' AND ciudad = 'Yopal';
UPDATE publicacion SET descripcion = 'Esta casa moderna está ubicada en Barrio Unión, uno de los sectores más agradables de Arauca, Arauca.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: joropo y sabanas infinitas. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa moderna en Barrio Unión' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta finca colorida en Río Arauca es el punto de partida perfecto para conocer Arauca y lo mejor de Arauca.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: joropo y tranquilidad. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca colorida en Río Arauca' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Este apartamento rústico en Barrio Unión es el punto de partida perfecto para conocer Arauca y lo mejor de Arauca.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: sabanas infinitas y joropo. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento rústico en Barrio Unión' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta casa romántica está ubicada en Barrio Unión, uno de los sectores más agradables de Arauca, Arauca.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: joropo y río Arauca. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa romántica en Barrio Unión' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta finca encantadora en Río Arauca es el punto de partida perfecto para conocer Arauca y lo mejor de Arauca.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: río Arauca y joropo. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca encantadora en Río Arauca' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Este apartamento acogedor está ubicado en Barrio Unión, uno de los sectores más agradables de Arauca, Arauca.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: joropo y río Arauca. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento acogedor en Barrio Unión' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta casa espaciosa en Centro es el punto de partida perfecto para conocer Arauca y lo mejor de Arauca.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: joropo y tranquilidad. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa espaciosa en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Descubre Arauca desde una finca exclusiva en Vía a Caño Limón, ideal para descansar después de un día de paseo.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 11 personas.

Lo mejor del entorno: sabanas infinitas y tranquilidad. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca exclusiva en Vía a Caño Limón' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Este apartamento familiar está ubicado en Centro, uno de los sectores más agradables de Arauca, Arauca.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: río Arauca y joropo. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento familiar en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Descubre Arauca desde una casa colorida en Centro, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: sabanas infinitas y joropo. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa colorida en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta finca sencilla en Centro es el punto de partida perfecto para conocer Arauca y lo mejor de Arauca.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 12 personas.

Lo mejor del entorno: tranquilidad y río Arauca. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca sencilla en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'En Vía a Caño Limón, Arauca, te espera un apartamento luminoso con todo lo necesario para una estadía tranquila.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: río Arauca y sabanas infinitas. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento luminoso en Vía a Caño Limón' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta casa tranquila en Vía a Caño Limón es el punto de partida perfecto para conocer Arauca y lo mejor de Arauca.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: tranquilidad y sabanas infinitas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa tranquila en Vía a Caño Limón' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'En Centro, Arauca, te espera una finca exclusiva con todo lo necesario para una estadía tranquila.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 6 personas.

Lo mejor del entorno: joropo y tranquilidad. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca exclusiva en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'En Río Arauca, Arauca, te espera un apartamento acogedor con todo lo necesario para una estadía tranquila.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: joropo y río Arauca. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento acogedor en Río Arauca' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta casa tranquila en Centro es el punto de partida perfecto para conocer Arauca y lo mejor de Arauca.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: tranquilidad y río Arauca. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa tranquila en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta finca luminosa está ubicada en Vía a Caño Limón, uno de los sectores más agradables de Arauca, Arauca.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: sabanas infinitas y tranquilidad. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca luminosa en Vía a Caño Limón' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'En Centro, Arauca, te espera un apartamento elegante con todo lo necesario para una estadía tranquila.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: río Arauca y joropo. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento elegante en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'En Centro, Arauca, te espera una casa exclusiva con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: joropo y tranquilidad. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa exclusiva en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta finca acogedora en Centro es el punto de partida perfecto para conocer Arauca y lo mejor de Arauca.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: joropo y sabanas infinitas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca acogedora en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Este apartamento fresco en Centro es el punto de partida perfecto para conocer Arauca y lo mejor de Arauca.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: sabanas infinitas y joropo. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento fresco en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta casa moderna está ubicada en Vía a Caño Limón, uno de los sectores más agradables de Arauca, Arauca.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: joropo y tranquilidad. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa moderna en Vía a Caño Limón' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'En Barrio Unión, Arauca, te espera una finca rústica con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 14 personas.

Lo mejor del entorno: tranquilidad y sabanas infinitas. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca rústica en Barrio Unión' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Descubre Arauca desde un apartamento familiar en Vía a Caño Limón, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: joropo y sabanas infinitas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento familiar en Vía a Caño Limón' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta casa colorida en Barrio Unión es el punto de partida perfecto para conocer Arauca y lo mejor de Arauca.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: sabanas infinitas y río Arauca. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa colorida en Barrio Unión' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta finca romántica en Barrio Unión es el punto de partida perfecto para conocer Arauca y lo mejor de Arauca.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 7 personas.

Lo mejor del entorno: tranquilidad y sabanas infinitas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca romántica en Barrio Unión' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Descubre Arauca desde un apartamento moderno en Vía a Caño Limón, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: sabanas infinitas y río Arauca. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento moderno en Vía a Caño Limón' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta casa rústica está ubicada en Centro, uno de los sectores más agradables de Arauca, Arauca.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: tranquilidad y sabanas infinitas. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa rústica en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta finca colorida en Centro es el punto de partida perfecto para conocer Arauca y lo mejor de Arauca.

La finca tiene 5 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 11 personas.

Lo mejor del entorno: joropo y tranquilidad. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Finca colorida en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Descubre Arauca desde un apartamento moderno en Centro, ideal para descansar después de un día de paseo.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: joropo y río Arauca. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento moderno en Centro' AND ciudad = 'Arauca';
UPDATE publicacion SET descripcion = 'Esta cabaña fresca en Río Orinoco es el punto de partida perfecto para conocer Puerto Carreño y lo mejor de Vichada.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: delfines rosados y pesca deportiva. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña fresca en Río Orinoco' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Esta casa encantadora está ubicada en Centro, uno de los sectores más agradables de Puerto Carreño, Vichada.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: pesca deportiva y delfines rosados. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa encantadora en Centro' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Este glamping colorido está ubicado en Centro, uno de los sectores más agradables de Puerto Carreño, Vichada.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: atardeceres y delfines rosados. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping colorido en Centro' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Esta cabaña luminosa en Cerro de la Bandera es el punto de partida perfecto para conocer Puerto Carreño y lo mejor de Vichada.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: río Orinoco y atardeceres. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña luminosa en Cerro de la Bandera' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'En Reserva Bojonawi, Puerto Carreño, te espera una casa exclusiva con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: atardeceres y río Orinoco. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa exclusiva en Reserva Bojonawi' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Este glamping espacioso en Cerro de la Bandera es el punto de partida perfecto para conocer Puerto Carreño y lo mejor de Vichada.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: atardeceres y pesca deportiva. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping espacioso en Cerro de la Bandera' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Descubre Puerto Carreño desde una cabaña luminosa en Centro, ideal para descansar después de un día de paseo.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: río Orinoco y pesca deportiva. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña luminosa en Centro' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Descubre Puerto Carreño desde una casa moderna en Cerro de la Bandera, ideal para descansar después de un día de paseo.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: río Orinoco y pesca deportiva. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa moderna en Cerro de la Bandera' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Este glamping acogedor está ubicado en Centro, uno de los sectores más agradables de Puerto Carreño, Vichada.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: pesca deportiva y río Orinoco. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping acogedor en Centro' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Esta cabaña tradicional está ubicada en Cerro de la Bandera, uno de los sectores más agradables de Puerto Carreño, Vichada.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: río Orinoco y delfines rosados. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña tradicional en Cerro de la Bandera' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Descubre Puerto Carreño desde una casa luminosa en Reserva Bojonawi, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: pesca deportiva y río Orinoco. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa luminosa en Reserva Bojonawi' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Este glamping familiar en Cerro de la Bandera es el punto de partida perfecto para conocer Puerto Carreño y lo mejor de Vichada.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: atardeceres y delfines rosados. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping familiar en Cerro de la Bandera' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Esta cabaña familiar está ubicada en Cerro de la Bandera, uno de los sectores más agradables de Puerto Carreño, Vichada.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: atardeceres y delfines rosados. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña familiar en Cerro de la Bandera' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'En Reserva Bojonawi, Puerto Carreño, te espera una casa tranquila con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: río Orinoco y atardeceres. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa tranquila en Reserva Bojonawi' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Descubre Puerto Carreño desde un glamping colorido en Reserva Bojonawi, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: río Orinoco y pesca deportiva. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping colorido en Reserva Bojonawi' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Descubre Puerto Carreño desde una cabaña acogedora en Cerro de la Bandera, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: río Orinoco y pesca deportiva. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña acogedora en Cerro de la Bandera' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'En Centro, Puerto Carreño, te espera una casa tranquila con todo lo necesario para una estadía tranquila.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: delfines rosados y río Orinoco. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa tranquila en Centro' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'En Centro, Puerto Carreño, te espera un glamping romántico con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: atardeceres y pesca deportiva. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping romántico en Centro' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Descubre Puerto Carreño desde una cabaña rústica en Centro, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: pesca deportiva y delfines rosados. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña rústica en Centro' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Descubre Puerto Carreño desde una casa acogedora en Río Orinoco, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: atardeceres y delfines rosados. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa acogedora en Río Orinoco' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Este glamping fresco está ubicado en Cerro de la Bandera, uno de los sectores más agradables de Puerto Carreño, Vichada.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: atardeceres y delfines rosados. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping fresco en Cerro de la Bandera' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Esta cabaña tranquila está ubicada en Centro, uno de los sectores más agradables de Puerto Carreño, Vichada.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: atardeceres y río Orinoco. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña tranquila en Centro' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Esta casa moderna en Reserva Bojonawi es el punto de partida perfecto para conocer Puerto Carreño y lo mejor de Vichada.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: delfines rosados y atardeceres. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa moderna en Reserva Bojonawi' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Este glamping fresco en Río Orinoco es el punto de partida perfecto para conocer Puerto Carreño y lo mejor de Vichada.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: río Orinoco y pesca deportiva. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping fresco en Río Orinoco' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Descubre Puerto Carreño desde una cabaña moderna en Centro, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: atardeceres y pesca deportiva. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña moderna en Centro' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'En Cerro de la Bandera, Puerto Carreño, te espera una casa elegante con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: atardeceres y pesca deportiva. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa elegante en Cerro de la Bandera' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Descubre Puerto Carreño desde un glamping rústico en Reserva Bojonawi, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: atardeceres y pesca deportiva. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping rústico en Reserva Bojonawi' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Esta cabaña romántica está ubicada en Cerro de la Bandera, uno de los sectores más agradables de Puerto Carreño, Vichada.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: atardeceres y delfines rosados. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña romántica en Cerro de la Bandera' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva en Cerro de la Bandera es el punto de partida perfecto para conocer Puerto Carreño y lo mejor de Vichada.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: atardeceres y delfines rosados. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa exclusiva en Cerro de la Bandera' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'En Reserva Bojonawi, Puerto Carreño, te espera un glamping acogedor con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: delfines rosados y atardeceres. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping acogedor en Reserva Bojonawi' AND ciudad = 'Puerto Carreño';
UPDATE publicacion SET descripcion = 'Esta cabaña tranquila está ubicada en Comunidad Coco Viejo, uno de los sectores más agradables de Inírida, Guainía.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: flor de Inírida y Cerros de Mavecure. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña tranquila en Comunidad Coco Viejo' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Este glamping exclusivo en Estrella Fluvial es el punto de partida perfecto para conocer Inírida y lo mejor de Guainía.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: flor de Inírida y selva amazónica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping exclusivo en Estrella Fluvial' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Esta habitación acogedora está ubicada en Centro, uno de los sectores más agradables de Inírida, Guainía.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: flor de Inírida y ríos de aguas negras. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación acogedora en Centro' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Descubre Inírida desde una cabaña exclusiva en Cerros de Mavecure, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: selva amazónica y Cerros de Mavecure. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña exclusiva en Cerros de Mavecure' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Descubre Inírida desde un glamping exclusivo en Centro, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: flor de Inírida y Cerros de Mavecure. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping exclusivo en Centro' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Esta habitación rústica en Centro es el punto de partida perfecto para conocer Inírida y lo mejor de Guainía.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: flor de Inírida y ríos de aguas negras. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación rústica en Centro' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Descubre Inírida desde una cabaña romántica en Centro, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: ríos de aguas negras y selva amazónica. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña romántica en Centro' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Este glamping moderno en Cerros de Mavecure es el punto de partida perfecto para conocer Inírida y lo mejor de Guainía.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: flor de Inírida y Cerros de Mavecure. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping moderno en Cerros de Mavecure' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Descubre Inírida desde una habitación fresca en Estrella Fluvial, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: flor de Inírida y ríos de aguas negras. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación fresca en Estrella Fluvial' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Descubre Inírida desde una cabaña romántica en Comunidad Coco Viejo, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: ríos de aguas negras y selva amazónica. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña romántica en Comunidad Coco Viejo' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Este glamping fresco está ubicado en Centro, uno de los sectores más agradables de Inírida, Guainía.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: Cerros de Mavecure y flor de Inírida. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping fresco en Centro' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Esta habitación tradicional en Cerros de Mavecure es el punto de partida perfecto para conocer Inírida y lo mejor de Guainía.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: flor de Inírida y ríos de aguas negras. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tradicional en Cerros de Mavecure' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Descubre Inírida desde una cabaña romántica en Estrella Fluvial, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: Cerros de Mavecure y flor de Inírida. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña romántica en Estrella Fluvial' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Este glamping tranquilo en Cerros de Mavecure es el punto de partida perfecto para conocer Inírida y lo mejor de Guainía.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: flor de Inírida y selva amazónica. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping tranquilo en Cerros de Mavecure' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'En Comunidad Coco Viejo, Inírida, te espera una habitación tranquila con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: ríos de aguas negras y Cerros de Mavecure. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tranquila en Comunidad Coco Viejo' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Descubre Inírida desde una cabaña luminosa en Cerros de Mavecure, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: flor de Inírida y ríos de aguas negras. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña luminosa en Cerros de Mavecure' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Descubre Inírida desde un glamping familiar en Centro, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: flor de Inírida y selva amazónica. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping familiar en Centro' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Descubre Inírida desde una habitación familiar en Centro, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: selva amazónica y flor de Inírida. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Centro' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Esta cabaña espaciosa está ubicada en Comunidad Coco Viejo, uno de los sectores más agradables de Inírida, Guainía.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: Cerros de Mavecure y ríos de aguas negras. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña espaciosa en Comunidad Coco Viejo' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'En Estrella Fluvial, Inírida, te espera un glamping sencillo con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: Cerros de Mavecure y flor de Inírida. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping sencillo en Estrella Fluvial' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Esta habitación encantadora está ubicada en Estrella Fluvial, uno de los sectores más agradables de Inírida, Guainía.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: selva amazónica y flor de Inírida. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación encantadora en Estrella Fluvial' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Esta cabaña elegante en Centro es el punto de partida perfecto para conocer Inírida y lo mejor de Guainía.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: flor de Inírida y selva amazónica. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña elegante en Centro' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'En Centro, Inírida, te espera un glamping acogedor con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: ríos de aguas negras y selva amazónica. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping acogedor en Centro' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Esta habitación exclusiva en Comunidad Coco Viejo es el punto de partida perfecto para conocer Inírida y lo mejor de Guainía.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: flor de Inírida y Cerros de Mavecure. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación exclusiva en Comunidad Coco Viejo' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Descubre Inírida desde una cabaña elegante en Comunidad Coco Viejo, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: flor de Inírida y ríos de aguas negras. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña elegante en Comunidad Coco Viejo' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Este glamping elegante en Estrella Fluvial es el punto de partida perfecto para conocer Inírida y lo mejor de Guainía.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: selva amazónica y ríos de aguas negras. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping elegante en Estrella Fluvial' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Esta habitación espaciosa en Centro es el punto de partida perfecto para conocer Inírida y lo mejor de Guainía.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: flor de Inírida y selva amazónica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación espaciosa en Centro' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'En Centro, Inírida, te espera una cabaña moderna con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: Cerros de Mavecure y selva amazónica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña moderna en Centro' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Este glamping moderno en Comunidad Coco Viejo es el punto de partida perfecto para conocer Inírida y lo mejor de Guainía.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: flor de Inírida y selva amazónica. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping moderno en Comunidad Coco Viejo' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Esta habitación colorida en Comunidad Coco Viejo es el punto de partida perfecto para conocer Inírida y lo mejor de Guainía.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: ríos de aguas negras y flor de Inírida. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación colorida en Comunidad Coco Viejo' AND ciudad = 'Inírida';
UPDATE publicacion SET descripcion = 'Esta cabaña familiar está ubicada en Puerta de Orión, uno de los sectores más agradables de San José del Guaviare, Guaviare.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: pozos naturales y selva. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña familiar en Puerta de Orión' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Este glamping moderno está ubicado en Centro, uno de los sectores más agradables de San José del Guaviare, Guaviare.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: selva y pinturas rupestres. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping moderno en Centro' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta casa familiar en Ciudad de Piedra es el punto de partida perfecto para conocer San José del Guaviare y lo mejor de Guaviare.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: pozos naturales y Puerta de Orión. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa familiar en Ciudad de Piedra' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta cabaña luminosa en Puerta de Orión es el punto de partida perfecto para conocer San José del Guaviare y lo mejor de Guaviare.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: selva y pozos naturales. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña luminosa en Puerta de Orión' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Descubre San José del Guaviare desde un glamping encantador en Puerta de Orión, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: pinturas rupestres y Puerta de Orión. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping encantador en Puerta de Orión' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva en Pozos Naturales es el punto de partida perfecto para conocer San José del Guaviare y lo mejor de Guaviare.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: selva y pinturas rupestres. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa exclusiva en Pozos Naturales' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta cabaña acogedora en Pozos Naturales es el punto de partida perfecto para conocer San José del Guaviare y lo mejor de Guaviare.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: Puerta de Orión y pozos naturales. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña acogedora en Pozos Naturales' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Descubre San José del Guaviare desde un glamping rústico en Ciudad de Piedra, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: pinturas rupestres y pozos naturales. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping rústico en Ciudad de Piedra' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta casa luminosa en Ciudad de Piedra es el punto de partida perfecto para conocer San José del Guaviare y lo mejor de Guaviare.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: Puerta de Orión y selva. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa luminosa en Ciudad de Piedra' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta cabaña elegante en Centro es el punto de partida perfecto para conocer San José del Guaviare y lo mejor de Guaviare.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: Puerta de Orión y selva. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña elegante en Centro' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Este glamping encantador está ubicado en Pozos Naturales, uno de los sectores más agradables de San José del Guaviare, Guaviare.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: pinturas rupestres y pozos naturales. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping encantador en Pozos Naturales' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta casa moderna está ubicada en Puerta de Orión, uno de los sectores más agradables de San José del Guaviare, Guaviare.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: pinturas rupestres y Puerta de Orión. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa moderna en Puerta de Orión' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Descubre San José del Guaviare desde una cabaña elegante en Pozos Naturales, ideal para descansar después de un día de paseo.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: selva y Puerta de Orión. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña elegante en Pozos Naturales' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'En Ciudad de Piedra, San José del Guaviare, te espera un glamping moderno con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: pinturas rupestres y selva. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping moderno en Ciudad de Piedra' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta casa elegante en Ciudad de Piedra es el punto de partida perfecto para conocer San José del Guaviare y lo mejor de Guaviare.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: selva y pinturas rupestres. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa elegante en Ciudad de Piedra' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'En Pozos Naturales, San José del Guaviare, te espera una cabaña luminosa con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: pozos naturales y pinturas rupestres. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña luminosa en Pozos Naturales' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Este glamping luminoso está ubicado en Pozos Naturales, uno de los sectores más agradables de San José del Guaviare, Guaviare.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: pozos naturales y selva. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping luminoso en Pozos Naturales' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta casa espaciosa en Puerta de Orión es el punto de partida perfecto para conocer San José del Guaviare y lo mejor de Guaviare.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: pinturas rupestres y selva. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa espaciosa en Puerta de Orión' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta cabaña espaciosa está ubicada en Centro, uno de los sectores más agradables de San José del Guaviare, Guaviare.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: pinturas rupestres y Puerta de Orión. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña espaciosa en Centro' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Este glamping exclusivo está ubicado en Centro, uno de los sectores más agradables de San José del Guaviare, Guaviare.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: selva y pinturas rupestres. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping exclusivo en Centro' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Descubre San José del Guaviare desde una casa tradicional en Centro, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: selva y Puerta de Orión. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa tradicional en Centro' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta cabaña romántica está ubicada en Pozos Naturales, uno de los sectores más agradables de San José del Guaviare, Guaviare.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: selva y Puerta de Orión. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña romántica en Pozos Naturales' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'En Puerta de Orión, San José del Guaviare, te espera un glamping moderno con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: Puerta de Orión y pozos naturales. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping moderno en Puerta de Orión' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta casa romántica está ubicada en Centro, uno de los sectores más agradables de San José del Guaviare, Guaviare.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: Puerta de Orión y pozos naturales. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa romántica en Centro' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta cabaña romántica está ubicada en Ciudad de Piedra, uno de los sectores más agradables de San José del Guaviare, Guaviare.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: pozos naturales y selva. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña romántica en Ciudad de Piedra' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Este glamping tranquilo en Pozos Naturales es el punto de partida perfecto para conocer San José del Guaviare y lo mejor de Guaviare.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: selva y pozos naturales. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping tranquilo en Pozos Naturales' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Descubre San José del Guaviare desde una casa moderna en Pozos Naturales, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: pinturas rupestres y selva. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa moderna en Pozos Naturales' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta cabaña acogedora está ubicada en Centro, uno de los sectores más agradables de San José del Guaviare, Guaviare.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: pozos naturales y Puerta de Orión. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña acogedora en Centro' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Este glamping elegante está ubicado en Puerta de Orión, uno de los sectores más agradables de San José del Guaviare, Guaviare.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: Puerta de Orión y pozos naturales. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping elegante en Puerta de Orión' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Esta casa tradicional está ubicada en Puerta de Orión, uno de los sectores más agradables de San José del Guaviare, Guaviare.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: pozos naturales y pinturas rupestres. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa tradicional en Puerta de Orión' AND ciudad = 'San José del Guaviare';
UPDATE publicacion SET descripcion = 'Descubre Mitú desde una cabaña encantadora en Centro, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: río Vaupés y raudales. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña encantadora en Centro' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Descubre Mitú desde una habitación tradicional en Río Vaupés, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: selva profunda y cultura indígena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tradicional en Río Vaupés' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'En Río Vaupés, Mitú, te espera un glamping acogedor con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: río Vaupés y cultura indígena. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping acogedor en Río Vaupés' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Descubre Mitú desde una cabaña tranquila en Cerro Urania, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: raudales y cultura indígena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña tranquila en Cerro Urania' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Descubre Mitú desde una habitación acogedora en Centro, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: raudales y río Vaupés. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación acogedora en Centro' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'En Cerro Urania, Mitú, te espera un glamping espacioso con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: río Vaupés y cultura indígena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping espacioso en Cerro Urania' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'En Raudal de Yuruparí, Mitú, te espera una cabaña acogedora con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: río Vaupés y cultura indígena. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña acogedora en Raudal de Yuruparí' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Descubre Mitú desde una habitación sencilla en Río Vaupés, ideal para descansar después de un día de paseo.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: selva profunda y cultura indígena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación sencilla en Río Vaupés' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'En Río Vaupés, Mitú, te espera un glamping luminoso con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: río Vaupés y raudales. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping luminoso en Río Vaupés' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Esta cabaña fresca en Río Vaupés es el punto de partida perfecto para conocer Mitú y lo mejor de Vaupés.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: río Vaupés y selva profunda. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña fresca en Río Vaupés' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Descubre Mitú desde una habitación luminosa en Cerro Urania, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: raudales y río Vaupés. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Cerro Urania' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Este glamping fresco en Río Vaupés es el punto de partida perfecto para conocer Mitú y lo mejor de Vaupés.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: río Vaupés y raudales. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping fresco en Río Vaupés' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Descubre Mitú desde una cabaña encantadora en Cerro Urania, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: río Vaupés y cultura indígena. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña encantadora en Cerro Urania' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'En Cerro Urania, Mitú, te espera una habitación elegante con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: raudales y selva profunda. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación elegante en Cerro Urania' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Descubre Mitú desde un glamping luminoso en Centro, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: raudales y río Vaupés. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping luminoso en Centro' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'En Centro, Mitú, te espera una cabaña tradicional con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: río Vaupés y raudales. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña tradicional en Centro' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'En Raudal de Yuruparí, Mitú, te espera una habitación sencilla con todo lo necesario para una estadía tranquila.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: río Vaupés y cultura indígena. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación sencilla en Raudal de Yuruparí' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Descubre Mitú desde un glamping espacioso en Río Vaupés, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: selva profunda y raudales. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping espacioso en Río Vaupés' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Descubre Mitú desde una cabaña tranquila en Río Vaupés, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: cultura indígena y selva profunda. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña tranquila en Río Vaupés' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Esta habitación tranquila en Río Vaupés es el punto de partida perfecto para conocer Mitú y lo mejor de Vaupés.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: raudales y selva profunda. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación tranquila en Río Vaupés' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'En Centro, Mitú, te espera un glamping romántico con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: cultura indígena y raudales. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping romántico en Centro' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'En Cerro Urania, Mitú, te espera una cabaña acogedora con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: raudales y río Vaupés. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña acogedora en Cerro Urania' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Esta habitación romántica en Raudal de Yuruparí es el punto de partida perfecto para conocer Mitú y lo mejor de Vaupés.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: raudales y río Vaupés. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación romántica en Raudal de Yuruparí' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'En Centro, Mitú, te espera un glamping acogedor con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: selva profunda y raudales. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping acogedor en Centro' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Esta cabaña familiar está ubicada en Río Vaupés, uno de los sectores más agradables de Mitú, Vaupés.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: cultura indígena y raudales. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña familiar en Río Vaupés' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Esta habitación espaciosa está ubicada en Centro, uno de los sectores más agradables de Mitú, Vaupés.

Es una habitación privada con cama sencilla, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: raudales y selva profunda. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación espaciosa en Centro' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'En Cerro Urania, Mitú, te espera un glamping encantador con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: río Vaupés y selva profunda. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping encantador en Cerro Urania' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Esta cabaña elegante en Río Vaupés es el punto de partida perfecto para conocer Mitú y lo mejor de Vaupés.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: cultura indígena y selva profunda. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña elegante en Río Vaupés' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Esta habitación moderna está ubicada en Río Vaupés, uno de los sectores más agradables de Mitú, Vaupés.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: río Vaupés y raudales. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación moderna en Río Vaupés' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'Este glamping luminoso en Cerro Urania es el punto de partida perfecto para conocer Mitú y lo mejor de Vaupés.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: cultura indígena y selva profunda. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping luminoso en Cerro Urania' AND ciudad = 'Mitú';
UPDATE publicacion SET descripcion = 'En Centro, Florencia, te espera una casa elegante con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: biodiversidad y ríos cristalinos. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa elegante en Centro' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'En Centro, Florencia, te espera un apartamento espacioso con todo lo necesario para una estadía tranquila.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: biodiversidad y puerta de la Amazonía. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento espacioso en Centro' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Esta cabaña exclusiva en Vereda El Caraño es el punto de partida perfecto para conocer Florencia y lo mejor de Caquetá.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: piscina y biodiversidad. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña exclusiva en Vereda El Caraño' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'En Vereda El Caraño, Florencia, te espera una finca elegante con todo lo necesario para una estadía tranquila.

La finca tiene 4 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 10 personas.

Lo mejor del entorno: ríos cristalinos y piscina. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Finca elegante en Vereda El Caraño' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Descubre Florencia desde una casa familiar en Vereda El Caraño, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: ríos cristalinos y biodiversidad. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa familiar en Vereda El Caraño' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'En Vía a Neiva, Florencia, te espera un apartamento sencillo con todo lo necesario para una estadía tranquila.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: ríos cristalinos y puerta de la Amazonía. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento sencillo en Vía a Neiva' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'En Vereda El Caraño, Florencia, te espera una cabaña espaciosa con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: puerta de la Amazonía y ríos cristalinos. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña espaciosa en Vereda El Caraño' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Esta finca espaciosa está ubicada en Centro, uno de los sectores más agradables de Florencia, Caquetá.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 14 personas.

Lo mejor del entorno: puerta de la Amazonía y ríos cristalinos. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca espaciosa en Centro' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Esta casa sencilla en Centro es el punto de partida perfecto para conocer Florencia y lo mejor de Caquetá.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: ríos cristalinos y biodiversidad. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa sencilla en Centro' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Descubre Florencia desde un apartamento tranquilo en Río Hacha, ideal para descansar después de un día de paseo.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: biodiversidad y puerta de la Amazonía. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento tranquilo en Río Hacha' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Descubre Florencia desde una cabaña espaciosa en Centro, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: ríos cristalinos y puerta de la Amazonía. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña espaciosa en Centro' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Esta finca encantadora está ubicada en Centro, uno de los sectores más agradables de Florencia, Caquetá.

La finca tiene 7 habitaciones, 4 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 16 personas.

Lo mejor del entorno: piscina y puerta de la Amazonía. Ideal para familias y grupos de amigos.', habitaciones = 7, banos = 4 WHERE titulo = 'Finca encantadora en Centro' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'En Vereda El Caraño, Florencia, te espera una casa espaciosa con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: biodiversidad y puerta de la Amazonía. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa espaciosa en Vereda El Caraño' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'En Vía a Neiva, Florencia, te espera un apartamento fresco con todo lo necesario para una estadía tranquila.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina y ríos cristalinos. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento fresco en Vía a Neiva' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'En Vereda El Caraño, Florencia, te espera una cabaña tradicional con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: biodiversidad y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña tradicional en Vereda El Caraño' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'En Centro, Florencia, te espera una finca romántica con todo lo necesario para una estadía tranquila.

La finca tiene 3 habitaciones, 2 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 6 personas.

Lo mejor del entorno: ríos cristalinos y piscina. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Finca romántica en Centro' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Esta casa luminosa está ubicada en Vereda El Caraño, uno de los sectores más agradables de Florencia, Caquetá.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 9 personas, wifi y parqueadero.

Lo mejor del entorno: puerta de la Amazonía y biodiversidad. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa luminosa en Vereda El Caraño' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Este apartamento tradicional está ubicado en Vía a Neiva, uno de los sectores más agradables de Florencia, Caquetá.

Tiene 1 habitación, 1 baño, sala-comedor y cocina equipada. Recibe hasta 2 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: puerta de la Amazonía y piscina. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Apartamento tradicional en Vía a Neiva' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Descubre Florencia desde una cabaña acogedora en Vía a Neiva, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: puerta de la Amazonía y biodiversidad. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña acogedora en Vía a Neiva' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Descubre Florencia desde una finca moderna en Vereda El Caraño, ideal para descansar después de un día de paseo.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: piscina y biodiversidad. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca moderna en Vereda El Caraño' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'En Vía a Neiva, Florencia, te espera una casa exclusiva con todo lo necesario para una estadía tranquila.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: puerta de la Amazonía y ríos cristalinos. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa exclusiva en Vía a Neiva' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Este apartamento luminoso en Río Hacha es el punto de partida perfecto para conocer Florencia y lo mejor de Caquetá.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 4 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: biodiversidad y piscina. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento luminoso en Río Hacha' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Esta cabaña luminosa en Centro es el punto de partida perfecto para conocer Florencia y lo mejor de Caquetá.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 5 personas.

Lo mejor del entorno: ríos cristalinos y puerta de la Amazonía. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña luminosa en Centro' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'En Centro, Florencia, te espera una finca colorida con todo lo necesario para una estadía tranquila.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 13 personas.

Lo mejor del entorno: puerta de la Amazonía y ríos cristalinos. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca colorida en Centro' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Esta casa exclusiva está ubicada en Vereda El Caraño, uno de los sectores más agradables de Florencia, Caquetá.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: piscina y biodiversidad. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa exclusiva en Vereda El Caraño' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Descubre Florencia desde un apartamento rústico en Centro, ideal para descansar después de un día de paseo.

Tiene 2 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 3 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina y biodiversidad. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento rústico en Centro' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Esta cabaña fresca en Vereda El Caraño es el punto de partida perfecto para conocer Florencia y lo mejor de Caquetá.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: piscina y puerta de la Amazonía. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña fresca en Vereda El Caraño' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Descubre Florencia desde una finca acogedora en Río Hacha, ideal para descansar después de un día de paseo.

La finca tiene 6 habitaciones, 3 baños, cocina grande, zonas verdes y kiosco con BBQ. Ideal para grupos de hasta 15 personas.

Lo mejor del entorno: biodiversidad y ríos cristalinos. Ideal para familias y grupos de amigos.', habitaciones = 6, banos = 3 WHERE titulo = 'Finca acogedora en Río Hacha' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Esta casa elegante está ubicada en Río Hacha, uno de los sectores más agradables de Florencia, Caquetá.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: ríos cristalinos y puerta de la Amazonía. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa elegante en Río Hacha' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Este apartamento encantador está ubicado en Vía a Neiva, uno de los sectores más agradables de Florencia, Caquetá.

Tiene 3 habitaciones, 2 baños, sala-comedor y cocina equipada. Recibe hasta 5 personas e incluye wifi, TV y ropa de cama.

Lo mejor del entorno: piscina y ríos cristalinos. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Apartamento encantador en Vía a Neiva' AND ciudad = 'Florencia';
UPDATE publicacion SET descripcion = 'Esta cabaña encantadora está ubicada en Centro, uno de los sectores más agradables de Mocoa, Putumayo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 4 personas.

Lo mejor del entorno: cascada Fin del Mundo y avistamiento de aves. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña encantadora en Centro' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Este glamping tradicional está ubicado en Vía a Villagarzón, uno de los sectores más agradables de Mocoa, Putumayo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: senderos en la selva y avistamiento de aves. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping tradicional en Vía a Villagarzón' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'En Ojo de Dios, Mocoa, te espera una casa familiar con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: cascada Fin del Mundo y avistamiento de aves. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa familiar en Ojo de Dios' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'En Vía a Villagarzón, Mocoa, te espera una cabaña luminosa con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: senderos en la selva y cascada Fin del Mundo. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña luminosa en Vía a Villagarzón' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Este glamping elegante está ubicado en Vía a Villagarzón, uno de los sectores más agradables de Mocoa, Putumayo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: senderos en la selva y cascada Fin del Mundo. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping elegante en Vía a Villagarzón' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'En Vía a Villagarzón, Mocoa, te espera una casa romántica con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: cascada Fin del Mundo y avistamiento de aves. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa romántica en Vía a Villagarzón' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Descubre Mocoa desde una cabaña familiar en Fin del Mundo, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: río Mocoa y cascada Fin del Mundo. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña familiar en Fin del Mundo' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Este glamping tradicional en Ojo de Dios es el punto de partida perfecto para conocer Mocoa y lo mejor de Putumayo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: avistamiento de aves y cascada Fin del Mundo. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping tradicional en Ojo de Dios' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'En Vía a Villagarzón, Mocoa, te espera una casa tranquila con todo lo necesario para una estadía tranquila.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: senderos en la selva y río Mocoa. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa tranquila en Vía a Villagarzón' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Descubre Mocoa desde una cabaña encantadora en Vía a Villagarzón, ideal para descansar después de un día de paseo.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: senderos en la selva y río Mocoa. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña encantadora en Vía a Villagarzón' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Descubre Mocoa desde un glamping espacioso en Ojo de Dios, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: senderos en la selva y avistamiento de aves. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping espacioso en Ojo de Dios' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'En Ojo de Dios, Mocoa, te espera una casa romántica con todo lo necesario para una estadía tranquila.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 6 personas, wifi y parqueadero.

Lo mejor del entorno: avistamiento de aves y río Mocoa. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa romántica en Ojo de Dios' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Esta cabaña tranquila en Ojo de Dios es el punto de partida perfecto para conocer Mocoa y lo mejor de Putumayo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: senderos en la selva y cascada Fin del Mundo. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña tranquila en Ojo de Dios' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Descubre Mocoa desde un glamping elegante en Ojo de Dios, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: avistamiento de aves y senderos en la selva. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping elegante en Ojo de Dios' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Descubre Mocoa desde una casa exclusiva en Ojo de Dios, ideal para descansar después de un día de paseo.

La casa tiene 5 habitaciones, 3 baños, cocina completa, sala amplia y patio. Hay espacio para 10 personas, wifi y parqueadero.

Lo mejor del entorno: río Mocoa y senderos en la selva. Ideal para familias y grupos de amigos.', habitaciones = 5, banos = 3 WHERE titulo = 'Casa exclusiva en Ojo de Dios' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Esta cabaña acogedora está ubicada en Fin del Mundo, uno de los sectores más agradables de Mocoa, Putumayo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: senderos en la selva y cascada Fin del Mundo. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña acogedora en Fin del Mundo' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Descubre Mocoa desde un glamping acogedor en Vía a Villagarzón, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: senderos en la selva y avistamiento de aves. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping acogedor en Vía a Villagarzón' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Descubre Mocoa desde una casa colorida en Vía a Villagarzón, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: cascada Fin del Mundo y avistamiento de aves. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa colorida en Vía a Villagarzón' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Esta cabaña colorida en Ojo de Dios es el punto de partida perfecto para conocer Mocoa y lo mejor de Putumayo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: senderos en la selva y cascada Fin del Mundo. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña colorida en Ojo de Dios' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Este glamping fresco está ubicado en Vía a Villagarzón, uno de los sectores más agradables de Mocoa, Putumayo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: senderos en la selva y río Mocoa. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping fresco en Vía a Villagarzón' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Esta casa fresca está ubicada en Vía a Villagarzón, uno de los sectores más agradables de Mocoa, Putumayo.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: río Mocoa y cascada Fin del Mundo. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa fresca en Vía a Villagarzón' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Descubre Mocoa desde una cabaña sencilla en Fin del Mundo, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: río Mocoa y cascada Fin del Mundo. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña sencilla en Fin del Mundo' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'En Fin del Mundo, Mocoa, te espera un glamping familiar con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: cascada Fin del Mundo y senderos en la selva. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping familiar en Fin del Mundo' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Esta casa acogedora en Vía a Villagarzón es el punto de partida perfecto para conocer Mocoa y lo mejor de Putumayo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: cascada Fin del Mundo y senderos en la selva. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa acogedora en Vía a Villagarzón' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'En Ojo de Dios, Mocoa, te espera una cabaña espaciosa con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 4 habitaciones, 2 baños, cocineta y terraza para disfrutar el paisaje. Recibe hasta 8 personas.

Lo mejor del entorno: río Mocoa y senderos en la selva. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Cabaña espaciosa en Ojo de Dios' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Este glamping sencillo está ubicado en Fin del Mundo, uno de los sectores más agradables de Mocoa, Putumayo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: avistamiento de aves y cascada Fin del Mundo. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping sencillo en Fin del Mundo' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Esta casa moderna está ubicada en Centro, uno de los sectores más agradables de Mocoa, Putumayo.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: cascada Fin del Mundo y senderos en la selva. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa moderna en Centro' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'En Centro, Mocoa, te espera una cabaña moderna con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: senderos en la selva y avistamiento de aves. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña moderna en Centro' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Este glamping luminoso en Ojo de Dios es el punto de partida perfecto para conocer Mocoa y lo mejor de Putumayo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: senderos en la selva y avistamiento de aves. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping luminoso en Ojo de Dios' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Esta casa familiar en Vía a Villagarzón es el punto de partida perfecto para conocer Mocoa y lo mejor de Putumayo.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: río Mocoa y avistamiento de aves. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa familiar en Vía a Villagarzón' AND ciudad = 'Mocoa';
UPDATE publicacion SET descripcion = 'Descubre Leticia desde una cabaña luminosa en Kilómetro 11, ideal para descansar después de un día de paseo.

La cabaña cuenta con 1 habitación, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 2 personas.

Lo mejor del entorno: río Amazonas y selva amazónica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Cabaña luminosa en Kilómetro 11' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Descubre Leticia desde un glamping encantador en Kilómetro 11, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: delfines rosados y río Amazonas. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping encantador en Kilómetro 11' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta habitación luminosa está ubicada en Isla de los Micos, uno de los sectores más agradables de Leticia, Amazonas.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: comunidades indígenas y delfines rosados. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Isla de los Micos' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta casa encantadora está ubicada en Kilómetro 11, uno de los sectores más agradables de Leticia, Amazonas.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 8 personas, wifi y parqueadero.

Lo mejor del entorno: río Amazonas y delfines rosados. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa encantadora en Kilómetro 11' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta cabaña tranquila está ubicada en Isla de los Micos, uno de los sectores más agradables de Leticia, Amazonas.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: comunidades indígenas y delfines rosados. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña tranquila en Isla de los Micos' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Este glamping fresco en Kilómetro 11 es el punto de partida perfecto para conocer Leticia y lo mejor de Amazonas.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: delfines rosados y río Amazonas. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping fresco en Kilómetro 11' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Descubre Leticia desde una habitación luminosa en Tabatinga, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: delfines rosados y río Amazonas. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Tabatinga' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Descubre Leticia desde una casa sencilla en Isla de los Micos, ideal para descansar después de un día de paseo.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: delfines rosados y río Amazonas. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa sencilla en Isla de los Micos' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta cabaña tranquila está ubicada en Tabatinga, uno de los sectores más agradables de Leticia, Amazonas.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: selva amazónica y comunidades indígenas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña tranquila en Tabatinga' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Este glamping exclusivo está ubicado en Malecón, uno de los sectores más agradables de Leticia, Amazonas.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: delfines rosados y río Amazonas. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping exclusivo en Malecón' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta habitación fresca está ubicada en Isla de los Micos, uno de los sectores más agradables de Leticia, Amazonas.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: selva amazónica y delfines rosados. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación fresca en Isla de los Micos' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Descubre Leticia desde una casa espaciosa en Puerto Nariño, ideal para descansar después de un día de paseo.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: río Amazonas y delfines rosados. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa espaciosa en Puerto Nariño' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Descubre Leticia desde una cabaña romántica en Puerto Nariño, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: selva amazónica y delfines rosados. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña romántica en Puerto Nariño' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Este glamping encantador en Puerto Nariño es el punto de partida perfecto para conocer Leticia y lo mejor de Amazonas.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: delfines rosados y selva amazónica. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping encantador en Puerto Nariño' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Descubre Leticia desde una habitación rústica en Malecón, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño compartido y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: río Amazonas y selva amazónica. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación rústica en Malecón' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta casa elegante en Malecón es el punto de partida perfecto para conocer Leticia y lo mejor de Amazonas.

La casa tiene 2 habitaciones, 1 baño, cocina completa, sala amplia y patio. Hay espacio para 4 personas, wifi y parqueadero.

Lo mejor del entorno: comunidades indígenas y selva amazónica. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Casa elegante en Malecón' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Descubre Leticia desde una cabaña rústica en Tabatinga, ideal para descansar después de un día de paseo.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 6 personas.

Lo mejor del entorno: selva amazónica y río Amazonas. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña rústica en Tabatinga' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'En Malecón, Leticia, te espera un glamping tradicional con todo lo necesario para una estadía tranquila.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 3 personas y es perfecto para desconectarse.

Lo mejor del entorno: selva amazónica y delfines rosados. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping tradicional en Malecón' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta habitación elegante está ubicada en Kilómetro 11, uno de los sectores más agradables de Leticia, Amazonas.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: río Amazonas y delfines rosados. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación elegante en Kilómetro 11' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta casa elegante está ubicada en Kilómetro 11, uno de los sectores más agradables de Leticia, Amazonas.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: selva amazónica y río Amazonas. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa elegante en Kilómetro 11' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta cabaña encantadora en Isla de los Micos es el punto de partida perfecto para conocer Leticia y lo mejor de Amazonas.

La cabaña cuenta con 3 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 7 personas.

Lo mejor del entorno: selva amazónica y delfines rosados. Ideal para familias y grupos de amigos.', habitaciones = 3, banos = 1 WHERE titulo = 'Cabaña encantadora en Isla de los Micos' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Este glamping luminoso está ubicado en Tabatinga, uno de los sectores más agradables de Leticia, Amazonas.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: río Amazonas y delfines rosados. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping luminoso en Tabatinga' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta habitación luminosa en Malecón es el punto de partida perfecto para conocer Leticia y lo mejor de Amazonas.

Es una habitación privada con cama sencilla, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: comunidades indígenas y delfines rosados. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación luminosa en Malecón' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta casa encantadora en Puerto Nariño es el punto de partida perfecto para conocer Leticia y lo mejor de Amazonas.

La casa tiene 4 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 7 personas, wifi y parqueadero.

Lo mejor del entorno: comunidades indígenas y río Amazonas. Ideal para familias y grupos de amigos.', habitaciones = 4, banos = 2 WHERE titulo = 'Casa encantadora en Puerto Nariño' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta cabaña fresca está ubicada en Malecón, uno de los sectores más agradables de Leticia, Amazonas.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: río Amazonas y selva amazónica. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña fresca en Malecón' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Este glamping exclusivo en Tabatinga es el punto de partida perfecto para conocer Leticia y lo mejor de Amazonas.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 4 personas y es perfecto para desconectarse.

Lo mejor del entorno: selva amazónica y comunidades indígenas. Ideal para parejas y familias pequeñas.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping exclusivo en Tabatinga' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Descubre Leticia desde una habitación familiar en Malecón, ideal para descansar después de un día de paseo.

Es una habitación privada con cama doble, baño privado y acceso a las zonas comunes. Incluye wifi, toallas y ropa de cama.

Lo mejor del entorno: selva amazónica y comunidades indígenas. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Habitación familiar en Malecón' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Esta casa rústica está ubicada en Tabatinga, uno de los sectores más agradables de Leticia, Amazonas.

La casa tiene 3 habitaciones, 2 baños, cocina completa, sala amplia y patio. Hay espacio para 5 personas, wifi y parqueadero.

Lo mejor del entorno: selva amazónica y delfines rosados. Ideal para parejas y familias pequeñas.', habitaciones = 3, banos = 2 WHERE titulo = 'Casa rústica en Tabatinga' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'En Tabatinga, Leticia, te espera una cabaña luminosa con todo lo necesario para una estadía tranquila.

La cabaña cuenta con 2 habitaciones, 1 baño, cocineta y terraza para disfrutar el paisaje. Recibe hasta 3 personas.

Lo mejor del entorno: río Amazonas y selva amazónica. Ideal para parejas y familias pequeñas.', habitaciones = 2, banos = 1 WHERE titulo = 'Cabaña luminosa en Tabatinga' AND ciudad = 'Leticia';
UPDATE publicacion SET descripcion = 'Descubre Leticia desde un glamping exclusivo en Puerto Nariño, ideal para descansar después de un día de paseo.

El domo tiene cama doble, baño privado con agua caliente y terraza con vista. Recibe hasta 2 personas y es perfecto para desconectarse.

Lo mejor del entorno: río Amazonas y comunidades indígenas. Ideal para parejas o viajeros que van solos.', habitaciones = 1, banos = 1 WHERE titulo = 'Glamping exclusivo en Puerto Nariño' AND ciudad = 'Leticia';

-- Habitaciones y baños de los 4 alojamientos de 04_datos_prueba.sql
UPDATE publicacion SET habitaciones = 3, banos = 2 WHERE titulo = 'Cabaña frente al lago';
UPDATE publicacion SET habitaciones = 4, banos = 3 WHERE titulo = 'Villa frente al mar';
UPDATE publicacion SET habitaciones = 2, banos = 2 WHERE titulo = 'Apartamento con vista a la ciudad';
UPDATE publicacion SET habitaciones = 1, banos = 1 WHERE titulo = 'Glamping en la montaña';

COMMIT;

SELECT tipo, ROUND(AVG(habitaciones), 1) AS habitaciones, ROUND(AVG(banos), 1) AS banos
FROM publicacion GROUP BY tipo;
