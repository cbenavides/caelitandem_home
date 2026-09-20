-- =============================================================================
-- LAESH Bloc Digital — Script 03: Schema Transaccional
-- Tablas: CATALOGO_ESTADOS, PACIENTES, ORDENES, DETALLE_ORDENES,
--         RESULTADOS_PDF, NOTIFICACIONES,
--         HISTORIAL_ESTADOS_ORDEN, FOLIOS_CONTROL
--
-- Redesign v2 — alineado con Tecnica_Modelo_Datos.html:
--   • catalogo_estados.valor       (era nombre)
--   • pacientes.nombre_completo    (era nombre+apellido_paterno+apellido_materno)
--   • pacientes.sexo ENUM('H','M') (se eliminó 'Otro')
--   • ordenes.folio_unico          (era folio)
--   • ordenes.hora_captura         (era creado_en; fecha_resultado agregado)
--   • notificaciones.user_id       (era destinatario_id)
--   • historial_estados_orden: estado_anterior_id, estado_nuevo_id, cambiado_por_user_id
--   • folios_control: tipo_documento, ultimo_folio, prefijo, longitud
-- Idempotente: CREATE TABLE IF NOT EXISTS.
-- =============================================================================

USE `laesh_db`;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------------
-- CATALOGO_ESTADOS — Estados operativos de una orden
-- D-redesign: columna 'valor' (no 'nombre') — alineado con ET y medicos.js
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `catalogo_estados` (
    `id`          TINYINT UNSIGNED NOT NULL,
    `valor`       VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL
                    COMMENT 'Valor canónico: Remitido|En Atención|Resultados Listos|Cerrada',
    `descripcion` VARCHAR(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `color_hex`   CHAR(7) DEFAULT '#6B7280' COMMENT 'Color UI para badges de estado',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Estados de orden: 1=Remitido, 2=En Atención, 3=Resultados Listos, 4=Cerrada, 5=Cancelada (H8 2026-09-20)';

-- ---------------------------------------------------------------------------
-- PACIENTES — Datos demográficos (inmutables una vez registrados)
-- D-redesign: nombre_completo VARCHAR(200) — campo único (localStorage → BD)
--             sexo ENUM('H','M') — sin 'Otro' (alineado con spec ET)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pacientes` (
    `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `nombre_completo` VARCHAR(200) COLLATE utf8mb4_unicode_ci NOT NULL
                        COMMENT 'Nombre y apellidos como string único — fuente: localStorage form medicos.php',
    `fecha_nacimiento` DATE DEFAULT NULL,
    `sexo`            ENUM('H','M') NOT NULL,
    `telefono`        VARCHAR(20) DEFAULT NULL,
    `creado_en`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FULLTEXT KEY `ft_nombre_completo` (`nombre_completo`)
                  COMMENT 'Búsqueda por nombre para autocomplete de recepción'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Registro demográfico de pacientes — nombre_completo como campo único';

-- ---------------------------------------------------------------------------
-- ORDENES — Solicitud digital de análisis (cabecera)
-- D-01: edad_al_emitir vive AQUÍ, no en pacientes (captura histórica del momento).
-- D-redesign: folio_unico (era folio), hora_captura (era creado_en), fecha_resultado (nuevo)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ordenes` (
    `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `folio_unico`     VARCHAR(20) COLLATE utf8mb4_unicode_ci NOT NULL
                        COMMENT 'LAESH-NNNNN — generado atómicamente por folios_control',
    `paciente_id`     INT UNSIGNED NOT NULL,
    `medico_id`       INT UNSIGNED NOT NULL COMMENT 'FK users.id (rol MEDICO)',
    `recepcion_id`    INT UNSIGNED DEFAULT NULL COMMENT 'FK users.id (rol RECEPCION) — quién capturó',
    `estado_id`       TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'FK catalogo_estados.id',
    `edad_al_emitir`  TINYINT UNSIGNED NOT NULL COMMENT 'D-01: edad clínica en el momento de emisión',
    `diagnostico`     VARCHAR(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                        COMMENT 'D-01: impresión diagnóstica libre del médico — máx 200 chars (spec ET)',
    `otros_estudios`  TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL
                        COMMENT 'D-01: estudios fuera del catálogo digitalizado (sin límite de chars)',
    `estudios`        TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL
                        COMMENT 'JSON array de nombres (desnormalización para solicitud digital)',
    `hora_captura`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                        COMMENT 'Timestamp de captura de la orden (era creado_en)',
    `fecha_resultado` DATETIME DEFAULT NULL
                        COMMENT 'Fecha/hora en que se subió el PDF de resultados',
    `actualizado_en`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_folio_unico` (`folio_unico`),
    KEY `idx_paciente`     (`paciente_id`),
    KEY `idx_medico`       (`medico_id`),
    KEY `idx_estado`       (`estado_id`),
    KEY `idx_hora_captura` (`hora_captura`),
    CONSTRAINT `fk_orden_paciente`  FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`id`),
    CONSTRAINT `fk_orden_estado`    FOREIGN KEY (`estado_id`)   REFERENCES `catalogo_estados` (`id`),
    CONSTRAINT `fk_orden_medico`    FOREIGN KEY (`medico_id`)    REFERENCES `users` (`id`),
    CONSTRAINT `fk_orden_recepcion` FOREIGN KEY (`recepcion_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Solicitudes de análisis (cabecera) — folio_unico LAESH-NNNNN';

-- ---------------------------------------------------------------------------
-- DETALLE_ORDENES — Estudios individuales dentro de una orden
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `detalle_ordenes` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `orden_id`    INT UNSIGNED NOT NULL,
    `estudio_id`  INT NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_orden` (`orden_id`),
    CONSTRAINT `fk_detalle_orden`   FOREIGN KEY (`orden_id`)   REFERENCES `ordenes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_detalle_estudio` FOREIGN KEY (`estudio_id`) REFERENCES `cat_estudios` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Estudios individuales por orden (N:M ordenes ↔ estudios)';

-- ---------------------------------------------------------------------------
-- RESULTADOS_PDF — Archivo PDF de resultados entregado al médico
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `resultados_pdf` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `orden_id`       INT UNSIGNED NOT NULL,
    `nombre_archivo` VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL,
    `ruta_storage`   VARCHAR(500) COLLATE utf8mb4_unicode_ci NOT NULL
                       COMMENT 'Path en filesystem de la VM OCI',
    `subido_por`     INT UNSIGNED DEFAULT NULL COMMENT 'FK users.id',
    `creado_en`      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_orden` (`orden_id`),
    KEY `idx_subido_por` (`subido_por`),
    CONSTRAINT `fk_pdf_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_pdf_subido_por` FOREIGN KEY (`subido_por`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='PDFs de resultados de laboratorio vinculados a órdenes';

-- ---------------------------------------------------------------------------
-- NOTIFICACIONES — SSOT de notificaciones con soporte QoS híbrido
-- QoS: slow-path (BD) + fast-path (Swoole WS) + fallback (AJAX poll)
-- D-redesign: user_id (era destinatario_id)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `notificaciones` (
    `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`         INT UNSIGNED NOT NULL COMMENT 'FK users.id (médico o recepción)',
    `tipo`            ENUM('nueva_orden','resultados_listos','orden_actualizada','catalogo_actualizado') NOT NULL,
    `folio_referencia` VARCHAR(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                        COMMENT 'folio_unico LAESH-NNNNN de la orden referenciada',
    `mensaje`         VARCHAR(500) COLLATE utf8mb4_unicode_ci NOT NULL,
    `leido`           TINYINT(1) NOT NULL DEFAULT 0,
    `entregado_ws`    TINYINT(1) NOT NULL DEFAULT 0
                        COMMENT 'Fast-path: 1 = entregado vía Swoole WS',
    `retry_count`     TINYINT UNSIGNED NOT NULL DEFAULT 0
                        COMMENT 'Intentos de entrega WS fallidos',
    `creado_en`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user`         (`user_id`),
    KEY `idx_fallback_poll` (`user_id`, `entregado_ws`, `leido`)
      COMMENT 'Índice para poll: WHERE user_id=? AND (entregado_ws=0 OR leido=0)',
    CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Notificaciones sistema — SSOT QoS: Swoole WS + fallback AJAX poll';

-- Gap 3 (auditoría WS 2026-09-18, §2.4c): 'catalogo_actualizado' agregado al ENUM.
-- Antes, ese evento no tenía fallback de persistencia — si Swoole estaba caído al
-- guardar un cambio de catálogo, ningún cliente se enteraba después. Idempotente:
-- re-declarar el mismo ENUM (o uno más amplio) no falla en ejecuciones repetidas.
ALTER TABLE `notificaciones`
  MODIFY COLUMN `tipo` ENUM('nueva_orden','resultados_listos','orden_actualizada','catalogo_actualizado') NOT NULL;

-- Deuda QoS-01 (2026-09-18) — estadísticas estructuradas de fallback WS: se agrega
-- fallback_reason (motivo corto del fallo cuando entregado_ws=0, poblado por
-- notifier.php) para poder distinguir timeout / http_error / respuesta inválida /
-- excepción, en vez de solo el bit binario que ya existía en entregado_ws.
-- ADD COLUMN IF NOT EXISTS: idempotente en MariaDB 10.4+ (re-ejecutar no falla).
-- La vista de estadísticas (vw_ws_fallback_stats) que consume esta columna vive
-- en 09_views.sql (SSOT de vistas del proyecto), no aquí.
-- Hallazgo 2026-09-19: 'no_recipients_connected' agregado — /publish respondía
-- status=success con sent_to_clients=0 (destinatario no conectado) y notifier.php
-- lo contaba como entrega exitosa; ahora se trata como fallback real.
ALTER TABLE `notificaciones`
  ADD COLUMN IF NOT EXISTS `fallback_reason` VARCHAR(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL
    COMMENT 'Motivo del fallo cuando entregado_ws=0: timeout|http_error_NNN|response_invalid|exception|no_curl_no_stream|no_recipients_connected'
    AFTER `retry_count`;

-- ---------------------------------------------------------------------------
-- WS_CONEXIONES_LOG — Gap 9 (auditoría WS 2026-09-18, §2.4c/§4.9)
-- Auditoría persistida de conexiones WebSocket — antes solo vivía en memoria
-- del proceso Swoole ($clients[$fd]), perdida en cada restart, sin registro de
-- quién estuvo conectado cuándo. Puente HTTP en dirección inversa a /publish:
-- Swoole (on open/close) → POST interno → este INSERT/UPDATE vía PHP-FPM.
-- Swoole nunca toca MariaDB directamente — mismo principio que evitó PDOPool
-- para el Gap 6 (revocación activa de sockets).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ws_conexiones_log` (
    `id`               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id`          INT UNSIGNED NOT NULL COMMENT 'FK users.id',
    `jti`              CHAR(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Identifica la sesión JWT — una fila por conexión WS',
    `role`             VARCHAR(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `ip`               VARCHAR(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'IPv4 o IPv6',
    `conectado_en`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `desconectado_en`  TIMESTAMP NULL DEFAULT NULL COMMENT 'NULL = sesión WS abierta o cierre nunca notificado (ej. crash del proceso)',
    PRIMARY KEY (`id`),
    KEY `idx_user_fecha` (`user_id`, `conectado_en`),
    KEY `idx_jti_abierta` (`jti`, `desconectado_en`)
      COMMENT 'Para el UPDATE de cierre: WHERE jti=? AND desconectado_en IS NULL'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Gap 9 — auditoría persistida de conexiones WebSocket (inicio/fin/IP)';

-- ---------------------------------------------------------------------------
-- HISTORIAL_ESTADOS_ORDEN — Movimientos de estado (trazabilidad completa)
-- D-06: Tabla de "movimientos" — fuente de verdad para reportes de tiempos.
-- D-redesign: estado_anterior_id, estado_nuevo_id, cambiado_por_user_id
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `historial_estados_orden` (
    `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `orden_id`             INT UNSIGNED NOT NULL,
    `estado_anterior_id`   TINYINT UNSIGNED DEFAULT NULL
                             COMMENT 'FK catalogo_estados.id (NULL si es creación)',
    `estado_nuevo_id`      TINYINT UNSIGNED NOT NULL
                             COMMENT 'FK catalogo_estados.id',
    `cambiado_por_user_id` INT UNSIGNED DEFAULT NULL
                             COMMENT 'FK users.id — quién realizó el cambio',
    `observacion`          VARCHAR(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `creado_en`            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_orden`   (`orden_id`),
    KEY `idx_creado`  (`creado_en`),
    KEY `idx_estado_ant` (`estado_anterior_id`),
    KEY `idx_estado_nue` (`estado_nuevo_id`),
    KEY `idx_cambiado_por` (`cambiado_por_user_id`),
    CONSTRAINT `fk_hist_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_hist_est_ant` FOREIGN KEY (`estado_anterior_id`) REFERENCES `catalogo_estados` (`id`),
    CONSTRAINT `fk_hist_est_nue` FOREIGN KEY (`estado_nuevo_id`) REFERENCES `catalogo_estados` (`id`),
    CONSTRAINT `fk_hist_cambiado` FOREIGN KEY (`cambiado_por_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Movimientos de estado por orden — auditoría y reportes de tiempos de atención';

-- ---------------------------------------------------------------------------
-- FOLIOS_CONTROL — Correlativo atómico de folios LAESH-NNNNN
-- D-redesign: tipo_documento (era serie), ultimo_folio (era ultimo_numero),
--             + prefijo (el prefijo string real) y longitud (ceros de LPAD)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `folios_control` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tipo_documento` VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL
                       COMMENT 'Discriminador: orden_laboratorio | factura | etc.',
    `prefijo`        VARCHAR(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'LAESH'
                       COMMENT 'Prefijo del folio — ej: LAESH → LAESH-00001',
    `longitud`       TINYINT UNSIGNED NOT NULL DEFAULT 5
                       COMMENT 'Dígitos con cero-padding en LPAD — ej: 5 → 00001',
    `ultimo_folio`   INT UNSIGNED NOT NULL DEFAULT 0
                       COMMENT 'Último número emitido — incrementar con SELECT ... FOR UPDATE',
    `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tipo_documento` (`tipo_documento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Control de folios correlativos — usar SELECT ... FOR UPDATE para atomicidad';

SET FOREIGN_KEY_CHECKS = 1;
