-- =============================================================================
-- LAESH Bloc Digital — Script 03: Schema Transaccional
-- Tablas: PACIENTES, CATALOGO_ESTADOS, ORDENES, DETALLE_ORDENES,
--         RESULTADOS_PDF, NOTIFICACIONES, NOTAS_ORDEN,
--         HISTORIAL_ESTADOS_ORDEN, FOLIOS_CONTROL
-- Idempotente: CREATE TABLE IF NOT EXISTS.
-- =============================================================================

USE `laesh_db`;

-- ---------------------------------------------------------------------------
-- CATALOGO_ESTADOS — Estados operativos de una orden
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `catalogo_estados` (
    `id`          TINYINT UNSIGNED NOT NULL,
    `nombre`      VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL,
    `descripcion` VARCHAR(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `color_hex`   CHAR(7) DEFAULT '#6B7280' COMMENT 'Color UI para badges de estado',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Estados de orden: 1=Pendiente, 2=En proceso, 3=Listo, 4=Entregado, 5=Cancelado';

-- ---------------------------------------------------------------------------
-- PACIENTES — Datos demográficos (inmutables una vez registrados)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pacientes` (
    `id`               INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `nombre`           VARCHAR(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `apellido_paterno` VARCHAR(100) COLLATE utf8mb4_unicode_ci NOT NULL,
    `apellido_materno` VARCHAR(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `fecha_nacimiento` DATE DEFAULT NULL,
    `sexo`             ENUM('H','M','Otro') NOT NULL,
    `telefono`         VARCHAR(20) DEFAULT NULL,
    `creado_en`        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_apellido` (`apellido_paterno`, `apellido_materno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Registro demográfico de pacientes';

-- ---------------------------------------------------------------------------
-- ORDENES — Solicitud digital de análisis (cabecera)
-- D-01: edad_al_emitir vive AQUÍ, no en pacientes (captura histórica del momento).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ordenes` (
    `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `folio`           VARCHAR(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'LAESH-NNNNN, generado por folios_control',
    `paciente_id`     INT UNSIGNED NOT NULL,
    `medico_id`       INT UNSIGNED NOT NULL COMMENT 'FK users.id (rol MEDICO)',
    `recepcion_id`    INT UNSIGNED DEFAULT NULL COMMENT 'FK users.id (rol RECEPCION) — quién capturó',
    `estado_id`       TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'FK catalogo_estados.id',
    `edad_al_emitir`  TINYINT UNSIGNED NOT NULL COMMENT 'D-01: edad clínica en el momento de emisión',
    `diagnostico`     VARCHAR(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `otros_estudios`  VARCHAR(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `estudios`        TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'JSON array de nombres (desnormalización para solicitud digital)',
    `creado_en`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `actualizado_en`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_folio` (`folio`),
    KEY `idx_paciente`  (`paciente_id`),
    KEY `idx_medico`    (`medico_id`),
    KEY `idx_estado`    (`estado_id`),
    KEY `idx_creado`    (`creado_en`),
    CONSTRAINT `fk_orden_paciente` FOREIGN KEY (`paciente_id`) REFERENCES `pacientes` (`id`),
    CONSTRAINT `fk_orden_estado`   FOREIGN KEY (`estado_id`)   REFERENCES `catalogo_estados` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Solicitudes de análisis (cabecera) — folio LAESH-NNNNN';

-- ---------------------------------------------------------------------------
-- DETALLE_ORDENES — Estudios individuales dentro de una orden
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `detalle_ordenes` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `orden_id`    INT UNSIGNED NOT NULL,
    `estudio_id`  INT UNSIGNED NOT NULL,
    `precio_snap` DECIMAL(10,2) DEFAULT NULL COMMENT 'Precio al momento de la orden (snapshot)',
    PRIMARY KEY (`id`),
    KEY `idx_orden` (`orden_id`),
    CONSTRAINT `fk_detalle_orden`   FOREIGN KEY (`orden_id`)   REFERENCES `ordenes` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_detalle_estudio` FOREIGN KEY (`estudio_id`) REFERENCES `estudios` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Estudios individuales por orden (N:M ordenes ↔ estudios)';

-- ---------------------------------------------------------------------------
-- RESULTADOS_PDF — Archivo PDF de resultados entregado al médico
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `resultados_pdf` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `orden_id`     INT UNSIGNED NOT NULL,
    `nombre_archivo` VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL,
    `ruta_storage` VARCHAR(500) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Path en filesystem de la VM OCI',
    `subido_por`   INT UNSIGNED DEFAULT NULL COMMENT 'FK users.id',
    `creado_en`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_orden` (`orden_id`),
    CONSTRAINT `fk_pdf_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='PDFs de resultados de laboratorio vinculados a órdenes';

-- ---------------------------------------------------------------------------
-- NOTIFICACIONES — SSOT de notificaciones con soporte QoS híbrido
-- QoS: slow-path (BD) + fast-path (Swoole WS) + fallback (AJAX poll)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `notificaciones` (
    `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `destinatario_id` INT UNSIGNED NOT NULL COMMENT 'FK users.id (médico o recepción)',
    `tipo`            ENUM('nueva_orden','resultados_listos') NOT NULL,
    `folio_referencia` VARCHAR(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'LAESH-NNNNN de la orden referenciada',
    `mensaje`         VARCHAR(500) COLLATE utf8mb4_unicode_ci NOT NULL,
    `leido`           TINYINT(1) NOT NULL DEFAULT 0,
    `entregado_ws`    TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Fast-path: 1 = entregado vía Swoole WS',
    `retry_count`     TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Intentos de entrega WS fallidos',
    `creado_en`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_destinatario` (`destinatario_id`),
    KEY `idx_fallback_poll` (`destinatario_id`, `entregado_ws`, `leido`)
      COMMENT 'Índice para poll: WHERE destinatario_id=? AND (entregado_ws=0 OR leido=0)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Notificaciones sistema — SSOT QoS: Swoole WS + fallback AJAX poll';

-- ---------------------------------------------------------------------------
-- NOTAS_ORDEN — Comentarios internos sobre una orden (recepción ↔ médico)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `notas_orden` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `orden_id`   INT UNSIGNED NOT NULL,
    `autor_id`   INT UNSIGNED NOT NULL COMMENT 'FK users.id',
    `nota`       TEXT COLLATE utf8mb4_unicode_ci NOT NULL,
    `creado_en`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_orden` (`orden_id`),
    CONSTRAINT `fk_nota_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Notas internas por orden entre recepción y médico';

-- ---------------------------------------------------------------------------
-- HISTORIAL_ESTADOS_ORDEN — Movimientos de estado de órdenes (trazabilidad)
-- D-06: Tabla de "movimientos" — fuente de verdad para reportes de tiempos.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `historial_estados_orden` (
    `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `orden_id`     INT UNSIGNED NOT NULL,
    `estado_desde` TINYINT UNSIGNED DEFAULT NULL COMMENT 'FK catalogo_estados.id (NULL si es creación)',
    `estado_hasta` TINYINT UNSIGNED NOT NULL COMMENT 'FK catalogo_estados.id',
    `cambiado_por` INT UNSIGNED DEFAULT NULL COMMENT 'FK users.id',
    `observacion`  VARCHAR(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    `creado_en`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_orden`     (`orden_id`),
    KEY `idx_creado`    (`creado_en`),
    CONSTRAINT `fk_hist_orden` FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Movimientos de estado por orden — auditoría de transiciones y tiempos de atención';

-- ---------------------------------------------------------------------------
-- FOLIOS_CONTROL — Correlativo atómico de folios LAESH-NNNNN
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `folios_control` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `serie`          VARCHAR(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'LAESH'
                       COMMENT 'Prefijo de serie (ej: LAESH)',
    `ultimo_numero`  INT UNSIGNED NOT NULL DEFAULT 0,
    `actualizado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_serie` (`serie`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Control de folios correlativos — usar SELECT ... FOR UPDATE para atomicidad';
