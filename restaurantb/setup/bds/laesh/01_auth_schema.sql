-- =============================================================================
-- LAESH Bloc Digital — Script 01: Schema Delight-Auth (PHP-Auth)
-- Tablas: users, users_remembered, users_throttling, users_confirmations,
--         users_resets, users_audit_log, users_2fa
--
-- IMPORTANTE: DDL derivado del código fuente de la versión instalada en
--   restaurant/commons/libs/auth/Delight/Auth/
-- NO usar $auth->install() — ese método no existe en esta versión.
-- Idempotente: CREATE TABLE IF NOT EXISTS.
-- =============================================================================

USE `laesh_db`;

-- ---------------------------------------------------------------------------
-- USERS — Tabla principal de autenticación
-- R15.5: email = {10digits}@laesh.local | username = teléfono
-- R14.9: verified=1 para usuarios creados por admin (sin email verification)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
    `id`           INT(10)      UNSIGNED NOT NULL AUTO_INCREMENT,
    `email`        VARCHAR(249) COLLATE utf8mb4_unicode_ci NOT NULL,
    `password`     VARCHAR(255) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
    `username`     VARCHAR(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `status`       TINYINT(4)   UNSIGNED NOT NULL DEFAULT 0,
    `verified`     TINYINT(1)   UNSIGNED NOT NULL DEFAULT 0,
    `resettable`   TINYINT(1)   UNSIGNED NOT NULL DEFAULT 1,
    `roles_mask`   INT(10)      UNSIGNED NOT NULL DEFAULT 0,
    `registered`   INT(10)      UNSIGNED NOT NULL,
    `last_login`   INT(10)      UNSIGNED DEFAULT NULL,
    `force_logout` MEDIUMINT(7) UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Autenticación Delight-Auth — R15.5: email virtual {tel}@laesh.local';

-- ---------------------------------------------------------------------------
-- USERS_REMEMBERED — Tokens de sesión persistente ("recordarme")
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users_remembered` (
    `id`       BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
    `user`     INT(10)    UNSIGNED NOT NULL,
    `selector` VARCHAR(24)  CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    `token`    VARCHAR(200) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    `expires`  INT(10)    UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `selector` (`selector`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- USERS_THROTTLING — Rate-limiting por bucket de acción + IP
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users_throttling` (
    `bucket`         VARCHAR(255) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    `tokens`         FLOAT        UNSIGNED NOT NULL,
    `replenished_at` INT(10)      UNSIGNED NOT NULL,
    `expires_at`     INT(10)      UNSIGNED NOT NULL,
    PRIMARY KEY (`bucket`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- USERS_CONFIRMATIONS — Tokens de verificación de email
-- R14.9: Bypaseada — admin crea usuarios con verified=1 directamente.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users_confirmations` (
    `id`       INT(10)      UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`  INT(10)      UNSIGNED NOT NULL,
    `email`    VARCHAR(249) COLLATE utf8mb4_unicode_ci NOT NULL,
    `selector` VARCHAR(24)  CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    `token`    VARCHAR(200) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    `expires`  INT(10)      UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `selector` (`selector`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- USERS_RESETS — Tokens de restablecimiento de contraseña
-- R14.8: La tabla existe pero LAESH no genera filas (no hay reset por email).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users_resets` (
    `id`       BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
    `user`     INT(10)    UNSIGNED NOT NULL,
    `selector` VARCHAR(24)  CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    `token`    VARCHAR(200) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    `expires`  INT(10)      UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `selector` (`selector`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- USERS_AUDIT_LOG — Auditoría de eventos de autenticación
-- Columnas exactas según Auth.php::logEvent() de esta versión de la librería.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users_audit_log` (
    `id`           BIGINT(20)   UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`      INT(10)      UNSIGNED NOT NULL,
    `event_at`     INT(10)      UNSIGNED NOT NULL,
    `event_type`   VARCHAR(64)  COLLATE utf8mb4_unicode_ci NOT NULL,
    `admin_id`     INT(10)      UNSIGNED DEFAULT NULL,
    `ip_address`   VARCHAR(45)  COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `user_agent`   VARCHAR(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `details_json` MEDIUMTEXT   COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Auditoría Delight-Auth — event_at, event_type, admin_id, ip_address, user_agent';

-- ---------------------------------------------------------------------------
-- USERS_2FA — Configuración de segundo factor (TOTP / SMS / Email OTP)
-- Columnas exactas según Auth.php prepareTwoFactor*/enableTwoFactor*.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users_2fa` (
    `id`         BIGINT(20)   UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`    INT(10)      UNSIGNED NOT NULL,
    `mechanism`  TINYINT(4)   UNSIGNED NOT NULL,
    `seed`       VARBINARY(255) NOT NULL,
    `created_at` INT(10)      UNSIGNED NOT NULL,
    `expires_at` INT(10)      UNSIGNED DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `user_id_mechanism` (`user_id`, `mechanism`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='2FA seeds Delight-Auth — mecanismo TOTP/SMS/Email según mechanism enum';
