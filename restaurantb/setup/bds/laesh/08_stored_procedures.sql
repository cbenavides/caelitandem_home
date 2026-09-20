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
    --    GAP-04 fix: actor = recepcion_id si viene de Recepción; medico_id si es Solicitud Digital
    INSERT INTO `historial_estados_orden`
        (`orden_id`, `estado_anterior_id`, `estado_nuevo_id`, `cambiado_por_user_id`, `observacion`)
    VALUES
        (v_orden_id, NULL, 1,
         COALESCE(p_recepcion_id, p_medico_id),
         CASE WHEN p_recepcion_id IS NOT NULL
              THEN 'Orden creada en Recepción — estado inicial: Remitido'
              ELSE 'Solicitud Digital emitida por médico — estado inicial: Remitido'
         END);

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

-- ---------------------------------------------------------------------------
-- CambiarEstadoOrden
-- Transición atómica de estado de una orden con registro en historial.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `CambiarEstadoOrden` //

CREATE PROCEDURE `CambiarEstadoOrden`(
    IN  p_orden_id        INT UNSIGNED,
    IN  p_nuevo_estado_id TINYINT UNSIGNED,
    IN  p_user_id         INT UNSIGNED,
    IN  p_observacion      VARCHAR(255),
    OUT p_estado_anterior TINYINT UNSIGNED,
    OUT p_folio_unico     VARCHAR(20)
)
BEGIN
    DECLARE v_curr_estado TINYINT UNSIGNED;
    DECLARE v_folio       VARCHAR(20);

    SELECT `estado_id`, `folio_unico`
      INTO v_curr_estado, v_folio
      FROM `ordenes`
     WHERE `id` = p_orden_id
     LIMIT 1;

    SET p_estado_anterior = v_curr_estado;
    SET p_folio_unico     = v_folio;

    IF v_curr_estado IS NOT NULL THEN
        UPDATE `ordenes`
           SET `estado_id` = p_nuevo_estado_id,
               `fecha_resultado` = IF(p_nuevo_estado_id IN (3,4), NOW(), `fecha_resultado`)
         WHERE `id` = p_orden_id;

        INSERT INTO `historial_estados_orden` (
            `orden_id`, `estado_anterior_id`, `estado_nuevo_id`, `cambiado_por_user_id`, `observacion`
        ) VALUES (
            p_orden_id, v_curr_estado, p_nuevo_estado_id, p_user_id,
            IF(p_observacion IS NULL OR p_observacion = '', CONCAT('Transición de estado a ', p_nuevo_estado_id), p_observacion)
        );
    END IF;
END //

-- ---------------------------------------------------------------------------
-- RegistrarPerfilMedico
-- Alta integral de médico: registra empleado, otorga permisos RBAC y crea perfil.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `RegistrarPerfilMedico` //

CREATE PROCEDURE `RegistrarPerfilMedico`(
    IN p_user_id        INT UNSIGNED,
    IN p_nombre         VARCHAR(150),
    IN p_especialidad   VARCHAR(100),
    IN p_cedula         VARCHAR(100),
    IN p_celular        VARCHAR(20),
    IN p_universidad_id INT UNSIGNED,
    IN p_lugar_id       INT UNSIGNED
)
BEGIN
    DECLARE v_primer_nombre VARCHAR(75);
    DECLARE v_apellidos     VARCHAR(75);
    DECLARE v_pos_space     INT;

    SET v_pos_space = INSTR(TRIM(p_nombre), ' ');
    IF v_pos_space > 0 THEN
        SET v_primer_nombre = SUBSTRING(TRIM(p_nombre), 1, v_pos_space - 1);
        SET v_apellidos     = SUBSTRING(TRIM(p_nombre), v_pos_space + 1);
    ELSE
        SET v_primer_nombre = TRIM(p_nombre);
        SET v_apellidos     = 'Médico';
    END IF;

    -- 1. Insertar empleado
    INSERT INTO `empleados` (`user_id`, `nombre`, `apellidos`, `rol`, `activo`, `creado_en`)
    VALUES (p_user_id, v_primer_nombre, v_apellidos, 'MEDICO', 1, NOW())
    ON DUPLICATE KEY UPDATE `activo` = 1;

    -- 2. Otorgar permisos RBAC predeterminados para médico
    INSERT IGNORE INTO `rbac_permisos_usuarios` (`user_id`, `permiso_id`, `otorgado_en`)
    SELECT p_user_id, `id`, NOW()
      FROM `rbac_permisos`
     WHERE `nombre` IN ('ver_ordenes_propias', 'ver_solicitud_digital');

    -- 3. Crear o actualizar perfil médico
    INSERT INTO `perfiles_medicos` (
        `user_id`, `nombre_completo`, `especialidad`, `cedula_profesional`, `celular`,
        `universidad_id`, `lugar_trabajo_id`, `estado_id`, `total_ordenes`, `creado_en`
    ) VALUES (
        p_user_id, p_nombre, p_especialidad, p_cedula, p_celular,
        p_universidad_id, p_lugar_id, 1, 0, NOW()
    ) ON DUPLICATE KEY UPDATE
        `nombre_completo` = p_nombre,
        `especialidad` = p_especialidad,
        `cedula_profesional` = p_cedula,
        `celular` = p_celular,
        `estado_id` = 1;
