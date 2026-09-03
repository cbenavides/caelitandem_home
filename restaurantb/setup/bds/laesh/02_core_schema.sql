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
-- CATALOGOS RELACIONALES — Estructura normalizada de Catálogos y Promociones
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `catalogo_grupos` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `clave` VARCHAR(10) UNIQUE NOT NULL,
  `titulo` VARCHAR(255) NOT NULL,
  `orden` INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `catalogo_categorias` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `grupo_id` INT UNSIGNED NOT NULL,
  `nombre` VARCHAR(255) NOT NULL,
  `orden` INT DEFAULT 0,
  FOREIGN KEY (`grupo_id`) REFERENCES `catalogo_grupos`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `catalogo_estudios` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `categoria_id` INT UNSIGNED NOT NULL,
  `clave_interna` VARCHAR(20) NOT NULL,
  `nombre` VARCHAR(255) NOT NULL,
  `tiempo_procesamiento` VARCHAR(100) DEFAULT '',
  `muestra_requerida` VARCHAR(255) DEFAULT '',
  `preparacion` VARCHAR(255) DEFAULT '',
  `detalle` TEXT,
  `precio` DECIMAL(10,2) DEFAULT 0.00,
  `activo` TINYINT(1) DEFAULT 1,
  FOREIGN KEY (`categoria_id`) REFERENCES `catalogo_categorias`(`id`) ON DELETE CASCADE,
  FULLTEXT KEY `ft_nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `catalogo_promociones` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `estudio_id` INT UNSIGNED DEFAULT NULL,
  `dia_semana` VARCHAR(255) NOT NULL,
  `nombre_oferta` VARCHAR(255) NOT NULL,
  `subtitulo` VARCHAR(255) DEFAULT '',
  `descripcion` TEXT DEFAULT NULL,
  `ayuno` VARCHAR(255) DEFAULT NULL,
  `tiempo_entrega` VARCHAR(255) DEFAULT NULL,
  `precio_regular` DECIMAL(10,2) DEFAULT NULL,
  `precio_oferta` DECIMAL(10,2) DEFAULT NULL,
  `imagen_fondo` VARCHAR(255) DEFAULT NULL,
  `activo` TINYINT(1) DEFAULT 1,
  `orden` INT DEFAULT 0,
  `creado_en` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`estudio_id`) REFERENCES `catalogo_estudios`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
