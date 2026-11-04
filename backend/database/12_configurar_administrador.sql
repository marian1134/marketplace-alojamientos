-- Ejecutar SOLO después de registrar una cuenta dedicada de tipo HUESPED.
-- Reemplaza NULL por su correo entre comillas simples, por ejemplo:
-- SET @correo_admin = 'mi-cuenta-administrativa@gmail.com';
-- No conviertas tu cuenta de anfitrión ni la de huésped que usas para las pruebas.
USE marketplace;
SET @correo_admin = NULL;

UPDATE usuario
SET rol = 'ADMINISTRADOR'
WHERE email = @correo_admin
  AND rol = 'HUESPED'
  AND estado = 'ACTIVA';

SELECT ROW_COUNT() AS cuentas_convertidas;
SELECT id, nombre, email, rol, estado
FROM usuario
WHERE email = @correo_admin;
-- Cierra la sesión de esa cuenta y vuelve a iniciarla para renovar sus permisos.
