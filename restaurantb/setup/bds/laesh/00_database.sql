-- =============================================================================
-- LAESH Bloc Digital — Script 00: Base de Datos y Usuario
-- Idempotente: puede ejecutarse múltiples veces sin error.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS `laesh_db`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Usuario de aplicación (ajustar contraseña antes de producción)
CREATE USER IF NOT EXISTS 'laesh_app'@'%' IDENTIFIED BY 'laesh_2026_dev';
GRANT ALL PRIVILEGES ON `laesh_db`.* TO 'laesh_app'@'%';
FLUSH PRIVILEGES;
