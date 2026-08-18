-- =============================================================================
-- LAESH Bloc Digital — Script 02: Core Schema
-- Tablas: CONFIGURACIONES, WEB_CONTENIDOS, CATALOGOS_UI, CAT_ESTADOS_MEDICO, ESTUDIOS
-- Idempotente: CREATE TABLE IF NOT EXISTS + INSERT IGNORE.
-- =============================================================================

USE `laesh_db`;

-- ---------------------------------------------------------------------------
-- CONFIGURACIONES — Parámetros globales de instancia (clave → valor)
-- D-04: Links sociales aquí, NO en WEB_CONTENIDOS.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `configuraciones` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `clave`        VARCHAR(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `valor`        TEXT COLLATE utf8mb4_unicode_ci,
    `descripcion`  VARCHAR(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_clave` (`clave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Parámetros globales de la instancia LAESH (singleton por clave)';

-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — Contenido CMS editable por sección del sitio público
-- D-07: Valores canónicos de seccion = data-section de gestion-web.html
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `web_contenidos` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `seccion`     VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL
                    COMMENT 'hero|quienes-somos|especialidades|promociones|calidad|ubicacion|privacidad|seo',
    `subseccion`  VARCHAR(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                    COMMENT 'slide1|slide2|ficha1|ficha2... según sección',
    `clave`       VARCHAR(100) COLLATE utf8mb4_unicode_ci NOT NULL
                    COMMENT 'titulo|descripcion|texto|imagen_url|etiqueta',
    `valor`       MEDIUMTEXT COLLATE utf8mb4_unicode_ci,
    `tipo`        ENUM('texto','imagen_url','html','json') NOT NULL DEFAULT 'texto',
    `actualizado_por` INT UNSIGNED DEFAULT NULL COMMENT 'FK users.id',
    `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_sec_subsec_clave` (`seccion`, `subseccion`, `clave`),
    KEY `idx_seccion` (`seccion`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Contenido editable del sitio web LAESH por sección CMS';

-- ---------------------------------------------------------------------------
-- CATALOGOS_UI — Catálogos polimórficos para selects dinámicos
-- D-03: universidad_id y lugar_trabajo_id son FK → aquí, no VARCHAR libre.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `catalogos_ui` (
    `id`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tipo`   VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL
               COMMENT 'universidad|lugar_trabajo — discriminador de tipo',
    `valor`  VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL,
    `orden`  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `activo` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `idx_tipo_activo` (`tipo`, `activo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catálogos polimórficos para selects dinámicos de UI (universidad, lugar_trabajo)';

-- ---------------------------------------------------------------------------
-- CAT_ESTADOS_MEDICO — Estado operativo del médico (Activo / Pausado)
-- D-05: No reemplaza empleados.activo TINYINT para personal no-médico.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `cat_estados_medico` (
    `id`          TINYINT UNSIGNED NOT NULL,
    `nombre`      VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL,
    `descripcion` VARCHAR(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catálogo de estados del médico: 1=Activo, 2=Pausado';

-- ---------------------------------------------------------------------------
-- ESTUDIOS — Catálogo maestro de análisis del laboratorio
-- D-02: Dos dimensiones de categoría independientes (categoria + tipo_web).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `estudios` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `nombre`      VARCHAR(200) COLLATE utf8mb4_unicode_ci NOT NULL,
    `categoria`   ENUM('Hematología','Bioquímica','Uroanálisis','Inmunología','Otros') NOT NULL
                    COMMENT 'Categoría interna labadmin — select#estudio-categoria',
    `tipo_web`    ENUM('rutina','check_up') NOT NULL DEFAULT 'rutina'
                    COMMENT 'Agrupación para el sitio web público',
    `precio`      DECIMAL(10,2) DEFAULT NULL COMMENT 'UI-G01: no expuesto en grilla labadmin v1',
    `disponible`  TINYINT(1) NOT NULL DEFAULT 1,
    `orden`       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `creado_en`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_nombre` (`nombre`),
    KEY `idx_categoria` (`categoria`),
    KEY `idx_tipo_web`  (`tipo_web`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catálogo de estudios/análisis — dimensiones: categoria (labadmin) y tipo_web (sitio)';
