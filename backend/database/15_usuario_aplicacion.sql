-- =====================================================================
-- USUARIO DE MYSQL SOLO PARA LA APLICACIÓN: marketplace
-- Ejecutar UNA vez en cada computador, como root, después de los demás
-- scripts. Es opcional pero recomendado (mínimo privilegio).
--
-- El backend no debería conectarse como root (que puede hacerlo todo).
-- Este usuario solo puede LEER, CREAR, CAMBIAR y BORRAR FILAS de la base
-- marketplace: no puede borrar ni crear tablas, ni ver otras bases, ni
-- crear usuarios. Así, aunque algo fallara en la aplicación, el daño
-- posible queda limitado a los datos.
--
-- Antes de ejecutar: reemplaza NULL por una clave segura entre comillas
-- simples, por ejemplo:  SET @clave_app = 'Una-Clave-Larga-2026!';
-- NO guardes la clave real en este archivo ni la subas a GitHub: después
-- de ejecutarlo, vuelve a dejar NULL.
--
-- Luego el backend se arranca con:
--   DB_USERNAME=stayhub_app   DB_PASSWORD=<la clave que pusiste>
-- Los scripts .sql se siguen ejecutando con root desde Workbench.
-- =====================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET @clave_app = NULL;

-- Si no se cambió la clave, no hace nada
SET @sql = IF(@clave_app IS NULL OR CHAR_LENGTH(@clave_app) < 12,
  'SELECT ''Pon una clave de al menos 12 caracteres en @clave_app'' AS aviso',
  CONCAT('CREATE USER IF NOT EXISTS ''stayhub_app''@''localhost'' IDENTIFIED BY ',
         QUOTE(@clave_app)));
PREPARE paso FROM @sql; EXECUTE paso; DEALLOCATE PREPARE paso;

-- Si el usuario ya existía, le actualiza la clave
SET @sql = IF(@clave_app IS NULL OR CHAR_LENGTH(@clave_app) < 12,
  'SELECT 1',
  CONCAT('ALTER USER ''stayhub_app''@''localhost'' IDENTIFIED BY ', QUOTE(@clave_app)));
PREPARE paso FROM @sql; EXECUTE paso; DEALLOCATE PREPARE paso;

-- Solo manejo de filas en marketplace
SET @sql = IF(@clave_app IS NULL OR CHAR_LENGTH(@clave_app) < 12,
  'SELECT 1',
  'GRANT SELECT, INSERT, UPDATE, DELETE ON marketplace.* TO ''stayhub_app''@''localhost''');
PREPARE paso FROM @sql; EXECUTE paso; DEALLOCATE PREPARE paso;

SET @clave_app = NULL;

-- Permisos que quedaron (si el usuario existe)
SET @sql = IF((SELECT COUNT(*) FROM mysql.user WHERE user = 'stayhub_app' AND host = 'localhost') = 1,
  'SHOW GRANTS FOR ''stayhub_app''@''localhost''',
  'SELECT ''El usuario stayhub_app todavía no existe'' AS aviso');
PREPARE paso FROM @sql; EXECUTE paso; DEALLOCATE PREPARE paso;
