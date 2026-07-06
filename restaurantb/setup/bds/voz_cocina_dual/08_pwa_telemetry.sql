USE `vcd01`;
 
-- 8. Telemetria y Estado de Red PWA
CREATE TABLE IF NOT EXISTS `pwa_estado_red` (
    `user_id` int(10) unsigned NOT NULL,
    `ultimo_ping` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`),
    CONSTRAINT `fk_pwa_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pwa_historial_offline` (
    `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
    `user_id` int(10) unsigned NOT NULL,
    `fecha_dia` date NOT NULL,
    `inicio_offline` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `fin_offline` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_historial_pwa_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
