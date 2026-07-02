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
(2, 'Tacos Tradicionales', 2),
(3, 'Especialidades y Alambres', 3),
(4, 'Entradas y Acompañamientos', 4);

-- Productos
INSERT IGNORE INTO `productos` (`categoria_id`, `nombre`, `precio`, `palabras_clave`) VALUES 
-- Bebidas
(1, 'Agua de horchata', 30.00, 'agua horchata agua de horchata'),
(1, 'Agua de Jamaica', 30.00, 'agua jamaica agua de jamaica'),
(1, 'Coca Cola 600ml', 25.00, 'coca coca cola refresco coca 600'),
(1, 'Boing de Mango', 22.00, 'boing boing mango jugo boing mango'),
(1, 'Boing de Guayaba', 22.00, 'boing boing guayaba jugo boing guayaba'),

-- Tacos Tradicionales
(2, 'Taco al pastor', 18.00, 'taco pastor tacos pastor pastor con todo pastor solo'),
(2, 'Taco de suadero', 20.00, 'taco suadero tacos suadero suadero con todo suadero solo'),
(2, 'Taco de bistec', 22.00, 'taco bistec tacos bistec asada bistec con todo bistec solo'),
(2, 'Taco de longaniza', 20.00, 'taco longaniza tacos longaniza longaniza con todo longaniza solo'),
(2, 'Taco campechano', 22.00, 'taco campechano tacos campechano campechano con todo campechano solo mixtos'),

-- Especialidades y Alambres
(3, 'Gringa de pastor', 55.00, 'gringa gringas gringa pastor gringas pastor queso'),
(3, 'Alambre de bistec', 95.00, 'alambre alambres alambre bistec alambre de bistec queso cebolla pimiento'),
(3, 'Alambre de pastor', 90.00, 'alambre alambres alambre pastor alambre de pastor queso cebolla pimiento'),
(3, 'Costra de bistec', 65.00, 'costra costras costra bistec costra de bistec queso crujiente'),
(3, 'Huarache de costilla', 75.00, 'huarache guarache huarache costilla guarache costilla'),

-- Entradas y Acompañamientos
(4, 'Quesadilla sencilla', 30.00, 'quesadilla quesadillas quesadilla sencilla con queso'),
(4, 'Queso fundido con champiñones', 70.00, 'queso fundido queso fundido champiñones champis entrada'),
(4, 'Queso fundido con chorizo', 75.00, 'queso fundido chorizo queso fundido con chorizo entrada'),
(4, 'Cebollitas cambray', 25.00, 'cebollitas cebollitas cambray cebollas asadas entrada'),
(4, 'Consome de barbacoa', 35.00, 'consome caldo consome de barbacoa caldito entrada');
