-- =============================================================================
-- LAESH Bloc Digital — Script 00: Base de Datos y Usuario
-- NOTA: DROP DATABASE incluido para redesign limpio en entorno de desarrollo.
--       Comentar las dos líneas DROP antes de deploy a producción OCI.
-- =============================================================================

-- ── Redesign limpio (dev) ─────────────────────────────────────────────────────
DROP DATABASE IF EXISTS `laesh_db`;

CREATE DATABASE IF NOT EXISTS `laesh_db`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Usuario de aplicación (ajustar contraseña antes de producción)
CREATE USER IF NOT EXISTS 'laesh_app'@'%' IDENTIFIED BY 'laesh_2026_dev';
GRANT ALL PRIVILEGES ON `laesh_db`.* TO 'laesh_app'@'%';
FLUSH PRIVILEGES;
