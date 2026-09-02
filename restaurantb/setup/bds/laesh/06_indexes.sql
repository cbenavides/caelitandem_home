-- =============================================================================
-- LAESH Bloc Digital — Script 06: Índices Adicionales de Rendimiento
-- Idempotente: DROP IF EXISTS + CREATE INDEX (evita duplicados).
-- Nota: Los índices PRIMARY, UNIQUE y FK ya están en los scripts 02–05.
-- Aquí solo índices de rendimiento para consultas frecuentes.
--
-- Redesign v2: columnas renombradas
--   • ordenes.folio_unico (era folio)
--   • ordenes.hora_captura (era creado_en)
--   • pacientes.nombre_completo (era apellido_paterno + nombre)
--   • notificaciones.user_id (era destinatario_id)
-- =============================================================================

USE `laesh_db`;

-- ORDENES: Búsqueda por médico + fecha (listado de órdenes del día)
DROP INDEX IF EXISTS `idx_ordenes_medico_fecha` ON `ordenes`;
CREATE INDEX `idx_ordenes_medico_fecha`
    ON `ordenes` (`medico_id`, `hora_captura`);

-- ORDENES: Búsqueda por estado + fecha (cola de recepción)
DROP INDEX IF EXISTS `idx_ordenes_estado_fecha` ON `ordenes`;
CREATE INDEX `idx_ordenes_estado_fecha`
    ON `ordenes` (`estado_id`, `hora_captura`);

-- ORDENES: Búsqueda por folio_unico (ya tiene UNIQUE KEY — índice adicional de texto)
-- UNIQUE KEY uq_folio_unico ya cubre búsquedas directas por folio.

-- PACIENTES: FULLTEXT ya declarado en 03_transactional_schema.sql (ft_nombre_completo).
-- Índice B-Tree adicional para ORDER BY nombre_completo en listados de recepción:
DROP INDEX IF EXISTS `idx_pacientes_nombre_completo` ON `pacientes`;
CREATE INDEX `idx_pacientes_nombre_completo`
    ON `pacientes` (`nombre_completo`(50));

-- NOTIFICACIONES: Poll AJAX fallback (user_id + entregado_ws + leido)
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

-- PERFILES_MEDICOS: Búsqueda por estado para listado de médicos activos/pausados
DROP INDEX IF EXISTS `idx_pm_estado_user` ON `perfiles_medicos`;
CREATE INDEX `idx_pm_estado_user`
    ON `perfiles_medicos` (`estado_id`, `user_id`);

-- CATALOGO_PROMOCIONES: Consulta de promociones vigentes (optimización index.php)
DROP INDEX IF EXISTS `idx_promos_activo_orden` ON `catalogo_promociones`;
CREATE INDEX `idx_promos_activo_orden`
    ON `catalogo_promociones` (`activo`, `orden`, `id`);

-- CATALOGO_ESTUDIOS: Covering Index para acordeón de especialidades (optimización index.php)
-- Nota: categoria_id es clave foránea; si ya existe idx_estudios_cat_activo no se elimina
CREATE INDEX IF NOT EXISTS `idx_estudios_cat_activo`
    ON `catalogo_estudios` (`categoria_id`, `activo`, `id`);

-- WEB_CONTENIDOS: Búsqueda acelerada por sección, subsección y clave (CMS render)
DROP INDEX IF EXISTS `idx_cms_sec_sub_clave` ON `web_contenidos`;
CREATE INDEX `idx_cms_sec_sub_clave`
    ON `web_contenidos` (`seccion`, `subseccion`, `clave`);

