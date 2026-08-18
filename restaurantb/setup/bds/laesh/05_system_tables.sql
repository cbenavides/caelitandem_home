-- =============================================================================
-- LAESH Bloc Digital — Script 05: Tablas de Sistema (Logs y Trazabilidad)
-- Tablas: SYS_LOGS, FALLBACK_LOG
-- Schemas alineados con Logger.php y DB.php (commons/ — fuente de verdad).
-- Idempotente: CREATE TABLE IF NOT EXISTS.
-- =============================================================================

USE `laesh_db`;

-- ---------------------------------------------------------------------------
-- SYS_LOGS — Log operativo PSR-3
-- Schema conforme a Logger.php::log() que inserta:
--   level, message, ip_address, user_id, created_at
-- Retención: INFO/DEBUG > 30 días eliminados por Event Scheduler.
-- WARN/ERROR/CRITICAL: retención indefinida.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sys_logs` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `level`      ENUM('DEBUG','INFO','WARN','ERROR','FATAL','CRITICAL') NOT NULL DEFAULT 'INFO',
    `message`    TEXT COLLATE utf8mb4_unicode_ci NOT NULL,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `user_id`    INT UNSIGNED DEFAULT NULL COMMENT 'FK users.id (nullable — puede ser request no autenticado)',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_level`      (`level`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Log operativo PSR-3 — purga auto de INFO/DEBUG >30 días via Event Scheduler';

-- Event Scheduler: purga de logs de nivel bajo pasados 30 días
DROP EVENT IF EXISTS `evt_purga_sys_logs`;
CREATE EVENT IF NOT EXISTS `evt_purga_sys_logs`
    ON SCHEDULE EVERY 1 DAY
    STARTS CURRENT_TIMESTAMP
    DO
        DELETE FROM `sys_logs`
        WHERE `level` IN ('DEBUG','INFO')
          AND `created_at` < NOW() - INTERVAL 30 DAY;

-- ---------------------------------------------------------------------------
-- FALLBACK_LOG — Log técnico de errores PHP/SQL (retención indefinida)
-- Schema conforme a DB.php::logFallback() que inserta:
--   nivel, origen, funcion, query_type, query_hash, query_text, error_msg, fecha
-- No se purga — revisión manual requerida.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `fallback_log` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `nivel`       ENUM('WARN','ERROR','FALLBACK','CRITICAL') NOT NULL DEFAULT 'ERROR',
    `origen`      VARCHAR(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Archivo:línea del caller',
    `funcion`     VARCHAR(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Clase::método del caller',
    `query_type`  ENUM('SELECT','INSERT','UPDATE','DELETE','CALL','OTHER') DEFAULT 'OTHER',
    `query_hash`  CHAR(8) COLLATE latin1_general_cs DEFAULT NULL COMMENT 'CRC32 de query_text para agrupar repeticiones',
    `query_text`  TEXT COLLATE utf8mb4_unicode_ci COMMENT 'Sentencia SQL fallida',
    `error_msg`   VARCHAR(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Mensaje de error PDO',
    `fecha`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_nivel` (`nivel`),
    KEY `idx_fecha` (`fecha`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Log técnico de errores SQL/PHP — retención indefinida, revisión manual requerida';
