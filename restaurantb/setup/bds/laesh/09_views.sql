-- =============================================================================
-- LAESH Bloc Digital — Script 09: Vistas (Views)
-- Vistas: vw_ordenes_completas
-- Idempotente: CREATE OR REPLACE VIEW.
-- Fuente: Tecnica_Modelo_Datos.html — sección Vistas y Consultas frecuentes
-- =============================================================================

USE `laesh_db`;

-- ---------------------------------------------------------------------------
-- vw_ordenes_completas
-- Vista desnormalizada para listados de recepción, médicos y reportes.
-- Junta: ordenes + pacientes + catalogo_estados + empleados (médico) + perfiles_medicos + empleados (recepción)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vw_ordenes_completas` AS
SELECT
    o.id                                                          AS orden_id,
    o.folio_unico,
    o.hora_captura,
    o.fecha_resultado,
    o.diagnostico,
    o.otros_estudios,
    o.estudios                                                    AS estudios_json,
    o.edad_al_emitir,

    -- Paciente
    p.id                                                          AS paciente_id,
    p.nombre_completo                                             AS paciente_nombre,
    p.sexo                                                        AS paciente_sexo,
    p.fecha_nacimiento                                            AS paciente_fecha_nac,
    p.telefono                                                    AS paciente_telefono,

    -- Estado de la orden
    ce.id                                                         AS estado_id,
    ce.valor                                                      AS estado_valor,
    ce.color_hex                                                  AS estado_color,

    -- Motivo de cancelación (si la orden fue cancelada)
    h_canc.observacion                                            AS motivo_cancelacion,

    -- Médico que emitió la orden (user_id directo + empleado_id + perfil)
    o.medico_id                                                   AS medico_user_id,
    em.id                                                         AS medico_empleado_id,
    em.nombre                                                     AS medico_nombre,
    em.apellidos                                                  AS medico_apellidos,
    COALESCE(pm.nombre_completo, NULLIF(CONCAT(IFNULL(em.nombre,''), ' ', IFNULL(em.apellidos,'')), ' '), 'Médico General') AS medico_nombre_completo,
    COALESCE(pm.especialidad, 'Medicina General')                AS medico_especialidad,
    COALESCE(pm.cedula_profesional, 'CED-N/A')                   AS medico_cedula,

    -- Recepcionista que capturó (nullable)
    o.recepcion_id                                                AS recepcion_user_id,
    er.nombre                                                     AS recepcion_nombre,
    er.apellidos                                                  AS recepcion_apellidos,

    o.actualizado_en

FROM `ordenes` o
JOIN `pacientes`        p   ON p.id  = o.paciente_id
JOIN `catalogo_estados` ce  ON ce.id = o.estado_id
LEFT JOIN (
    SELECT h1.orden_id, h1.observacion
    FROM historial_estados_orden h1
    INNER JOIN (
        SELECT orden_id, MAX(id) AS max_id
        FROM historial_estados_orden
        WHERE estado_nuevo_id = 5
        GROUP BY orden_id
    ) h2 ON h1.id = h2.max_id
) h_canc ON h_canc.orden_id = o.id
LEFT JOIN `empleados`   em  ON em.user_id  = o.medico_id
LEFT JOIN `perfiles_medicos` pm ON pm.user_id  = o.medico_id
LEFT JOIN `empleados`   er  ON er.user_id  = o.recepcion_id;

-- ---------------------------------------------------------------------------
-- vw_ws_fallback_stats — Deuda QoS-01 (2026-09-18)
-- Estadísticas agregadas de fallback WS por flujo/día, consumidas por
-- admrc/views/log_viewer.php (pestaña "Estadísticas WS" en /laesh/adrc/sistema).
-- Deliberadamente una VIEW de solo lectura sobre notificaciones, no una tabla de
-- log nueva: el dato crudo (entregado_ws, tipo, creado_en) ya existe por fila
-- desde el diseño original de QoS; esto solo lo agrega — evita una segunda vía
-- de escritura en el hot path de commons/notifier.php::emit().
-- Depende de notificaciones.fallback_reason (columna agregada en
-- 03_transactional_schema.sql — debe correr antes que este script).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vw_ws_fallback_stats` AS
SELECT
    `tipo`,
    DATE(`creado_en`)                                              AS `dia`,
    COUNT(*)                                                       AS `total`,
    SUM(`entregado_ws` = 0)                                        AS `fallbacks`,
    ROUND(SUM(`entregado_ws` = 0) / COUNT(*) * 100, 1)             AS `pct_fallback`
