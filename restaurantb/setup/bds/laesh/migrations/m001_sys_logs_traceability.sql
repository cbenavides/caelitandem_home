-- =============================================================================
-- Migración M001 — sys_logs: columnas de trazabilidad E2E (G3, G4, G5)
-- Aplicar en producción (KVM2) con:
--   sudo mariadb -u root -p'comite_2026' laesh_db < m001_sys_logs_traceability.sql
-- Idempotente: usa IF NOT EXISTS para cada columna (MariaDB 10.4+).
-- Fecha: 2026-09-06
-- =============================================================================

USE `laesh_db`;

-- G3: request_id — correlaciona todos los eventos de un mismo ciclo HTTP
ALTER TABLE `sys_logs`
    ADD COLUMN IF NOT EXISTS `request_id` CHAR(16) DEFAULT NULL
        COMMENT 'G3: ID único por request HTTP (8 bytes hex) — correlaciona eventos del mismo ciclo'
        AFTER `user_id`;

-- G4: url + metodo — contexto HTTP del request que originó el evento
ALTER TABLE `sys_logs`
    ADD COLUMN IF NOT EXISTS `url` VARCHAR(500) DEFAULT NULL
        COMMENT 'G4: REQUEST_URI del request que originó el evento'
        AFTER `request_id`,
    ADD COLUMN IF NOT EXISTS `metodo` VARCHAR(10) DEFAULT NULL
        COMMENT 'G4: Método HTTP (GET, POST…)'
        AFTER `url`;

-- G5: session_id — identifica la sesión del usuario
ALTER TABLE `sys_logs`
    ADD COLUMN IF NOT EXISTS `session_id` CHAR(26) DEFAULT NULL
        COMMENT 'G5: session_id() truncado — identifica la sesión del usuario'
        AFTER `metodo`;

-- Índice para correlación por request_id (consultas de trazabilidad E2E)
ALTER TABLE `sys_logs`
    ADD INDEX IF NOT EXISTS `idx_request_id` (`request_id`);

-- Verificar resultado
DESCRIBE `sys_logs`;
