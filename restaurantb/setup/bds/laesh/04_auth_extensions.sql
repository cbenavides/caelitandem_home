-- =============================================================================
-- LAESH Bloc Digital — Script 04: Extensiones de Auth y RBAC
-- Tablas: EMPLEADOS, PERFILES_MEDICOS, RBAC_PERMISOS, RBAC_PERMISOS_USUARIOS
-- Depende de: 01_auth_schema.sql (tabla users debe existir).
-- Idempotente: CREATE TABLE IF NOT EXISTS.
-- =============================================================================

USE `laesh_db`;

-- ---------------------------------------------------------------------------
-- EMPLEADOS — Extensión del perfil operativo para personal LAESH
-- Roles: MEDICO | RECEPCION | ADMIN
-- empleados.activo TINYINT permanece para personal no-médico (ver D-05).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `empleados` (
    `id`        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`   INT UNSIGNED NOT NULL COMMENT 'FK users.id (Delight-Auth)',
    `nombre`    VARCHAR(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `apellidos` VARCHAR(200) COLLATE utf8mb4_unicode_ci NOT NULL,
    `rol`       ENUM('MEDICO','RECEPCION','ADMIN') NOT NULL,
    `activo`    TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Boolean simple para recepción/admin (D-05)',
    `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_user_id` (`user_id`),
    KEY `idx_rol` (`rol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Extensión de users para personal LAESH — rol operativo y estado activo';

-- ---------------------------------------------------------------------------
-- PERFILES_MEDICOS — Perfil extendido exclusivo para médicos
-- D-03: universidad_id y lugar_trabajo_id son FK → catalogos_ui (no VARCHAR).
-- D-05: estado_id FK → cat_estados_medico (Activo/Pausado).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `perfiles_medicos` (
    `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `empleado_id`      INT UNSIGNED NOT NULL COMMENT 'FK empleados.id',
    `especialidad`     VARCHAR(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `cedula_profesional` VARCHAR(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `universidad_id`   INT UNSIGNED DEFAULT NULL COMMENT 'FK catalogos_ui.id (tipo=universidad)',
    `lugar_trabajo_id` INT UNSIGNED DEFAULT NULL COMMENT 'FK catalogos_ui.id (tipo=lugar_trabajo)',
    `estado_id`        TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'FK cat_estados_medico.id',
    `foto_url`         VARCHAR(255) DEFAULT NULL,
    `creado_en`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `actualizado_en`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_empleado` (`empleado_id`),
    KEY `idx_universidad`   (`universidad_id`),
    KEY `idx_lugar_trabajo` (`lugar_trabajo_id`),
    KEY `idx_estado`        (`estado_id`),
    CONSTRAINT `fk_pm_empleado`    FOREIGN KEY (`empleado_id`)      REFERENCES `empleados` (`id`),
    CONSTRAINT `fk_pm_universidad` FOREIGN KEY (`universidad_id`)   REFERENCES `catalogos_ui` (`id`),
    CONSTRAINT `fk_pm_lugar`       FOREIGN KEY (`lugar_trabajo_id`) REFERENCES `catalogos_ui` (`id`),
    CONSTRAINT `fk_pm_estado`      FOREIGN KEY (`estado_id`)        REFERENCES `cat_estados_medico` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Perfil extendido de médicos — especialidad, cédula, universidad (FK), estado (FK)';

-- ---------------------------------------------------------------------------
-- RBAC_PERMISOS — Catálogo de permisos granulares del sistema
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `rbac_permisos` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `nombre`      VARCHAR(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ej: ver_ordenes_propias, gestionar_cms',
    `descripcion` VARCHAR(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catálogo de permisos granulares RBAC';

-- ---------------------------------------------------------------------------
-- RBAC_PERMISOS_USUARIOS — Asignación de permisos a usuarios
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `rbac_permisos_usuarios` (
    `user_id`    INT UNSIGNED NOT NULL COMMENT 'FK users.id (Delight-Auth)',
    `permiso_id` INT UNSIGNED NOT NULL,
    `otorgado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`, `permiso_id`),
    CONSTRAINT `fk_pu_permiso` FOREIGN KEY (`permiso_id`) REFERENCES `rbac_permisos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Asignación permiso → usuario (granular, independiente del rol de empleados)';
