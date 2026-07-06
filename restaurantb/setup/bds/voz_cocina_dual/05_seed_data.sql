USE `vcd01`;

-- Insert admin user (password is '1234' hashed)
INSERT IGNORE INTO `users` (`id`, `email`, `password`, `username`, `status`, `verified`, `roles_mask`, `registered`) 
VALUES (1, 'admin@restaurante.local', '$2y$10$0Ws1IqHLUs0t0fWb7pgrFeavk2rJUO44NC0VuERGbC0tEcRmXbJ0m', 'Administrador', 0, 1, 1, UNIX_TIMESTAMP());

INSERT IGNORE INTO `empleados` (`user_id`, `nombre_completo`, `rol`, `pin`, `diadema_id`) 
VALUES (1, 'Administrador del Sistema', 'administrador', '1234', 'SYS-001');

-- Meseros (password is '2222' hashed)
INSERT IGNORE INTO `users` (`id`, `email`, `password`, `username`, `status`, `verified`, `roles_mask`, `registered`) 
VALUES (2, 'juan@restaurante.local', '$2y$10$nt79vyE5A8rtrXaDmWCJNOy8JTXD9mokjwZXbn9cPDeDegU8je3oy', 'Juan Mesero', 0, 1, 0, UNIX_TIMESTAMP());
INSERT IGNORE INTO `empleados` (`user_id`, `nombre_completo`, `rol`, `pin`, `diadema_id`) 
VALUES (2, 'Juan Pérez', 'mesero', '2222', 'BT-MES-01');

-- Cocineros (password is '3333' hashed)
INSERT IGNORE INTO `users` (`id`, `email`, `password`, `username`, `status`, `verified`, `roles_mask`, `registered`) 
VALUES (3, 'pedro@restaurante.local', '$2y$10$yx.FLSjY21Bd2PFXU0RifuJbEKph1NNIv1yU0FmAoCziI6RhwxXQC', 'Pedro Chef', 0, 1, 0, UNIX_TIMESTAMP());
INSERT IGNORE INTO `empleados` (`user_id`, `nombre_completo`, `rol`, `pin`, `diadema_id`) 
VALUES (3, 'Pedro Cocinero', 'cocinero', '3333', 'BT-COC-01');

INSERT IGNORE INTO `users` (`id`, `email`, `password`, `username`, `status`, `verified`, `roles_mask`, `registered`) 
VALUES (5, 'cocinero1@restaurante.local', '$2y$10$tsS1AB26s6vlww0m6wWe5.oFbhvC9kcw9Z9C0h5dJZDj47Lez1/hO', 'Cocinero 1', 0, 1, 0, UNIX_TIMESTAMP());
INSERT IGNORE INTO `empleados` (`user_id`, `nombre_completo`, `rol`, `pin`, `diadema_id`) 
VALUES (5, 'Cocinero Uno', 'cocinero', '3001', 'BT-COC-02');

INSERT IGNORE INTO `users` (`id`, `email`, `password`, `username`, `status`, `verified`, `roles_mask`, `registered`) 
VALUES (6, 'cocinero2@restaurante.local', '$2y$10$wy4xw/CJv3ELGlcek4gg7eWHuy0SEj/fJvXP8Wx0zGhc.WMK.BZrm', 'Cocinero 2', 0, 1, 0, UNIX_TIMESTAMP());
INSERT IGNORE INTO `empleados` (`user_id`, `nombre_completo`, `rol`, `pin`, `diadema_id`) 
VALUES (6, 'Cocinero Dos', 'cocinero', '3002', 'BT-COC-03');

INSERT IGNORE INTO `users` (`id`, `email`, `password`, `username`, `status`, `verified`, `roles_mask`, `registered`) 
VALUES (7, 'cocinero3@restaurante.local', '$2y$10$xgzEbwa/Gr/zH36M7Y/0n.nZgk/DwzgALayV4KT1bqRVt0rbD3Veu', 'Cocinero 3', 0, 1, 0, UNIX_TIMESTAMP());
INSERT IGNORE INTO `empleados` (`user_id`, `nombre_completo`, `rol`, `pin`, `diadema_id`) 
VALUES (7, 'Cocinero Tres', 'cocinero', '3003', 'BT-COC-04');

-- Cajeros (password is '4444' hashed)
INSERT IGNORE INTO `users` (`id`, `email`, `password`, `username`, `status`, `verified`, `roles_mask`, `registered`) 
VALUES (4, 'maria@restaurante.local', '$2y$10$GdTP2qXf9oH23qbo1ga9PepEOxl.lBiHZfWgZw716mlrvtZi7oLAG', 'Maria Caja', 0, 1, 0, UNIX_TIMESTAMP());
INSERT IGNORE INTO `empleados` (`user_id`, `nombre_completo`, `rol`, `pin`, `diadema_id`) 
VALUES (4, 'Maria Cajera', 'cajero', '4444', 'BT-CAJA-01');

