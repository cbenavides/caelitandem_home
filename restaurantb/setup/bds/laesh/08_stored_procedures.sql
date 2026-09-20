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
-- ProcesarCargaResultadoPDF — ELIMINADO (H5, auditoría 2026-09-20)
-- Código muerto: ningún PHP lo invocaba (confirmado por grep sobre todo el
-- repo). La ruta real (rc/negocio/Ordenes.php::guardarResultadoPDF) hacía el
-- INSERT a resultados_pdf y el cambio de estado en pasos sueltos, perdiendo la
-- guarda "no reabrir una orden Cerrada" que sí tenía este SP. Esa guarda queda
-- cubierta de forma genérica (para TODAS las transiciones, no solo PDF) por la
-- máquina de estados agregada a CambiarEstadoOrden abajo — guardarResultadoPDF
-- ya pasa por ahí. El DROP se conserva (sin CREATE) para limpiar el SP huérfano
-- en cualquier BD donde ya exista.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `ProcesarCargaResultadoPDF` //

-- ---------------------------------------------------------------------------
-- CambiarEstadoOrden
-- Transición atómica de estado de una orden con registro en historial.
--
-- H1 (auditoría 2026-09-20): antes aceptaba cualquier nuevo_estado_id sin
-- validar el estado actual — se podía saltar de Remitido a Cerrada, o
-- reabrir una orden Cerrada. Ahora valida contra una máquina de estados
-- explícita: 1→{2,3,4,5} · 2→{3,4} · 3→{4} · 4→{} (terminal) · 5→{} (terminal,
-- Cancelada — H8). Transición inválida → p_transicion_invalida=1, no se aplica
-- ningún cambio.
--
-- Regla de negocio (2026-09-20, confirmada explícitamente por el usuario):
-- la cancelación (→5) SOLO es válida desde Remitido (1) — nunca desde En
-- Atención (2). Antes el CASE permitía 2→5 por error de una edición previa
-- (la máquina de estados original de H1/H8 nunca lo incluyó); la UI de
-- Recepción (rcRenderBotonesAccion() en rc/index.php) ya solo ofrecía el
-- botón Cancelar en estado 1, así que el SP era más permisivo que la UI que
-- lo gobierna — corregido para que ambos coincidan.
--
-- H7 (auditoría 2026-09-20): optimistic locking — p_estado_esperado (opcional,
-- NULL = sin verificar, usado por callers que no lo necesiten) debe coincidir
-- con el estado actual real en BD o la transición se rechaza con
-- p_conflicto=1. Evita que dos usuarios con la misma vista abierta se pisen
-- una transición basada en datos obsoletos.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `CambiarEstadoOrden` //

CREATE PROCEDURE `CambiarEstadoOrden`(
    IN  p_orden_id          INT UNSIGNED,
    IN  p_nuevo_estado_id   TINYINT UNSIGNED,
    IN  p_user_id           INT UNSIGNED,
    IN  p_observacion       VARCHAR(255),
    IN  p_estado_esperado   TINYINT UNSIGNED,
    OUT p_estado_anterior   TINYINT UNSIGNED,
    OUT p_folio_unico       VARCHAR(20),
    OUT p_conflicto         TINYINT(1),
    OUT p_transicion_invalida TINYINT(1)
)
proc_body: BEGIN
    DECLARE v_curr_estado TINYINT UNSIGNED;
    DECLARE v_folio       VARCHAR(20);
    DECLARE v_transicion_ok TINYINT(1) DEFAULT 0;

    SET p_conflicto = 0;
    SET p_transicion_invalida = 0;

    SELECT `estado_id`, `folio_unico`
      INTO v_curr_estado, v_folio
      FROM `ordenes`
     WHERE `id` = p_orden_id
     LIMIT 1;

    SET p_estado_anterior = v_curr_estado;
    SET p_folio_unico     = v_folio;

    IF v_curr_estado IS NULL THEN
        -- Orden no encontrada — folio_unico queda NULL, el caller PHP ya lo interpreta como error.
        LEAVE proc_body;
    END IF;

    -- H7: optimistic locking — si el caller indicó el estado que esperaba ver
    -- y no coincide con el real, es una transición basada en datos obsoletos.
    IF p_estado_esperado IS NOT NULL AND p_estado_esperado <> v_curr_estado THEN
        SET p_conflicto = 1;
        LEAVE proc_body;
    END IF;

    -- H1: máquina de estados — whitelist de transiciones válidas.
    SET v_transicion_ok = CASE
        WHEN v_curr_estado = 1 AND p_nuevo_estado_id IN (2,3,4,5) THEN 1
        WHEN v_curr_estado = 2 AND p_nuevo_estado_id IN (3,4)     THEN 1
        WHEN v_curr_estado = 3 AND p_nuevo_estado_id = 4          THEN 1
        ELSE 0
    END;

    IF v_transicion_ok = 0 THEN
        SET p_transicion_invalida = 1;
        LEAVE proc_body;
    END IF;

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
END //

-- ---------------------------------------------------------------------------
-- RegistrarPerfilMedico
-- Alta integral de médico: registra empleado, otorga permisos RBAC y crea perfil.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `RegistrarPerfilMedico` //

CREATE PROCEDURE `RegistrarPerfilMedico`(
    IN p_user_id             INT UNSIGNED,
    IN p_nombre              VARCHAR(150),
    IN p_especialidad        VARCHAR(100),
    IN p_cedula_profesional  VARCHAR(50),
    IN p_cedula_especialidad VARCHAR(50),
    IN p_celular             VARCHAR(20),
    IN p_universidad_id      INT UNSIGNED,
    IN p_lugar_id            INT UNSIGNED
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
        `user_id`, `nombre_completo`, `especialidad`, `cedula_profesional`, `cedula_especialidad`, `celular`,
        `universidad_id`, `lugar_trabajo_id`, `estado_id`, `total_ordenes`, `creado_en`
    ) VALUES (
        p_user_id, p_nombre, p_especialidad, p_cedula_profesional, p_cedula_especialidad, p_celular,
        p_universidad_id, p_lugar_id, 1, 0, NOW()
    ) ON DUPLICATE KEY UPDATE
        `nombre_completo` = p_nombre,
        `especialidad` = p_especialidad,
        `cedula_profesional` = p_cedula_profesional,
        `cedula_especialidad` = p_cedula_especialidad,
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
