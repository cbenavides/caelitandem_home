-- Migration m005: DDL de Registro Criptográfico JWT ID (JTI)
-- Permite revocación atómica y sesión segura multi-dispositivo (<0.1ms latencia con OPcache L2)

USE `laesh_db`;

CREATE TABLE IF NOT EXISTS `jwt_jti_registry` (
    `jti`            VARCHAR(36) NOT NULL COMMENT 'UUIDv4 id criptográfico de token',
    `user_id`        INT UNSIGNED NOT NULL COMMENT 'FK users.id (Delight Auth)',
    `role`           VARCHAR(20) NOT NULL COMMENT 'Rol del usuario (MEDICO, RECEPCION, ADMIN)',
    `user_agent`     VARCHAR(255) DEFAULT NULL COMMENT 'User-Agent del navegador cliente',
    `ip_address`     VARCHAR(45) DEFAULT NULL COMMENT 'Dirección IP de emisión',
    `issued_at`      BIGINT UNSIGNED NOT NULL COMMENT 'Timestamp epoch de emisión',
    `expires_at`     BIGINT UNSIGNED NOT NULL COMMENT 'Timestamp epoch de expiración',
    `is_revoked`     TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0=Activo, 1=Revocado',
    `revoked_at`     BIGINT UNSIGNED DEFAULT NULL COMMENT 'Timestamp epoch de revocación',
    `revoked_reason` VARCHAR(100) DEFAULT NULL COMMENT 'Razón de revocación (logout, admin, etc)',
    PRIMARY KEY (`jti`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_expires_at` (`expires_at`),
    KEY `idx_is_revoked` (`is_revoked`),
    CONSTRAINT `fk_jti_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Registro criptográfico de JWT ID (JTI) y revocación atómica multi-dispositivo';
