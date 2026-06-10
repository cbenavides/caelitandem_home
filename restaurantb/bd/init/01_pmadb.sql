-- ============================================================
--  01_pmadb.sql — Inicialización de la BD de phpMyAdmin
--  Se ejecuta automáticamente en el primer arranque de MariaDB
--  (directorio docker-entrypoint-initdb.d)
--
--  Crea el usuario 'pma' y la base de datos 'phpmyadmin'
--  Las tablas de configuración (pma__*) las crea phpMyAdmin
--  automáticamente al primer acceso si la pmadb está vacía.
-- ============================================================

-- Usuario de control phpMyAdmin (acceso limitado a pmadb)
CREATE USER IF NOT EXISTS 'pma'@'%' IDENTIFIED BY 'pma_pass_2026';

-- Base de datos de configuración phpMyAdmin
CREATE DATABASE IF NOT EXISTS `phpmyadmin`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Permisos del usuario pma
GRANT ALL PRIVILEGES ON `phpmyadmin`.* TO 'pma'@'%';

-- phpMyAdmin también necesita SELECT en mysql para mostrar usuarios
GRANT SELECT ON `mysql`.* TO 'pma'@'%';

FLUSH PRIVILEGES;
