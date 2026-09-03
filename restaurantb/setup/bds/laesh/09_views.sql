-- =============================================================================
-- LAESH Bloc Digital — Script 09: Vistas (Views)
-- Vistas: vw_ordenes_completas, vw_pacientes_historial
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
LEFT JOIN `empleados`   em  ON em.user_id  = o.medico_id
LEFT JOIN `perfiles_medicos` pm ON pm.user_id  = o.medico_id
LEFT JOIN `empleados`   er  ON er.user_id  = o.recepcion_id;

-- ---------------------------------------------------------------------------
-- vw_pacientes_historial
-- Vista para consultar el historial de órdenes de un paciente.
-- Incluye estado actual y cantidad de estudios en JSON (desnormalización).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `vw_pacientes_historial` AS
SELECT
    p.id                                                          AS paciente_id,
    p.nombre_completo,
    p.sexo,
    p.fecha_nacimiento,
    p.telefono,

    o.id                                                          AS orden_id,
    o.folio_unico,
    o.hora_captura,
    o.fecha_resultado,
    o.diagnostico,
    o.edad_al_emitir,

    ce.valor                                                      AS estado_valor,
    ce.color_hex                                                  AS estado_color,

    CONCAT(em.nombre, ' ', em.apellidos)                          AS medico_nombre_completo,
    pm.especialidad                                               AS medico_especialidad

FROM `pacientes` p
JOIN `ordenes`          o   ON o.paciente_id = p.id
JOIN `catalogo_estados` ce  ON ce.id         = o.estado_id
JOIN `empleados`        em  ON em.user_id    = o.medico_id
LEFT JOIN `perfiles_medicos` pm ON pm.user_id = o.medico_id

ORDER BY p.nombre_completo, o.hora_captura DESC;
