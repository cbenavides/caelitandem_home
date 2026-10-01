-- =============================================================================
-- m006 — notificaciones.subtipo (2026-10-01)
--
-- Corrección de raíz: `tipo` solo tiene 4 valores (ENUM) pero `orden_actualizada`
-- cubre 5 acciones de negocio distintas (atención/entregada/cancelada-por-
-- recepción/cancelada-por-médico/genérica) y `resultados_listos` cubre 2
-- (parcial/completo) — antes SOLO se distinguían por texto libre dentro de
-- `mensaje`, re-adivinado con stripos() en cada consumidor (frágil, no
-- indexable/agrupable en reportes, no distingue el actor de forma confiable).
-- `subtipo` lo graba el código explícitamente al crear la notificación
-- (Common\Notifier::persist()) — ya no se infiere nunca más para filas nuevas.
--
-- Mismo contenido que el bloque equivalente en 03_transactional_schema.sql
-- (ese bloque cubre instalaciones NUEVAS vía --drop; este migration cubre la
-- BD ya viva de producción, que solo corre migrations/ en modo incremental).
-- Completamente idempotente — seguro de re-ejecutar.
-- =============================================================================

USE `laesh_db`;

ALTER TABLE `notificaciones`
  ADD COLUMN IF NOT EXISTS `subtipo` VARCHAR(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL
    COMMENT 'Acción de negocio exacta, ver Common\\Notifier::persist(). nueva_orden: creada. orden_actualizada: atencion|entregada|cancelada_recepcion|cancelada_medico|cancelada|generica. resultados_listos: parcial|completo. catalogo_actualizado: publicado.'
    AFTER `tipo`;

-- Backfill de filas existentes — fuente preferida: `titulo` (ya calculada
-- correctamente por la app al insertar); fallback a `mensaje` solo si
-- `titulo` también está vacío (legado anterior a esa columna).
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
-- Canceladas con motivo personalizado: el texto es idéntico entre recepción y
-- médico — el actor no es recuperable retroactivamente; se marcan genérico.
-- Todo registro NUEVO desde esta corrección sí distingue el actor con certeza.
UPDATE `notificaciones` SET `subtipo` = 'cancelada'
  WHERE `tipo` = 'orden_actualizada' AND `subtipo` IS NULL
    AND (`titulo` LIKE '%Cancelada%' OR (`titulo` IS NULL AND `mensaje` LIKE '%Motivo:%'));
UPDATE `notificaciones` SET `subtipo` = 'generica'
  WHERE `tipo` = 'orden_actualizada' AND `subtipo` IS NULL;

-- Alineación de texto (pedido explícito): "Cancelada por recepción" →
-- "Cancelada por Laesh" en filas ya persistidas. REPLACE() es sensible a
-- mayúsculas (a diferencia de LIKE) — se cubren ambas variantes encontradas.
UPDATE `notificaciones` SET `mensaje` = REPLACE(`mensaje`, 'Cancelada por recepción', 'Cancelada por Laesh')
  WHERE `mensaje` LIKE '%Cancelada por recepción%' COLLATE utf8mb4_bin;
UPDATE `notificaciones` SET `mensaje` = REPLACE(`mensaje`, 'cancelada por recepción', 'cancelada por Laesh')
  WHERE `mensaje` LIKE '%cancelada por recepción%' COLLATE utf8mb4_bin;
