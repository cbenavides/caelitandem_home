-- =============================================================================
-- LAESH Bloc Digital — Script 08: Procedimientos Almacenados
-- Procedimientos: CrearOrdenLaboratorio, ProcesarCargaResultadoPDF
-- Idempotente: DROP PROCEDURE IF EXISTS + CREATE PROCEDURE.
-- =============================================================================

USE `laesh_db`;

DELIMITER //

-- ---------------------------------------------------------------------------
-- CrearOrdenLaboratorio
-- Crea una orden con folio atómico LAESH-NNNNN y registra el primer movimiento
-- de estado en historial_estados_orden.
-- Retorna el folio generado vía parámetro OUT.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `CrearOrdenLaboratorio` //

CREATE PROCEDURE `CrearOrdenLaboratorio`(
    IN  p_paciente_id     INT UNSIGNED,
    IN  p_medico_id       INT UNSIGNED,
    IN  p_recepcion_id    INT UNSIGNED,
    IN  p_edad_al_emitir  TINYINT UNSIGNED,
    IN  p_diagnostico     VARCHAR(500),
    IN  p_otros_estudios  VARCHAR(500),
    IN  p_estudios_json   TEXT,
    OUT p_folio           VARCHAR(20)
)
BEGIN
    DECLARE v_ultimo   INT UNSIGNED DEFAULT 0;
    DECLARE v_orden_id INT UNSIGNED;

    -- 1. Obtener siguiente número de folio de forma atómica
    UPDATE `folios_control`
       SET `ultimo_numero` = `ultimo_numero` + 1
     WHERE `serie` = 'LAESH';

    SELECT `ultimo_numero` INTO v_ultimo
      FROM `folios_control`
     WHERE `serie` = 'LAESH'
     LIMIT 1;

    -- 2. Formatear folio: LAESH-00001
    SET p_folio = CONCAT('LAESH-', LPAD(v_ultimo, 5, '0'));

    -- 3. Insertar la orden
    INSERT INTO `ordenes` (
        `folio`, `paciente_id`, `medico_id`, `recepcion_id`,
        `estado_id`, `edad_al_emitir`, `diagnostico`, `otros_estudios`, `estudios`
    ) VALUES (
        p_folio, p_paciente_id, p_medico_id, p_recepcion_id,
        1, p_edad_al_emitir, p_diagnostico, p_otros_estudios, p_estudios_json
    );

    SET v_orden_id = LAST_INSERT_ID();

    -- 4. Registrar primer movimiento de estado (creación = NULL → Pendiente)
    INSERT INTO `historial_estados_orden` (`orden_id`, `estado_desde`, `estado_hasta`, `cambiado_por`, `observacion`)
    VALUES (v_orden_id, NULL, 1, p_recepcion_id, 'Orden creada');

END //

-- ---------------------------------------------------------------------------
-- ProcesarCargaResultadoPDF
-- Registra el PDF subido, avanza el estado a Listo (3) y genera notificación
-- para el médico con soporte QoS (entregado_ws=0 por defecto → AJAX fallback).
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `ProcesarCargaResultadoPDF` //

CREATE PROCEDURE `ProcesarCargaResultadoPDF`(
    IN p_orden_id      INT UNSIGNED,
    IN p_nombre_archivo VARCHAR(255),
    IN p_ruta_storage  VARCHAR(500),
    IN p_subido_por    INT UNSIGNED
)
BEGIN
    DECLARE v_medico_id   INT UNSIGNED;
    DECLARE v_folio       VARCHAR(20);
    DECLARE v_estado_prev TINYINT UNSIGNED;

    -- 1. Obtener datos de la orden
    SELECT `medico_id`, `folio`, `estado_id`
      INTO v_medico_id, v_folio, v_estado_prev
      FROM `ordenes`
     WHERE `id` = p_orden_id
     LIMIT 1;

    -- 2. Registrar el PDF
    INSERT INTO `resultados_pdf` (`orden_id`, `nombre_archivo`, `ruta_storage`, `subido_por`)
    VALUES (p_orden_id, p_nombre_archivo, p_ruta_storage, p_subido_por);

    -- 3. Avanzar estado a Listo (3) si no está ya en Entregado (4) o Cancelado (5)
    IF v_estado_prev NOT IN (4, 5) THEN
        UPDATE `ordenes` SET `estado_id` = 3 WHERE `id` = p_orden_id;

        INSERT INTO `historial_estados_orden` (`orden_id`, `estado_desde`, `estado_hasta`, `cambiado_por`, `observacion`)
        VALUES (p_orden_id, v_estado_prev, 3, p_subido_por, CONCAT('PDF cargado: ', p_nombre_archivo));
    END IF;

    -- 4. Crear notificación para el médico (QoS: entregado_ws=0 → fallback AJAX activo)
    INSERT INTO `notificaciones` (`destinatario_id`, `tipo`, `folio_referencia`, `mensaje`, `entregado_ws`)
    VALUES (
        v_medico_id,
        'resultados_listos',
        v_folio,
        CONCAT('Sus resultados para la orden ', v_folio, ' están disponibles.'),
        0
    );

END //

DELIMITER ;
