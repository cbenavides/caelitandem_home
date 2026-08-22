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
-- Secciones: hero|quienes-somos|especialidades|promociones|calidad|ubicacion|privacidad|footer|seo
-- Subsecciones promociones: banner|lunes|martes|miercoles|jueves|viernes|sabado|domingo
-- Subsecciones footer: logo|info|contacto|horarios
-- Subsecciones seo: meta|og|schema
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `web_contenidos` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `seccion`     VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL
                    COMMENT 'hero|quienes-somos|especialidades|promociones|calidad|ubicacion|privacidad|footer|seo',
    `subseccion`  VARCHAR(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                    COMMENT 'slide1..5|ficha1..4|banner|lunes..domingo|logo|info|contacto|meta|og|schema',
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
-- D-08 (nuevo): ayuno_descripcion y tiempo_resultado alimentan las badges
--   de las catalog-card-day (Lunes–Domingo) en index.php y el autocomplete
--   del portal médico (input-buscar-estudio-ficha / medicos.php).
-- SSOT: clave (ej. HEM-01) es el identificador corto para labadmin y para
--   la referencia en web_contenidos/promociones/{dia}/estudio_clave.
--   muestra_requerida y preparacion_paciente completan el modal-estudio de labadmin.
--   NUNCA duplicar nombre/precio/ayuno/tiempo en web_contenidos — leer desde aquí vía JOIN.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `estudios` (
    `id`                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `nombre`              VARCHAR(200) COLLATE utf8mb4_unicode_ci NOT NULL,
    `categoria`           ENUM('Hematología','Bioquímica','Uroanálisis','Inmunología','Otros') NOT NULL
                            COMMENT 'Categoría interna labadmin — select#estudio-categoria',
    `tipo_web`            ENUM('rutina','check_up') NOT NULL DEFAULT 'rutina'
                            COMMENT 'Agrupación para el sitio web público',
    `precio`              DECIMAL(10,2) DEFAULT NULL
                            COMMENT 'Precio de lista — badge catalog-card-price / D-08',
    `ayuno_descripcion`   VARCHAR(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                            COMMENT 'Ej: "8 hrs ayuno" | "Sin ayuno" — badge catalog-card en index.php',
    `tiempo_resultado`    VARCHAR(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                            COMMENT 'Ej: "Resultado 24 hrs" — badge catalog-card en index.php',
    `clave`               VARCHAR(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                            COMMENT 'Código corto labadmin (ej. HEM-01) — referenciado en web_contenidos/promociones/{dia}/estudio_clave (SSOT)',
    `muestra_requerida`   VARCHAR(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                            COMMENT 'Tipo de muestra biológica (ej. Sangre total — tubo EDTA lila) — labadmin campo estudio-muestra',
    `preparacion_paciente` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL
                            COMMENT 'Instrucciones clínicas completas de preparación para el paciente — labadmin textarea estudio-preparacion',
    `disponible`          TINYINT(1) NOT NULL DEFAULT 1,
    `orden`               SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `creado_en`           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `actualizado_en`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_nombre` (`nombre`),
    UNIQUE KEY `uq_clave`  (`clave`),
    KEY `idx_categoria`  (`categoria`),
    KEY `idx_tipo_web`   (`tipo_web`),
    FULLTEXT KEY `ft_nombre` (`nombre`)
                            COMMENT 'Búsqueda fulltext para autocomplete input-buscar-estudio-ficha'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catálogo de estudios/análisis — categoria (labadmin), tipo_web (sitio), badges, clave SSOT';

-- ---------------------------------------------------------------------------
-- NOTA DE MIGRACIÓN:
-- Columnas precio, ayuno_descripcion, tiempo_resultado → D-08 (ya en CREATE TABLE).
-- Columnas clave, muestra_requerida, preparacion_paciente → SSOT (añadidas aquí).
-- Si upgradeando desde v1 sin DROP DATABASE, ejecutar manualmente:
--   ALTER TABLE estudios
--     ADD COLUMN IF NOT EXISTS precio DECIMAL(10,2) DEFAULT NULL AFTER tipo_web,
--     ADD COLUMN IF NOT EXISTS ayuno_descripcion VARCHAR(60) DEFAULT NULL AFTER precio,
--     ADD COLUMN IF NOT EXISTS tiempo_resultado VARCHAR(60) DEFAULT NULL AFTER ayuno_descripcion,
--     ADD COLUMN IF NOT EXISTS clave VARCHAR(30) DEFAULT NULL UNIQUE AFTER tiempo_resultado,
--     ADD COLUMN IF NOT EXISTS muestra_requerida VARCHAR(120) DEFAULT NULL AFTER clave,
--     ADD COLUMN IF NOT EXISTS preparacion_paciente TEXT DEFAULT NULL AFTER muestra_requerida;
-- ---------------------------------------------------------------------------