-- RBAC Permisos Base
INSERT IGNORE INTO `rbac_permisos` (`id`, `nombre`, `descripcion`) VALUES 
(1, 'ver_kds', 'Permite ver la pantalla de comandas en cocina'),
(2, 'tomar_ordenes', 'Permite abrir mesas y tomar ordenes (mesero)'),
(3, 'cobrar_mesas', 'Permite cerrar mesas y cobrar'),
(4, 'gestionar_menu', 'Permite administrar versiones del catálogo'),
(5, 'ver_reportes', 'Permite ver corte de caja e historial');

-- Asignar Permisos (RBAC Verification Seed)
-- Admin (todos)
INSERT IGNORE INTO `rbac_permisos_usuarios` (`user_id`, `permiso_id`) VALUES (1, 1), (1, 2), (1, 3), (1, 4), (1, 5);
-- Mesero (tomar ordenes)
INSERT IGNORE INTO `rbac_permisos_usuarios` (`user_id`, `permiso_id`) VALUES (2, 2);
-- Cocinero (ver KDS)
INSERT IGNORE INTO `rbac_permisos_usuarios` (`user_id`, `permiso_id`) VALUES (3, 1), (5, 1), (6, 1), (7, 1);
-- Cajera (cobrar, ver reportes)
INSERT IGNORE INTO `rbac_permisos_usuarios` (`user_id`, `permiso_id`) VALUES (4, 3), (4, 5);

-- Mesas
INSERT IGNORE INTO `mesas` (`numero`, `capacidad`) VALUES (1, 2), (2, 4), (3, 4), (4, 6), (5, 4);

-- Categorías
INSERT IGNORE INTO `categorias` (`id`, `nombre`, `orden`) VALUES 
(1, 'Bebidas', 1),
(2, 'Tacos Tradicionales', 2),
(3, 'Especialidades y Alambres', 3),
(4, 'Entradas y Acompañamientos', 4);

-- Productos con catálogo expandido (55 productos NLP)
INSERT IGNORE INTO `productos` (`id`, `categoria_id`, `nombre`, `precio`, `precio_orden`, `cantidad_orden`, `palabras_clave`, `sinonimos_json`) VALUES 
-- Tacos Tradicionales
(1, 2, 'Taco Al Pastor', 35.00, 160.00, 5, 'taco pastor tacos pastor trompo al pastor', '["Trompo"]'),
(2, 2, 'Taco de Tripa', 35.00, 170.00, 5, 'taco tripa tacos tripa tripitas taco arto taco arta tripa', '["Tripitas"]'),
(3, 2, 'Taco de Suadero', 35.00, 170.00, 5, 'taco suadero tacos suadero suadero', '[]'),
(4, 2, 'Taco de Bistec', 35.00, 165.00, 5, 'taco bistec tacos bistec asada bistec', '[]'),
(5, 2, 'Taco Campechano', 40.00, 190.00, 5, 'taco campechano tacos campechano mixto campechano', '["Mixto"]'),
(6, 2, 'Taco de Cabeza', 33.00, 155.00, 5, 'taco cabeza tacos cabeza cabeza', '[]'),
(7, 2, 'Taco de Lengua', 45.00, 210.00, 5, 'taco lengua tacos lengua lengua', '[]'),
(8, 2, 'Taco de Cachete', 42.00, 195.00, 5, 'taco cachete tacos cachete cachete', '[]'),
(9, 2, 'Taco de Costilla', 38.00, 175.00, 5, 'taco costilla tacos costilla costilla', '[]'),
(10, 2, 'Taco de Chorizo', 34.00, 160.00, 5, 'taco chorizo tacos chorizo chorizo', '[]'),
(11, 2, 'Taco de Longaniza', 35.00, 170.00, 5, 'taco longaniza tacos longaniza longaniza', '[]'),
(12, 2, 'Taco de Barbacoa', 37.00, 175.00, 5, 'taco barbacoa tacos barbacoa barbacoa', '[]'),
(13, 2, 'Taco de Arrachera', 46.00, 215.00, 5, 'taco arrachera tacos arrachera arrachera', '[]'),
(14, 2, 'Taco Alambre', 42.00, 200.00, 5, 'taco alambre tacos alambre alambre', '[]'),
(15, 2, 'Taco Adobada', 34.00, 160.00, 5, 'taco adobada tacos adobada adobada', '[]'),

