-- ==============================================================================
-- 10_catalogos_estaticos.sql
-- Descripción: Tablas estructurales para el motor de generación SSOT de JS.
-- Proyecto: LAESH
-- ==============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. Tabla de Categorías (Grupos)
CREATE TABLE IF NOT EXISTS `cat_categorias` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `nombre` VARCHAR(255) NOT NULL,
  `orden` INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Tabla de Gabinetes
CREATE TABLE IF NOT EXISTS `cat_gabinetes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `nombre` VARCHAR(255) NOT NULL,
  `orden` INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Tabla Principal de Estudios
CREATE TABLE IF NOT EXISTS `cat_estudios` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `clave` VARCHAR(50) DEFAULT NULL,
  `nombre` VARCHAR(255) NOT NULL,
  `muestra` VARCHAR(150) DEFAULT NULL,
  `contenedor` VARCHAR(150) DEFAULT NULL,
  `tiempo` VARCHAR(100) DEFAULT NULL,
  `categoria_id` INT DEFAULT NULL,
  `preparacion` TEXT DEFAULT NULL,
  `pruebas_incluidas` TEXT DEFAULT NULL,
  `top20_orden` INT DEFAULT NULL COMMENT '1-20 si pertenece al Top 20 Est.Med',
  
  -- Tracking de auditoría básico
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  CONSTRAINT `fk_estudio_categoria` FOREIGN KEY (`categoria_id`) REFERENCES `cat_categorias`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Tabla de Versión Global (Cache Busting)
CREATE TABLE IF NOT EXISTS `sys_catalog_version` (
  `id` INT PRIMARY KEY,
  `version_hash` BIGINT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================================
-- TABLAS DE GABINETES Y VINCULACIONES (AGREGADO POST-ANALISIS)
-- =========================================================================

CREATE TABLE IF NOT EXISTS `cat_subgabinetes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `gabinete_id` INT NOT NULL,
  `nombre` VARCHAR(150) NOT NULL,
  `orden` INT DEFAULT 0,
  FOREIGN KEY (`gabinete_id`) REFERENCES `cat_gabinetes`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cat_igabinetes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `nombre` VARCHAR(150) NOT NULL,
  `orden` INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vinculaciones: Estudio -> Gabinete/Subgabinete
CREATE TABLE IF NOT EXISTS `rel_estudio_gabinete` (
  `estudio_id` INT NOT NULL,
  `gabinete_id` INT NULL,
  `subgabinete_id` INT NULL,
  FOREIGN KEY (`estudio_id`) REFERENCES `cat_estudios`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`gabinete_id`) REFERENCES `cat_gabinetes`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`subgabinete_id`) REFERENCES `cat_subgabinetes`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vinculaciones: I.Gabinete -> Gabinete/Subgabinete
CREATE TABLE IF NOT EXISTS `rel_igabinete_vinculos` (
  `igabinete_id` INT NOT NULL,
  `gabinete_id` INT NULL,
  `subgabinete_id` INT NULL,
  FOREIGN KEY (`igabinete_id`) REFERENCES `cat_igabinetes`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`gabinete_id`) REFERENCES `cat_gabinetes`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`subgabinete_id`) REFERENCES `cat_subgabinetes`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar semilla inicial de versión
INSERT IGNORE INTO `sys_catalog_version` (`id`, `version_hash`) VALUES (1, UNIX_TIMESTAMP());

SET FOREIGN_KEY_CHECKS = 1;
