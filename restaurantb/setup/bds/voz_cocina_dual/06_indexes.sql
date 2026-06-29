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

-- Índices Transaccionales y de Reportes Analíticos (HTMX)
-- Acelera los arqueos y reportes financieros
CREATE INDEX idx_tickets_corte ON tickets (corte_id);
CREATE INDEX idx_tickets_fecha ON tickets (fecha_cierre);

-- Acelera los reportes del Reloj Checador
CREATE INDEX idx_asistencias_fecha ON asistencias_personal (timestamp);

-- Índice para filtrado en el Log Viewer
CREATE INDEX idx_syslogs_level_time ON sys_logs (level, timestamp);

-- ════════════════════════════════════════════════════════════
-- EVENTOS PROGRAMADOS (Log Rotation y Purgado)
-- ════════════════════════════════════════════════════════════

-- Asegurar que el Event Scheduler esté activo (si es posible a nivel DB)
-- Nota: En producción, asegurar que event_scheduler=ON esté en my.cnf
SET GLOBAL event_scheduler = ON;

DELIMITER //
DROP EVENT IF EXISTS `RotateSysLogsEvent` //
CREATE EVENT `RotateSysLogsEvent`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO
BEGIN
    -- Borrado duro de logs INFO y DEBUG mayores a 30 días
    DELETE FROM `sys_logs` 
    WHERE `level` IN ('INFO', 'DEBUG') 
      AND `timestamp` < DATE_SUB(NOW(), INTERVAL 30 DAY);
END //
DELIMITER ;