-- Especialidades
(16, 3, 'Gringa de Pastor', 105.00, NULL, NULL, 'gringa gringas gringa pastor gringas pastor', '[]'),
(17, 3, 'Consome de Barbacoa', 35.00, NULL, NULL, 'consome caldo consome barbacoa caldito', '["Caldito"]'),

-- Refrescos
(20, 1, 'Coca-Cola (600ml)', 20.00, NULL, NULL, 'coca coca cola refresco cocacola chesco 600 600ml pequena chica', '["Coca", "Chesco"]'),
(21, 1, 'Coca-Cola (1L)', 32.00, NULL, NULL, 'coca cola litro un litro 1l coca litro', '[]'),
(22, 1, 'Coca-Cola (2L)', 42.00, NULL, NULL, 'coca cola dos litros 2l dos litros', '[]'),
(23, 1, 'Coca-Cola (Familiar 3L)', 55.00, NULL, NULL, 'coca familiar tres litros 3l familiar', '[]'),
(24, 1, 'Pepsi (600ml)', 19.00, NULL, NULL, 'pepsi refresco pepsi 600', '[]'),
(25, 1, 'Pepsi (1L)', 30.00, NULL, NULL, 'pepsi litro pepsi 1l', '[]'),
(26, 1, 'Sprite (600ml)', 18.00, NULL, NULL, 'sprite limon sprite refresco', '[]'),
(27, 1, 'Fanta Naranja (600ml)', 18.00, NULL, NULL, 'fanta naranja fanta', '[]'),
(28, 1, 'Fanta Fresa (600ml)', 18.00, NULL, NULL, 'fanta fresa fanta rosa', '[]'),
(29, 1, 'Manzanita Sol (600ml)', 18.00, NULL, NULL, 'manzanita manzana sidral', '[]'),
(30, 1, 'Sidral Mundet (600ml)', 19.00, NULL, NULL, 'sidral mundet manzana verde', '[]'),
(31, 1, 'Jarritos Tamarindo (600ml)', 20.00, NULL, NULL, 'jarritos tamarindo jarrito', '[]'),
(32, 1, 'Jarritos Piña (600ml)', 20.00, NULL, NULL, 'jarritos pina jarrito pina', '[]'),
(33, 1, 'Jarritos Mandarina (600ml)', 20.00, NULL, NULL, 'jarritos mandarina jarrito mandarina', '[]'),
(34, 1, 'Jarritos Guayaba (600ml)', 20.00, NULL, NULL, 'jarritos guayaba jarrito guayaba', '[]'),
(35, 1, 'Jarritos Sandía (600ml)', 20.00, NULL, NULL, 'jarritos sandia jarrito sandia', '[]'),

-- Aguas Frescas
(40, 1, 'Horchata (Vaso 500ml)', 25.00, NULL, NULL, 'agua horchata horchata vaso', '[]'),
(41, 1, 'Horchata (Jarra 1L)', 48.00, NULL, NULL, 'agua horchata jarra horchata jarra', '[]'),
(42, 1, 'Jamaica (Vaso)', 25.00, NULL, NULL, 'agua jamaica jamaica vaso', '[]'),
(43, 1, 'Jamaica (Jarra)', 48.00, NULL, NULL, 'agua jamaica jarra jamaica jarra', '[]'),
(44, 1, 'Limón (Vaso)', 24.00, NULL, NULL, 'agua limon limon vaso', '[]'),
(45, 1, 'Mango (Vaso)', 27.00, NULL, NULL, 'agua mango mango vaso', '[]'),
(46, 1, 'Guayaba (Vaso)', 25.00, NULL, NULL, 'agua guayaba guayaba vaso', '[]'),
(47, 1, 'Tamarindo (Vaso)', 25.00, NULL, NULL, 'agua tamarindo tamarindo vaso', '[]'),
(48, 1, 'Piña (Vaso)', 26.00, NULL, NULL, 'agua pina pina vaso', '[]'),
(49, 1, 'Tepache (Vaso)', 30.00, NULL, NULL, 'agua tepache tepache pina fermentado', '[]'),

-- Cervezas
(50, 1, 'Corona (355ml)', 38.00, NULL, NULL, 'corona coronita cerveza corona', '["Coronita"]'),
(51, 1, 'Modelo Especial', 40.00, NULL, NULL, 'modelo modelito cerveza modelo especial', '["Modelito"]'),
(52, 1, 'Pacifico', 39.00, NULL, NULL, 'pacifico cerveza pacifico', '[]'),
(53, 1, 'Indio', 38.00, NULL, NULL, 'indio cerveza indio', '[]'),
(54, 1, 'Victoria', 37.00, NULL, NULL, 'victoria vicky cerveza victoria', '["Vicky"]');
