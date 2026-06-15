USE `vcd01`;

-- Insert admin user (password is 'admin' hashed with default PHP password_hash for Delight)
-- Note: Replace with proper hash in production
INSERT IGNORE INTO `users` (`id`, `email`, `password`, `username`, `status`, `verified`, `roles_mask`, `registered`) 
VALUES (1, 'admin@restaurante.local', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Administrador', 0, 1, 1, UNIX_TIMESTAMP());

INSERT IGNORE INTO `empleados` (`user_id`, `nombre_completo`, `rol`, `diadema_id`) 
VALUES (1, 'Administrador del Sistema', 'administrador', 'SYS-001');

-- Meseros
INSERT IGNORE INTO `users` (`id`, `email`, `password`, `username`, `status`, `verified`, `roles_mask`, `registered`) 
VALUES (2, 'juan@restaurante.local', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Juan Mesero', 0, 1, 0, UNIX_TIMESTAMP());
INSERT IGNORE INTO `empleados` (`user_id`, `nombre_completo`, `rol`, `diadema_id`) 
VALUES (2, 'Juan Pérez', 'mesero', 'BT-MES-01');

-- Cocineros
INSERT IGNORE INTO `users` (`id`, `email`, `password`, `username`, `status`, `verified`, `roles_mask`, `registered`) 
VALUES (3, 'pedro@restaurante.local', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Pedro Chef', 0, 1, 0, UNIX_TIMESTAMP());
INSERT IGNORE INTO `empleados` (`user_id`, `nombre_completo`, `rol`, `diadema_id`) 
VALUES (3, 'Pedro Cocinero', 'cocinero', 'BT-COC-01');

-- Mesas
INSERT IGNORE INTO `mesas` (`numero`, `capacidad`) VALUES (1, 2), (2, 4), (3, 4), (4, 6), (5, 4);

-- Categorías
INSERT IGNORE INTO `categorias` (`id`, `nombre`, `orden`) VALUES 
(1, 'Bebidas', 1),
(2, 'Tacos', 2),
(3, 'Especialidades', 3);

-- Productos
INSERT IGNORE INTO `productos` (`categoria_id`, `nombre`, `precio`, `palabras_clave`) VALUES 
(1, 'Agua de horchata', 30.00, 'agua horchata agua de horchata'),
(1, 'Coca Cola 600ml', 25.00, 'coca coca cola refresco coca 600'),
(2, 'Taco al pastor', 20.00, 'taco pastor tacos pastor pastor con todo'),
(2, 'Taco de bistec', 25.00, 'taco bistec tacos bistec asada bistec'),
(3, 'Huarache de costilla', 75.00, 'huarache guarache huarache costilla guarache costilla');
