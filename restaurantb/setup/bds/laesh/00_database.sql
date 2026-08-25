-- =============================================================================
-- LAESH Bloc Digital — Script 00: Base de Datos y Usuario
--
-- ENTORNOS:
--   LOCAL (Docker): ejecutar tal cual. DROP limpia el volumen dev.
--   OCI PRODUCCIÓN: usar setup_oci.sh — NO ejecutar este archivo directo.
--                   setup_oci.sh gestiona el DROP de forma controlada y
--                   corrige la contraseña de laesh_app post-creación.
--
-- ⚠️  OCI MANUAL: si ejecutas este script directo en OCI, comenta el DROP
--       y ejecuta después:
--         ALTER USER 'laesh_app'@'%' IDENTIFIED BY 'laesh_oci_app_2026';
-- =============================================================================

-- ── Redesign limpio (dev/OCI controlado) ─────────────────────────────────────
-- OCI manual: comentar la siguiente línea (setup_oci.sh la gestiona con --drop flag)
DROP DATABASE IF EXISTS `laesh_db`;

CREATE DATABASE IF NOT EXISTS `laesh_db`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Usuario de aplicación
-- Contraseña DEV: 'laesh_2026_dev'  (local Docker www.conf)
-- Contraseña OCI: setup_oci.sh ejecuta ALTER USER con 'laesh_oci_app_2026' al final
CREATE USER IF NOT EXISTS 'laesh_app'@'%' IDENTIFIED BY 'laesh_2026_dev';
GRANT ALL PRIVILEGES ON `laesh_db`.* TO 'laesh_app'@'%';
FLUSH PRIVILEGES;