FROM `notificaciones`
GROUP BY `tipo`, DATE(`creado_en`)
ORDER BY `dia` DESC, `tipo` ASC;

-- ---------------------------------------------------------------------------
-- vw_estudios_catalogo
-- Catálogo general desnormalizado de estudios de laboratorio con su categoría.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vw_estudios_catalogo` AS
SELECT
    e.id,
    e.categoria_id,
    e.clave,
    e.nombre,
    COALESCE(c.nombre, 'General') AS categoria,
    e.descripcion_breve,
    e.tiempo,
    e.muestra,
    e.contenedor,
    e.preparacion,
    e.top20_orden,
    e.activo
FROM `cat_estudios` e
LEFT JOIN `cat_categorias` c ON e.categoria_id = c.id;

-- ---------------------------------------------------------------------------
-- vw_top20_estudios
-- Estudios destacados Top 20 para la grilla del portal médico y recepción.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vw_top20_estudios` AS
SELECT
    e.id,
    e.clave,
    e.nombre,
    e.categoria,
    e.top20_orden
FROM `vw_estudios_catalogo` e
WHERE e.top20_orden IS NOT NULL AND e.top20_orden > 0
ORDER BY e.top20_orden ASC;

-- ---------------------------------------------------------------------------
-- vw_rbac_permisos_usuarios
-- Mapeo relacional de permisos asignados por usuario (RBAC).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vw_rbac_permisos_usuarios` AS
SELECT
    pu.user_id,
    p.id          AS permiso_id,
    p.nombre      AS permiso_nombre,
    p.descripcion AS permiso_descripcion
FROM `rbac_permisos` p
JOIN `rbac_permisos_usuarios` pu ON p.id = pu.permiso_id;

-- ---------------------------------------------------------------------------
-- vw_empleados_usuarios
-- Unión relacional entre la cuenta de usuario (users) y el perfil operativo de empleado.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vw_empleados_usuarios` AS
SELECT
    e.id                                AS empleado_id,
    e.user_id,
    e.nombre,
    e.apellidos,
    CONCAT(e.nombre, ' ', e.apellidos) AS nombre_completo,
    e.rol,
    e.activo,
    e.creado_en,
    u.email,
    u.username
FROM `empleados` e
JOIN `users` u ON e.user_id = u.id;

