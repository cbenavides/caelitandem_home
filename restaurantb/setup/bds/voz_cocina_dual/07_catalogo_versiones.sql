USE `vcd01`;

CREATE TABLE IF NOT EXISTS `catalogo_versiones` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `version_label` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
    `descripcion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `delta_hash` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
    `json_data` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
    `sinonimos_cantidades` text COLLATE utf8mb4_unicode_ci NOT NULL,
    `umbral_levenshtein_largo` int(10) unsigned NOT NULL DEFAULT 3,
    `umbral_levenshtein_corto` int(10) unsigned NOT NULL DEFAULT 1,
    `publicado` tinyint(1) NOT NULL DEFAULT 0,
    `creado_por` int(10) unsigned NOT NULL,
    `creado_en` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_cat_version_user` FOREIGN KEY (`creado_por`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- La versión semilla v2.0.0 será generada dinámicamente por la API al no haber versiones publicadas.
-- El administrador debe acceder al panel "Gestión de Catálogo" y presionar "Publicar Versión" para persistirla.
