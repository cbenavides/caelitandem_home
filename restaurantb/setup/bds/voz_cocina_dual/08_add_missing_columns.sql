USE `vcd01`;

-- 1. Agregar columnas si no existen
ALTER TABLE `comandas` 
ADD COLUMN IF NOT EXISTS `numero_personas` int(10) unsigned NOT NULL DEFAULT 1 AFTER `hora_captura`,
ADD COLUMN IF NOT EXISTS `metodo_captura` ENUM('voz', 'teclado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'voz' AFTER `numero_personas`;

-- 2. Insertar nuevos cocineros en users
INSERT IGNORE INTO `users` (`id`, `email`, `password`, `username`, `status`, `verified`, `roles_mask`, `registered`) VALUES 
(5, 'cocinero1@restaurante.local', '$2y$10$tsS1AB26s6vlww0m6wWe5.oFbhvC9kcw9Z9C0h5dJZDj47Lez1/hO', 'Cocinero 1', 0, 1, 0, UNIX_TIMESTAMP()),
(6, 'cocinero2@restaurante.local', '$2y$10$wy4xw/CJv3ELGlcek4gg7eWHuy0SEj/fJvXP8Wx0zGhc.WMK.BZrm', 'Cocinero 2', 0, 1, 0, UNIX_TIMESTAMP()),
(7, 'cocinero3@restaurante.local', '$2y$10$xgzEbwa/Gr/zH36M7Y/0n.nZgk/DwzgALayV4KT1bqRVt0rbD3Veu', 'Cocinero 3', 0, 1, 0, UNIX_TIMESTAMP());

-- 3. Insertar nuevos empleados
INSERT IGNORE INTO `empleados` (`user_id`, `nombre_completo`, `rol`, `pin`, `diadema_id`) VALUES 
(5, 'Cocinero Uno', 'cocinero', '3001', 'BT-COC-02'),
(6, 'Cocinero Dos', 'cocinero', '3002', 'BT-COC-03'),
(7, 'Cocinero Tres', 'cocinero', '3003', 'BT-COC-04');

-- 4. Asignar permisos RBAC
INSERT IGNORE INTO `rbac_permisos_usuarios` (`user_id`, `permiso_id`) VALUES 
(5, 1), 
(6, 1), 
(7, 1);
