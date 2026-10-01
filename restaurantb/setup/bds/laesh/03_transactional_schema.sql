-- =============================================================================
-- LAESH Bloc Digital — Script 03: Schema Transaccional
-- Tablas: CATALOGO_ESTADOS, PACIENTES, ORDENES,
--         RESULTADOS_PDF, NOTIFICACIONES,
-- (DETALLE_ORDENES retirada 2026-09-30: nunca tuvo filas — los estudios viven en
--  ordenes.estudios como JSON de nombres; retirada de KVM2 con m005, ver migrations/README.md)
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
--   • folios_control: tipo_documento, ultimo_folio
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
                        COMMENT 'Numérico puro (p.ej. "27"), generado atómicamente por folios_control — formato legado con prefijo LAESH-NNNNN descontinuado, ver 08_stored_procedures.sql',
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
  COMMENT='Solicitudes de análisis (cabecera) — folio_unico numérico puro (formato legado LAESH-NNNNN descontinuado)';

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
    `tipo_entrega`   ENUM('parcial','completo') NOT NULL DEFAULT 'parcial'
                       COMMENT 'P-LAESH-RESULTADOS-PARCIALES-01 (2026-09-23): criterio de Recepción al subir — parcial no transiciona la orden, completo sí (2→3)',
    `folio_extraido` VARCHAR(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                       COMMENT 'P-LAESH-FOLIO-EXTRAIDO-01 (2026-09-24): folio interno del equipo/software de laboratorio (ej. PxLab, NNNN-NNNN) extraído del PDF en servidor — best-effort, NULL si no se detecta',
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
    `titulo`          VARCHAR(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                        COMMENT 'Título conciso para encabezado de notificación (ej. Nueva Solicitud · #29, Paciente en Atención · #15)',
    `mensaje`         VARCHAR(500) COLLATE utf8mb4_unicode_ci NOT NULL,
    `leido`           TINYINT(1) NOT NULL DEFAULT 0,
    `actualizado_en`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                        COMMENT 'BUG-NOTIF-LEIDO-SYNC-01: se refresca al UPDATE leido — permite que el poll incremental detecte una transición no-leído→leído desde otro dispositivo/pestaña y reenvíe la fila una vez más',
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

-- P-LAESH-NOTIF-SEMANTICA-01 (2026-09-30) — desacoplamiento de título y cuerpo
-- para eliminar redundancias en notificaciones WS/Polling. Idempotente.
ALTER TABLE `notificaciones`
  ADD COLUMN IF NOT EXISTS `titulo` VARCHAR(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL
    COMMENT 'Título conciso para encabezado de notificación'
    AFTER `folio_referencia`;

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

-- P-LAESH-NOTIF-SUBTIPO-01 (2026-10-01) — corrección de raíz del hallazgo de
-- auditoría: `tipo` solo tiene 4 valores pero `orden_actualizada` cubre 5
-- acciones de negocio distintas (atención/entregada/cancelada-por-recepción/
-- cancelada-por-médico/genérica) y `resultados_listos` cubre 2 (parcial/
-- completo) — antes SOLO se distinguían por texto libre dentro de `mensaje`,
-- re-adivinado con stripos() en cada consumidor (frágil: se rompe si cambia
-- la redacción, no es indexable/agrupable en reportes, no distingue el actor
-- de forma confiable). `subtipo` lo graba el código explícitamente al crear
-- la notificación (Common\Notifier::persist()) — ya no se infiere nunca más
-- para filas nuevas. Idempotente.
ALTER TABLE `notificaciones`
  ADD COLUMN IF NOT EXISTS `subtipo` VARCHAR(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL
    COMMENT 'Acción de negocio exacta, ver Common\\Notifier::persist(). nueva_orden: creada. orden_actualizada: atencion|entregada|cancelada_recepcion|cancelada_medico|cancelada|generica. resultados_listos: parcial|completo. catalogo_actualizado: publicado.'
    AFTER `tipo`;

-- Backfill de filas existentes (previas a esta columna) — fuente de verdad
-- preferida: la columna `titulo` (ya calculada correctamente por la app al
-- insertar, no re-derivada de texto libre); fallback a `mensaje` solo para
-- filas donde `titulo` también esté vacío (legado anterior a esa columna).
-- Guardado contra re-ejecución con `WHERE subtipo IS NULL` en cada UPDATE.
UPDATE `notificaciones` SET `subtipo` = 'creada'
  WHERE `tipo` = 'nueva_orden' AND `subtipo` IS NULL;
UPDATE `notificaciones` SET `subtipo` = 'publicado'
  WHERE `tipo` = 'catalogo_actualizado' AND `subtipo` IS NULL;
UPDATE `notificaciones` SET `subtipo` = 'parcial'
  WHERE `tipo` = 'resultados_listos' AND `subtipo` IS NULL
    AND (`titulo` LIKE '%Parcial%' OR (`titulo` IS NULL AND `mensaje` LIKE '%parcial%'));
UPDATE `notificaciones` SET `subtipo` = 'completo'
  WHERE `tipo` = 'resultados_listos' AND `subtipo` IS NULL;
UPDATE `notificaciones` SET `subtipo` = 'atencion'
  WHERE `tipo` = 'orden_actualizada' AND `subtipo` IS NULL
    AND (`titulo` LIKE '%Atenci%' OR (`titulo` IS NULL AND (`mensaje` LIKE '%atención%' OR `mensaje` LIKE '%recibido%')));
UPDATE `notificaciones` SET `subtipo` = 'entregada'
  WHERE `tipo` = 'orden_actualizada' AND `subtipo` IS NULL
    AND (`titulo` LIKE '%Entregada%' OR (`titulo` IS NULL AND `mensaje` LIKE '%entregad%'));
-- Canceladas con texto explícito de actor (sin motivo personalizado) — confiable.
UPDATE `notificaciones` SET `subtipo` = 'cancelada_recepcion'
  WHERE `tipo` = 'orden_actualizada' AND `subtipo` IS NULL
    AND (`mensaje` LIKE '%Cancelada por Laesh%' OR `mensaje` LIKE '%Cancelada por recepci%');
UPDATE `notificaciones` SET `subtipo` = 'cancelada_medico'
  WHERE `tipo` = 'orden_actualizada' AND `subtipo` IS NULL
    AND `mensaje` LIKE '%Cancelada por el médico%';
-- Canceladas con motivo personalizado: el texto es IDÉNTICO entre recepción y
-- médico ("Paciente: X del Dr(a). Y — Motivo: Z") — el actor no es recuperable
-- retroactivamente de datos históricos; se marcan con el genérico 'cancelada'
-- en vez de adivinar. Todo registro NUEVO desde esta corrección sí distingue
-- el actor con certeza porque el código ya no necesita adivinarlo.
UPDATE `notificaciones` SET `subtipo` = 'cancelada'
  WHERE `tipo` = 'orden_actualizada' AND `subtipo` IS NULL
    AND (`titulo` LIKE '%Cancelada%' OR (`titulo` IS NULL AND `mensaje` LIKE '%Motivo:%'));
UPDATE `notificaciones` SET `subtipo` = 'generica'
  WHERE `tipo` = 'orden_actualizada' AND `subtipo` IS NULL;

-- Alineación de texto (2026-10-01, pedido explícito): "Cancelada por recepción"
-- → "Cancelada por Laesh" también en filas ya persistidas, para que el
-- histórico use la misma redacción que las notificaciones nuevas.
-- REPLACE() es sensible a mayúsculas/minúsculas (a diferencia de LIKE, que usa
-- la collation case-insensitive de la columna) — se cubren ambas variantes
-- encontradas en datos reales: "Cancelada por recepción" (formato actual) y
-- "cancelada por recepción" (formato legado más antiguo, ej. "La orden N fue
-- cancelada por recepción. Motivo: ...").
UPDATE `notificaciones` SET `mensaje` = REPLACE(`mensaje`, 'Cancelada por recepción', 'Cancelada por Laesh')
  WHERE `mensaje` LIKE '%Cancelada por recepción%' COLLATE utf8mb4_bin;
UPDATE `notificaciones` SET `mensaje` = REPLACE(`mensaje`, 'cancelada por recepción', 'cancelada por Laesh')
  WHERE `mensaje` LIKE '%cancelada por recepción%' COLLATE utf8mb4_bin;

-- P-LAESH-RESULTADOS-PARCIALES-01 (2026-09-23) — resultados parciales de
-- laboratorio: el laboratorio entrega los estudios de una orden en días
-- distintos, acumulados en el mismo PDF; Recepción decide con un radio
-- Parcial/Completado cuándo la orden queda realmente lista. tipo_entrega
-- ya viaja en el CREATE TABLE de resultados_pdf (arriba) para instalaciones
-- nuevas — este ALTER es para instalaciones ya corriendo.
ALTER TABLE `resultados_pdf`
  ADD COLUMN IF NOT EXISTS `tipo_entrega` ENUM('parcial','completo') NOT NULL DEFAULT 'parcial'
    COMMENT 'Criterio de Recepción al subir — parcial no transiciona la orden, completo sí (2→3)'
    AFTER `subido_por`;

-- P-LAESH-FOLIO-EXTRAIDO-01 (2026-09-24) — Recepción pidió mostrar, junto al
-- folio_unico interno de LAESH, el folio propio del equipo/software de
-- laboratorio (PxLab, formato NNNN-NNNN) que ya viene impreso en el PDF de
-- resultados, como referencia cruzada visual. Se extrae en servidor con PHP
-- puro (sin librerías ni binarios externos: descompresión de streams
-- FlateDecode vía gzuncompress() + regex sobre el texto plano resultante) al
-- momento de la subida, en RC\Negocio\Ordenes::extraerFolioLaboratorio().
-- Puramente informativo — NO participa en los criterios de búsqueda (LIKE)
-- de buscarOrdenes()/obtenerOrdenesRecientes()/obtenerOrdenesAnteriores(), y
-- la extracción nunca bloquea ni hace fallar la subida (best-effort, NULL
-- ante cualquier fallo). folio_extraido ya viaja en el CREATE TABLE de
-- resultados_pdf (arriba) para instalaciones nuevas — este ALTER es para
-- instalaciones ya corriendo.
ALTER TABLE `resultados_pdf`
  ADD COLUMN IF NOT EXISTS `folio_extraido` VARCHAR(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL
    COMMENT 'Folio interno del equipo/software de laboratorio (ej. PxLab, NNNN-NNNN) extraído del PDF en servidor'
    AFTER `tipo_entrega`;

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
-- WS_RECHAZOS_LOG — G-DEV-03 (2026-09-23) — auditoría de handshakes WS
-- rechazados por verifyWsJwt() en on('open'), con el motivo exacto.
-- Antes: un handshake rechazado no dejaba NINGÚN rastro (ws_conexiones_log
-- solo registra conexiones ACEPTADAS) — diagnosticar un rechazo intermitente
-- requería instrumentación temporal en vivo. jti/user_id son NULLABLE porque
-- varios motivos de rechazo (empty_token, malformed_token, invalid_signature,
-- invalid_payload) ocurren ANTES de poder leer el payload del JWT — no hay
-- jti/user_id que registrar en esos casos. Mismo puente HTTP inverso que
-- ws_conexiones_log (Swoole nunca toca MariaDB directamente).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ws_rechazos_log` (
    `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `motivo`         VARCHAR(32) COLLATE utf8mb4_unicode_ci NOT NULL
                       COMMENT 'empty_token|malformed_token|invalid_signature|invalid_payload|expired|jti_cache_miss|jti_revoked',
    `jti`            CHAR(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL
                       COMMENT 'NULL si el rechazo ocurrió antes de poder leer el payload',
    `user_id`        INT UNSIGNED DEFAULT NULL
                       COMMENT 'NULL si el rechazo ocurrió antes de poder leer el payload',
    `ip`             VARCHAR(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `rechazado_en`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_motivo_fecha` (`motivo`, `rechazado_en`),
    KEY `idx_jti` (`jti`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='G-DEV-03 — auditoría persistida de handshakes WS rechazados, con motivo exacto';

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
-- FOLIOS_CONTROL — Correlativo atómico de folios (numéricos puros "1", "2"… desde 2026-09-23)
-- D-redesign: tipo_documento (era serie), ultimo_folio (era ultimo_numero).
-- 2026-10-01: se retiraron prefijo/longitud (formato LAESH-NNNNN descontinuado).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `folios_control` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tipo_documento` VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL
                       COMMENT 'Discriminador: orden_laboratorio | factura | etc.',
    `ultimo_folio`   INT UNSIGNED NOT NULL DEFAULT 0
                       COMMENT 'Último número emitido — incrementar con SELECT ... FOR UPDATE',
    `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_tipo_documento` (`tipo_documento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Control de folios correlativos — usar SELECT ... FOR UPDATE para atomicidad';

SET FOREIGN_KEY_CHECKS = 1;