END //

-- ---------------------------------------------------------------------------
-- UpsertEstudioCatalogo
-- Inserción/actualización atómica de un estudio en el catálogo de laboratorio.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `UpsertEstudioCatalogo` //

CREATE PROCEDURE `UpsertEstudioCatalogo`(
    INOUT p_id               INT UNSIGNED,
    IN    p_clave            VARCHAR(30),
    IN    p_nombre           VARCHAR(150),
    IN    p_categoria_nombre VARCHAR(100),
    IN    p_muestra          VARCHAR(120),
    IN    p_contenedor       VARCHAR(100),
    IN    p_tiempo           VARCHAR(100),
    IN    p_preparacion      TEXT,
    IN    p_pruebas_incluidas TEXT
)
BEGIN
    DECLARE v_cat_id INT UNSIGNED DEFAULT 1;

    IF p_categoria_nombre IS NOT NULL AND p_categoria_nombre <> '' THEN
        SELECT `id` INTO v_cat_id
          FROM `cat_categorias`
         WHERE `nombre` = p_categoria_nombre
         LIMIT 1;
        IF v_cat_id IS NULL THEN SET v_cat_id = 1; END IF;
    END IF;

    IF p_id IS NOT NULL AND p_id > 0 THEN
        UPDATE `cat_estudios`
           SET `clave` = COALESCE(NULLIF(p_clave, ''), `clave`),
               `nombre` = COALESCE(NULLIF(p_nombre, ''), `nombre`),
               `categoria_id` = v_cat_id,
               `muestra` = p_muestra,
               `contenedor` = p_contenedor,
               `tiempo` = p_tiempo,
               `preparacion` = p_preparacion,
               `pruebas_incluidas` = p_pruebas_incluidas,
               `fecha_modificacion` = NOW(),
               `updated_at` = NOW()
         WHERE `id` = p_id;
    ELSE
        INSERT INTO `cat_estudios` (
            `clave`, `nombre`, `categoria_id`, `muestra`, `contenedor`,
            `tiempo`, `preparacion`, `pruebas_incluidas`, `fecha_modificacion`, `updated_at`
        ) VALUES (
            p_clave, p_nombre, v_cat_id, p_muestra, p_contenedor,
            p_tiempo, p_preparacion, p_pruebas_incluidas, NOW(), NOW()
        );
        SET p_id = LAST_INSERT_ID();
    END IF;
END //

-- ---------------------------------------------------------------------------
-- CambiarEstadoMedico
-- Cambia de forma sincronizada el estado del perfil médico y su cuenta de empleado.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `CambiarEstadoMedico` //

CREATE PROCEDURE `CambiarEstadoMedico`(
    IN p_target_user_id  INT UNSIGNED,
    IN p_nuevo_estado_id TINYINT UNSIGNED
)
BEGIN
    UPDATE `perfiles_medicos`
       SET `estado_id` = p_nuevo_estado_id
     WHERE `user_id` = p_target_user_id;

    UPDATE `empleados`
       SET `activo` = IF(p_nuevo_estado_id = 1, 1, 0)
     WHERE `user_id` = p_target_user_id;
END //

-- ---------------------------------------------------------------------------
-- SyncJerarquiaGabinete
-- Reconstruye las relaciones entre gabinete/subgabinete y estudios.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `SyncJerarquiaGabinete` //

CREATE PROCEDURE `SyncJerarquiaGabinete`(
    IN p_gabinete_id    INT UNSIGNED,
    IN p_subgabinete_id INT UNSIGNED,
    IN p_estudio_id     INT UNSIGNED
)
BEGIN
    INSERT IGNORE INTO `rel_estudio_gabinete` (`estudio_id`, `gabinete_id`, `subgabinete_id`)
    VALUES (p_estudio_id, p_gabinete_id, p_subgabinete_id);
END //

DELIMITER ;
