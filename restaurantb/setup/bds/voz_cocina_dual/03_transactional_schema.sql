USE `vcd01`;

CREATE TABLE IF NOT EXISTS `comandas` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `mesa_id` int(10) unsigned NOT NULL,
    `mesero_id` int(10) unsigned NOT NULL,
    `cocinero_id` int(10) unsigned DEFAULT NULL,
    `texto_transcrito` text COLLATE utf8mb4_unicode_ci,
    `total` decimal(10,2) NOT NULL DEFAULT 0.00,
    `estado` ENUM('pendiente', 'en_preparacion', 'listo', 'entregado', 'cobrado', 'cancelado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
    `hora_captura` datetime NOT NULL,
    `creado_en` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `actualizado_en` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_comanda_mesa` FOREIGN KEY (`mesa_id`) REFERENCES `mesas` (`id`),
    CONSTRAINT `fk_comanda_mesero` FOREIGN KEY (`mesero_id`) REFERENCES `users` (`id`),
    CONSTRAINT `fk_comanda_cocinero` FOREIGN KEY (`cocinero_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `detalle_comandas` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `comanda_id` bigint(20) unsigned NOT NULL,
    `producto_id` int(10) unsigned NOT NULL,
    `cantidad` int(10) unsigned NOT NULL DEFAULT 1,
    `precio_unitario` decimal(10,2) NOT NULL,
    `subtotal` decimal(10,2) NOT NULL,
    `estado` ENUM('activo', 'cancelado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'activo',
    `cancelado_por_user_id` int(10) unsigned DEFAULT NULL,
    `cancelado_en` timestamp NULL DEFAULT NULL,
    `notas` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_detalle_comanda` FOREIGN KEY (`comanda_id`) REFERENCES `comandas` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_detalle_producto` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`),
    CONSTRAINT `fk_detalle_cancelado_por` FOREIGN KEY (`cancelado_por_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cancelaciones_pendientes` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `detalle_comanda_id` bigint(20) unsigned NOT NULL,
    `mesero_id` int(10) unsigned NOT NULL,
    `cocinero_id` int(10) unsigned DEFAULT NULL,
    `estado` ENUM('pendiente', 'aprobada', 'rechazada', 'expirada') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
    `creado_en` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `respondido_en` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_canc_detalle` FOREIGN KEY (`detalle_comanda_id`) REFERENCES `detalle_comandas` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_canc_mesero` FOREIGN KEY (`mesero_id`) REFERENCES `users` (`id`),
    CONSTRAINT `fk_canc_cocinero` FOREIGN KEY (`cocinero_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cortes_caja` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `cajero_id` int(10) unsigned NOT NULL,
    `fondo_caja` decimal(10,2) NOT NULL DEFAULT 0.00,
    `total_efectivo_declarado` decimal(10,2) DEFAULT NULL,
    `total_calculado` decimal(10,2) DEFAULT NULL,
    `fecha_apertura` datetime NOT NULL,
    `fecha_cierre` datetime DEFAULT NULL,
    `estado` ENUM('abierto', 'cerrado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'abierto',
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_corte_cajero` FOREIGN KEY (`cajero_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tickets` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `comanda_id` bigint(20) unsigned NOT NULL,
    `corte_id` bigint(20) unsigned DEFAULT NULL,
    `total_pagado` decimal(10,2) NOT NULL,
    `cobrado_por_user_id` int(10) unsigned NOT NULL,
    `fecha_cierre` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_ticket_comanda` FOREIGN KEY (`comanda_id`) REFERENCES `comandas` (`id`),
    CONSTRAINT `fk_ticket_cobrado_por` FOREIGN KEY (`cobrado_por_user_id`) REFERENCES `users` (`id`),
    CONSTRAINT `fk_ticket_corte` FOREIGN KEY (`corte_id`) REFERENCES `cortes_caja` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sys_logs` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `level` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
    `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
    `device_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `correlation_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `timestamp` datetime NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `folios_ticket` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `dummy` tinyint(4) NOT NULL DEFAULT 1,
    `creado_en` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `historial_operaciones` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `comanda_id` bigint(20) unsigned DEFAULT NULL,
    `mesa_id` int(10) unsigned DEFAULT NULL,
    `user_id` int(10) unsigned NOT NULL,
    `tipo_operacion` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
    `detalles` text COLLATE utf8mb4_unicode_ci NOT NULL,
    `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_historial_comanda` FOREIGN KEY (`comanda_id`) REFERENCES `comandas` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_historial_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
