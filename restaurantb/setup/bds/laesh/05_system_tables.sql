-- =============================================================================
-- LAESH Bloc Digital — Script 05: Tablas de Sistema (Logs y Trazabilidad)
-- Tablas: SYS_LOGS, FALLBACK_LOG
-- Schemas alineados con Logger.php y DB.php (commons/ — fuente de verdad).
-- Idempotente: CREATE TABLE IF NOT EXISTS.
-- =============================================================================

USE `laesh_db`;

-- Activar Event Scheduler (idempotente — sin efecto si ya está ON).
-- Necesario para que evt_purga_sys_logs corra en segundo plano.
SET GLOBAL event_scheduler = ON;

-- ---------------------------------------------------------------------------
-- SYS_LOGS — Log operativo PSR-3
-- Schema conforme a Logger.php::log() que inserta (2026-09-06 — Gaps G3/G4/G5):
--   level, message, ip_address, user_id,
--   request_id (G3), url + metodo (G4), session_id (G5), created_at
-- Retención diferenciada por nivel:
--   DEBUG / INFO → 30 días | WARN → 90 días | ERROR/FATAL/CRITICAL → indefinido
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sys_logs` (
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `level`      ENUM('DEBUG','INFO','WARN','ERROR','FATAL','CRITICAL') NOT NULL DEFAULT 'INFO',
    `message`    TEXT COLLATE utf8mb4_unicode_ci NOT NULL,
    `ip_address` VARCHAR(45) DEFAULT NULL,
    `user_id`    INT UNSIGNED DEFAULT NULL COMMENT 'FK users.id (nullable — puede ser request no autenticado)',
    `request_id` CHAR(16)     DEFAULT NULL COMMENT 'G3: ID único por request HTTP (8 bytes hex) — correlaciona eventos del mismo ciclo',
    `url`        VARCHAR(500) DEFAULT NULL COMMENT 'G4: REQUEST_URI del request que originó el evento',
    `metodo`     VARCHAR(10)  DEFAULT NULL COMMENT 'G4: Método HTTP (GET, POST…)',
    `session_id` CHAR(26)     DEFAULT NULL COMMENT 'G5: session_id() truncado — identifica la sesión del usuario',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_level`      (`level`),
    KEY `idx_created_at` (`created_at`),
    KEY `idx_request_id` (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Log operativo PSR-3 — purga auto de INFO/DEBUG >30 días via Event Scheduler';

-- Event Scheduler: purga diferenciada por nivel
--   DEBUG / INFO → 30 días
--   WARN         → 90 días (G2: RBAC denials — volumen operativo, no retención crítica)
--   ERROR / FATAL / CRITICAL → indefinido (revisión manual requerida)
DROP EVENT IF EXISTS `evt_purga_sys_logs`;
CREATE EVENT IF NOT EXISTS `evt_purga_sys_logs`
    ON SCHEDULE EVERY 1 DAY
    STARTS CURRENT_TIMESTAMP
    DO
        DELETE FROM `sys_logs`
        WHERE (`level` IN ('DEBUG','INFO') AND `created_at` < NOW() - INTERVAL 30  DAY)
           OR (`level` = 'WARN'           AND `created_at` < NOW() - INTERVAL 90  DAY);

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
