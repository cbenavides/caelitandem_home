-- =============================================================================
-- LAESH Bloc Digital — Script 08: Procedimientos Almacenados
-- Procedimientos: CrearOrdenLaboratorio, ProcesarCargaResultadoPDF
-- Idempotente: DROP PROCEDURE IF EXISTS + CREATE PROCEDURE.
--
-- Redesign v2 — alineado con Tecnica_Modelo_Datos.html:
--   • folios_control: tipo_documento (era serie), ultimo_folio (era ultimo_numero),
--                     prefijo + longitud para formato del folio
--   • ordenes: folio_unico (era folio), hora_captura (era creado_en)
--   • historial_estados_orden: estado_anterior_id, estado_nuevo_id, cambiado_por_user_id
--   • notificaciones: user_id (era destinatario_id)
--   • catalogo_estados: 1=Remitido, 2=En Atención, 3=Resultados Listos, 4=Cerrada
-- =============================================================================

USE `laesh_db`;

DELIMITER //

-- ---------------------------------------------------------------------------
-- CrearOrdenLaboratorio
-- Crea una orden con folio atómico usando folios_control.tipo_documento='orden_laboratorio'.
-- Formato: CONCAT(prefijo, '-', LPAD(ultimo_folio, longitud, '0')) → LAESH-00001
-- Retorna el folio_unico generado vía parámetro OUT.
-- Estado inicial: 1 = Remitido
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `CrearOrdenLaboratorio` //

CREATE PROCEDURE `CrearOrdenLaboratorio`(
    IN  p_paciente_id     INT UNSIGNED,
    IN  p_medico_id       INT UNSIGNED,
    IN  p_recepcion_id    INT UNSIGNED,
    IN  p_edad_al_emitir  TINYINT UNSIGNED,
    IN  p_diagnostico     VARCHAR(200),   -- alineado con ordenes.diagnostico VARCHAR(200) — spec ET
    IN  p_otros_estudios  TEXT,            -- alineado con ordenes.otros_estudios TEXT — spec ET
    IN  p_estudios_json   TEXT,
    OUT p_folio_unico     VARCHAR(20)
)
BEGIN
    DECLARE v_ultimo   INT UNSIGNED DEFAULT 0;
    DECLARE v_prefijo  VARCHAR(10) DEFAULT 'LAESH';
    DECLARE v_longitud TINYINT UNSIGNED DEFAULT 5;
    DECLARE v_orden_id INT UNSIGNED;

    -- 1. Obtener siguiente número de folio de forma atómica
    UPDATE `folios_control`
       SET `ultimo_folio` = `ultimo_folio` + 1
     WHERE `tipo_documento` = 'orden_laboratorio';

    SELECT `ultimo_folio`, `prefijo`, `longitud`
      INTO v_ultimo, v_prefijo, v_longitud
      FROM `folios_control`
     WHERE `tipo_documento` = 'orden_laboratorio'
     LIMIT 1;

    -- 2. Formatear folio: LAESH-00001
    SET p_folio_unico = CONCAT(v_prefijo, '-', LPAD(v_ultimo, v_longitud, '0'));

    -- 3. Insertar la orden (estado inicial: 1=Remitido)
    INSERT INTO `ordenes` (
        `folio_unico`, `paciente_id`, `medico_id`, `recepcion_id`,
        `estado_id`, `edad_al_emitir`, `diagnostico`, `otros_estudios`, `estudios`
    ) VALUES (
        p_folio_unico, p_paciente_id, p_medico_id, p_recepcion_id,
        1, p_edad_al_emitir, p_diagnostico, p_otros_estudios, p_estudios_json
    );

    SET v_orden_id = LAST_INSERT_ID();

    -- 4. Registrar primer movimiento de estado (creación: NULL → Remitido)
    INSERT INTO `historial_estados_orden`
        (`orden_id`, `estado_anterior_id`, `estado_nuevo_id`, `cambiado_por_user_id`, `observacion`)
    VALUES
        (v_orden_id, NULL, 1, p_recepcion_id, 'Orden creada — estado inicial: Remitido');

END //

-- ---------------------------------------------------------------------------
-- ProcesarCargaResultadoPDF
-- Registra el PDF subido, avanza el estado a 3 (Resultados Listos) y genera
-- notificación para el médico con soporte QoS (entregado_ws=0 → AJAX fallback).
-- También actualiza ordenes.fecha_resultado con la fecha/hora de la carga.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `ProcesarCargaResultadoPDF` //

CREATE PROCEDURE `ProcesarCargaResultadoPDF`(
    IN p_orden_id       INT UNSIGNED,
    IN p_nombre_archivo VARCHAR(255),
    IN p_ruta_storage   VARCHAR(500),
    IN p_subido_por     INT UNSIGNED
)
BEGIN
    DECLARE v_medico_id   INT UNSIGNED;
    DECLARE v_folio       VARCHAR(20);
    DECLARE v_estado_prev TINYINT UNSIGNED;

    -- 1. Obtener datos de la orden
    SELECT `medico_id`, `folio_unico`, `estado_id`
      INTO v_medico_id, v_folio, v_estado_prev
      FROM `ordenes`
     WHERE `id` = p_orden_id
     LIMIT 1;

    -- 2. Registrar el PDF
    INSERT INTO `resultados_pdf` (`orden_id`, `nombre_archivo`, `ruta_storage`, `subido_por`)
    VALUES (p_orden_id, p_nombre_archivo, p_ruta_storage, p_subido_por);

    -- 3. Avanzar estado a 3 (Resultados Listos) si no está ya en 4 (Cerrada)
    IF v_estado_prev <> 4 THEN
        UPDATE `ordenes`
           SET `estado_id` = 3, `fecha_resultado` = NOW()
         WHERE `id` = p_orden_id;

        INSERT INTO `historial_estados_orden`
            (`orden_id`, `estado_anterior_id`, `estado_nuevo_id`, `cambiado_por_user_id`, `observacion`)
        VALUES
            (p_orden_id, v_estado_prev, 3, p_subido_por, CONCAT('PDF cargado: ', p_nombre_archivo));
    END IF;

    -- 4. Crear notificación para el médico (QoS: entregado_ws=0 → fallback AJAX activo)
    INSERT INTO `notificaciones`
        (`user_id`, `tipo`, `folio_referencia`, `mensaje`, `url_enlace`, `entregado_ws`)
    VALUES (
        v_medico_id,
        'resultados_listos',
        v_folio,
        CONCAT('Sus resultados para la orden ', v_folio, ' están disponibles.'),
        CONCAT('/laesh/md/?orden=', v_folio),
        0
    );

END //

DELIMITER ;
