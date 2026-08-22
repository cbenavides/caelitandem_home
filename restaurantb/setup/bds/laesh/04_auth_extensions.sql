-- =============================================================================
-- LAESH Bloc Digital — Script 04: Extensiones de Auth y RBAC
-- Tablas: EMPLEADOS, PERFILES_MEDICOS, RBAC_PERMISOS, RBAC_PERMISOS_USUARIOS
-- Depende de: 01_auth_schema.sql (tabla users debe existir).
-- Idempotente: CREATE TABLE IF NOT EXISTS.
--
-- Redesign v2 — alineado con Tecnica_Modelo_Datos.html:
--   • perfiles_medicos: user_id como PK/FK directa a users.id (era empleado_id FK empleados.id)
--   • perfiles_medicos: + celular, telefono_consultorio, direccion_consultorio
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
    KEY `idx_rol` (`rol`),
    CONSTRAINT `fk_emp_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Extensión de users para personal LAESH — rol operativo y estado activo';

-- ---------------------------------------------------------------------------
-- PERFILES_MEDICOS — Perfil extendido exclusivo para médicos
-- D-03: universidad_id y lugar_trabajo_id son FK → catalogos_ui (no VARCHAR).
-- D-05: estado_id FK → cat_estados_medico (Activo/Pausado).
-- D-redesign: user_id como PK y FK directa a users.id (simplifica joins).
--             Agregados: celular, telefono_consultorio, direccion_consultorio.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `perfiles_medicos` (
    `user_id`                INT UNSIGNED NOT NULL
                               COMMENT 'PK y FK users.id — un perfil por médico',
    `especialidad`           VARCHAR(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `cedula_profesional`     VARCHAR(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `celular`                VARCHAR(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                               COMMENT 'Teléfono celular del médico (10 dígitos)',
    `telefono_consultorio`   VARCHAR(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                               COMMENT 'Teléfono fijo del consultorio',
    `direccion_consultorio`  VARCHAR(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                               COMMENT 'Dirección del consultorio (mostrada en solicitud digital)',
    `universidad_id`         INT UNSIGNED DEFAULT NULL
                               COMMENT 'FK catalogos_ui.id (tipo=universidad)',
    `lugar_trabajo_id`       INT UNSIGNED DEFAULT NULL
                               COMMENT 'FK catalogos_ui.id (tipo=lugar_trabajo)',
    `estado_id`              TINYINT UNSIGNED NOT NULL DEFAULT 1
                               COMMENT 'FK cat_estados_medico.id (1=Activo, 2=Pausado)',
    `foto_url`               VARCHAR(255) DEFAULT NULL,
    `creado_en`              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `actualizado_en`         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`),
    KEY `idx_universidad`   (`universidad_id`),
    KEY `idx_lugar_trabajo` (`lugar_trabajo_id`),
    KEY `idx_estado`        (`estado_id`),
    CONSTRAINT `fk_pm_user`        FOREIGN KEY (`user_id`)          REFERENCES `users` (`id`),
    CONSTRAINT `fk_pm_universidad` FOREIGN KEY (`universidad_id`)   REFERENCES `catalogos_ui` (`id`),
    CONSTRAINT `fk_pm_lugar`       FOREIGN KEY (`lugar_trabajo_id`) REFERENCES `catalogos_ui` (`id`),
    CONSTRAINT `fk_pm_estado`      FOREIGN KEY (`estado_id`)        REFERENCES `cat_estados_medico` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Perfil extendido de médicos — user_id PK/FK directa, especialidad, cédula, contacto consultorio';

-- ---------------------------------------------------------------------------
-- RBAC_PERMISOS — Catálogo de permisos granulares del sistema
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `rbac_permisos` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `nombre`      VARCHAR(100) COLLATE utf8mb4_unicode_ci NOT NULL
                    COMMENT 'ej: ver_ordenes_propias, gestionar_cms',
    `descripcion` VARCHAR(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catálogo de permisos granulares RBAC';

-- ---------------------------------------------------------------------------
-- RBAC_PERMISOS_USUARIOS — Asignación de permisos a usuarios
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `rbac_permisos_usuarios` (
    `user_id`     INT UNSIGNED NOT NULL COMMENT 'FK users.id (Delight-Auth)',
    `permiso_id`  INT UNSIGNED NOT NULL,
    `otorgado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`, `permiso_id`),
    CONSTRAINT `fk_pu_permiso` FOREIGN KEY (`permiso_id`) REFERENCES `rbac_permisos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Asignación permiso → usuario (granular, independiente del rol de empleados)';