-- ---------------------------------------------------------------------------
-- vw_website_arbol_estudios
-- Jerarquía multinivel (iGabinetes → Gabinetes / Subgabinetes → Estudios) para la web pública.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vw_website_arbol_estudios` AS
SELECT
    ig.id                                                                               AS grupo_id,
    ig.nombre                                                                           AS grupo_titulo,
    ig.orden                                                                            AS grupo_orden,
    CASE WHEN sg.id IS NOT NULL THEN CONCAT('s_', sg.id) ELSE CONCAT('g_', gab.id) END AS cat_id,
    COALESCE(sg.nombre, gab.nombre)                                                     AS cat_nombre,
    COALESCE(sg.orden, gab.orden)                                                      AS cat_orden,
    e.id                                                                                AS estudio_id,
    e.clave                                                                            AS clave_interna,
    e.nombre                                                                            AS estudio_nombre,
    e.tiempo                                                                            AS tiempo_procesamiento,
    e.muestra                                                                           AS muestra_requerida,
    e.preparacion,
    e.contenedor,
    e.pruebas_incluidas
FROM `cat_igabinetes` ig
JOIN `rel_igabinete_vinculos` riv ON riv.igabinete_id = ig.id
LEFT JOIN `cat_gabinetes` gab     ON gab.id = riv.gabinete_id
LEFT JOIN `cat_subgabinetes` sg   ON sg.id = riv.subgabinete_id
JOIN `rel_estudio_gabinete` reg   ON (
    (riv.subgabinete_id IS NOT NULL AND reg.subgabinete_id = riv.subgabinete_id) OR
    (riv.subgabinete_id IS NULL AND riv.gabinete_id IS NOT NULL AND reg.gabinete_id = riv.gabinete_id AND reg.subgabinete_id IS NULL)
)
JOIN `cat_estudios` e             ON e.id = reg.estudio_id;

-- ---------------------------------------------------------------------------
-- vw_medicos_completos
-- Vista consolidada del directorio de médicos enlazando perfiles, estado y catálogos UI.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vw_medicos_completos` AS
SELECT
    pm.user_id,
    pm.nombre_completo,
    pm.especialidad,
    pm.cedula_profesional,
    pm.cedula_especialidad,
    pm.celular,
    pm.telefono_consultorio,
    pm.direccion_consultorio,
    pm.universidad_id,
    c_u.valor                                                            AS universidad_nombre,
    pm.lugar_trabajo_id,
    c_l.valor                                                            AS lugar_trabajo_nombre,
    pm.estado_id,
    COALESCE(cem.nombre, 'Activo')                                        AS estado_nombre,
    pm.total_ordenes,
    pm.creado_en
FROM `perfiles_medicos` pm
LEFT JOIN `cat_estados_medico` cem ON cem.id = pm.estado_id
LEFT JOIN `catalogos_ui` c_u       ON c_u.id = pm.universidad_id
LEFT JOIN `catalogos_ui` c_l       ON c_l.id = pm.lugar_trabajo_id;

-- ---------------------------------------------------------------------------
-- vw_notificaciones_pendientes
-- Vista desnormalizada de notificaciones no leídas para polling fallback.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vw_notificaciones_pendientes` AS
SELECT
    n.id,
    n.user_id,
    n.tipo,
    n.folio_referencia,
    n.mensaje,
    n.leido,
    n.entregado_ws,
    n.creado_en
FROM `notificaciones` n
WHERE n.leido = 0;

-- ---------------------------------------------------------------------------
-- vw_ordenes_estadisticas
-- Vista consolidada de totales por estado, pacientes y médicos para el dashboard.
-- ---------------------------------------------------------------------------
-- H8 (2026-09-20): agregado 'canceladas' (estado_id=5) para no contaminar el
-- conteo de 'cerradas' con órdenes canceladas (motivo original del hallazgo).
CREATE OR REPLACE VIEW `vw_ordenes_estadisticas` AS
SELECT
    (SELECT COUNT(*) FROM `ordenes`)                                      AS total_ordenes,
    (SELECT COUNT(*) FROM `ordenes` WHERE `estado_id` = 1)                AS remitidas,
    (SELECT COUNT(*) FROM `ordenes` WHERE `estado_id` = 2)                AS en_atencion,
    (SELECT COUNT(*) FROM `ordenes` WHERE `estado_id` = 3)                AS resultados_listos,
    (SELECT COUNT(*) FROM `ordenes` WHERE `estado_id` = 4)                AS cerradas,
    (SELECT COUNT(*) FROM `ordenes` WHERE `estado_id` = 5)                AS canceladas,
    (SELECT COUNT(*) FROM `pacientes`)                                    AS total_pacientes,
    (SELECT COUNT(*) FROM `perfiles_medicos` WHERE `estado_id` = 1)       AS total_medicos;


