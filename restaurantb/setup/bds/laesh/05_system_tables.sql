-- =============================================================================
-- LAESH Bloc Digital — Script 05: Tablas de Sistema (Logs y Trazabilidad)
-- Tablas: SYS_LOGS, FALLBACK_LOG
-- Idempotente: CREATE TABLE IF NOT EXISTS.
-- =============================================================================

USE `laesh_db`;

-- ---------------------------------------------------------------------------
-- SYS_LOGS — Log operativo PSR-3 con purga automática
-- Retención: INFO/DEBUG > 30 días eliminados por Event Scheduler.
-- WARN/ERROR/CRITICAL: retención indefinida.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sys_logs` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `nivel`      ENUM('DEBUG','INFO','WARN','ERROR','CRITICAL') NOT NULL DEFAULT 'INFO',
    `evento`     VARCHAR(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Slug del evento (ej: password_reset_by_admin)',
    `mensaje`    TEXT COLLATE utf8mb4_unicode_ci NOT NULL,
    `contexto`   JSON DEFAULT NULL COMMENT 'Datos adicionales: user_id, admin_id, ip, etc.',
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `creado_en`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_nivel`   (`nivel`),
    KEY `idx_evento`  (`evento`),
    KEY `idx_creado`  (`creado_en`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Log operativo PSR-3 — purga auto de INFO/DEBUG >30 días via Event Scheduler';

-- Event Scheduler: purga de logs de nivel bajo pasados 30 días
-- Requiere que el Event Scheduler esté habilitado (SET GLOBAL event_scheduler = ON).
DROP EVENT IF EXISTS `evt_purga_sys_logs`;
CREATE EVENT IF NOT EXISTS `evt_purga_sys_logs`
    ON SCHEDULE EVERY 1 DAY
    STARTS CURRENT_TIMESTAMP
    DO
        DELETE FROM `sys_logs`
        WHERE `nivel` IN ('DEBUG','INFO')
          AND `creado_en` < NOW() - INTERVAL 30 DAY;

-- ---------------------------------------------------------------------------
-- FALLBACK_LOG — Log técnico de errores PHP/SQL (retención indefinida)
-- Registra errores que requieren revisión manual — no se purgan.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fallback_log` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `nivel`      ENUM('ERROR','CRITICAL') NOT NULL DEFAULT 'ERROR',
    `contexto`   VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Operación que falló',
    `mensaje`    TEXT COLLATE utf8mb4_unicode_ci NOT NULL,
    `stack_trace` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `creado_en`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_creado` (`creado_en`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Log técnico de errores SQL/PHP — retención indefinida, revisión manual requerida';
