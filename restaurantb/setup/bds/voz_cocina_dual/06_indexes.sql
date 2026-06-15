-- ════════════════════════════════════════════════════════════
-- 06_indexes.sql
-- Optimización de Consultas para Dashboard Cocina y Cierre
-- ════════════════════════════════════════════════════════════

USE vcd01;

-- Índice para el Dashboard de Cocina KDS
-- Filtra rápidamente comandas por estado y ordena por hora de captura (FIFO)
CREATE INDEX idx_comanda_estado_hora ON comandas (estado, hora_captura);

-- Índice para Cierre de Cuenta
-- Filtra rápidamente las comandas activas por mesa
CREATE INDEX idx_comanda_mesa_estado ON comandas (mesa_id, estado);

-- Índice para el detalle de comandas
-- Acelera el proceso CerrarCuentaMesa que suma subtotales de productos 'activos'
CREATE INDEX idx_detalle_comanda_estado ON detalle_comandas (comanda_id, estado);
