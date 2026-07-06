USE `vcd01`;

CREATE TABLE IF NOT EXISTS `mesas` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `numero` int(10) unsigned NOT NULL,
    `capacidad` int(10) unsigned NOT NULL DEFAULT 4,
    `activa` tinyint(1) NOT NULL DEFAULT 1,
    `creado_en` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `idx_mesa_numero` (`numero`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `categorias` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
    `orden` int(10) unsigned NOT NULL DEFAULT 0,
    `activa` tinyint(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `productos` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `categoria_id` int(10) unsigned NOT NULL,
    `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `descripcion` text COLLATE utf8mb4_unicode_ci,
    `precio` decimal(10,2) NOT NULL DEFAULT 0.00,
    `precio_orden` decimal(10,2) DEFAULT NULL,
    `cantidad_orden` tinyint(3) unsigned DEFAULT NULL,
    `codigo` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `disponible` tinyint(1) NOT NULL DEFAULT 1,
    `palabras_clave` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
    `sinonimos_json` text COLLATE utf8mb4_unicode_ci,
    `image_emoji` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT '🍽️',
    `creado_en` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `actualizado_en` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_producto_categoria` FOREIGN KEY (`categoria_id`) REFERENCES `categorias` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
