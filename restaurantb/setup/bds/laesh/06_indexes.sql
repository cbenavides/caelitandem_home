-- =============================================================================
-- LAESH Bloc Digital — Script 06: Índices Adicionales de Rendimiento
-- Idempotente: DROP IF EXISTS + CREATE INDEX (evita duplicados).
-- Nota: Los índices PRIMARY, UNIQUE y FK ya están en los scripts 02–05.
-- Aquí solo índices de rendimiento para consultas frecuentes.
-- =============================================================================

USE `laesh_db`;

-- ORDENES: Búsqueda por médico + fecha (listado de órdenes del día)
DROP INDEX IF EXISTS `idx_ordenes_medico_fecha` ON `ordenes`;
CREATE INDEX `idx_ordenes_medico_fecha`
    ON `ordenes` (`medico_id`, `creado_en`);

-- ORDENES: Búsqueda por estado + fecha (cola de recepción)
DROP INDEX IF EXISTS `idx_ordenes_estado_fecha` ON `ordenes`;
CREATE INDEX `idx_ordenes_estado_fecha`
    ON `ordenes` (`estado_id`, `creado_en`);

-- PACIENTES: Búsqueda por nombre completo (LIKE prefix)
DROP INDEX IF EXISTS `idx_pacientes_nombre` ON `pacientes`;
CREATE INDEX `idx_pacientes_nombre`
    ON `pacientes` (`apellido_paterno`, `nombre`);

-- NOTIFICACIONES: Poll AJAX fallback (entregado_ws=0 OR leido=0)
-- El índice idx_fallback_poll ya está en 03_transactional_schema.sql.
-- HISTORIAL: Consulta de tiempos por orden
DROP INDEX IF EXISTS `idx_hist_orden_creado` ON `historial_estados_orden`;
CREATE INDEX `idx_hist_orden_creado`
    ON `historial_estados_orden` (`orden_id`, `creado_en`);

-- WEB_CONTENIDOS: Lectura por sección (CMS render)
-- El idx_seccion ya está en 02_core_schema.sql.

-- SYS_LOGS: Consulta de eventos de seguridad por nivel (columnas en inglés — Logger.php)
DROP INDEX IF EXISTS `idx_syslogs_level_created` ON `sys_logs`;
CREATE INDEX `idx_syslogs_level_created`
    ON `sys_logs` (`level`, `created_at`);
