-- =============================================================================
-- m008 — Parametrizaciones pendientes en pantalla Admin (2026-10-01)
--
-- Cierra PEN-LAESH-01, 02, 03 y 04 (docs-dev/runbook-pendientes-laesh.md):
--   1. notif_polling_http_interval_sec — intervalo (segundos) del polling HTTP
--      de respaldo cuando el WebSocket no está disponible. Antes fijo en 120s
--      dentro de ws-client.js.
--   2. auto_cierre_resultados_dias — días que una orden puede permanecer en
--      "Resultados Listos" (estado 3) sin que Recepción la entregue, antes de
--      que el cron la cierre automáticamente (pasa a estado 4).
--   3. draft_order_ttl_horas — horas de vigencia del borrador local de
--      solicitud médica (medicos.js) antes de descartarse por antigüedad.
--      El mecanismo cliente ya soporta este valor (data-draft-ttl-hours);
--      antes nunca se poblaba desde configuración, siempre usaba el default
--      canónico de 12h hardcodeado en la vista.
--   4. notif_retencion_dias — días de antigüedad a partir de los cuales el
--      cron de retención purga físicamente notificaciones YA LEÍDAS (las no
--      leídas nunca se purgan, sin importar su antigüedad, para no borrar un
--      aviso antes de que alguien llegue a verlo).
--
-- Completamente idempotente — seguro de re-ejecutar.
-- =============================================================================

USE `laesh_db`;

INSERT INTO `configuraciones` (`clave`, `valor`, `descripcion`) VALUES
    ('notif_polling_http_interval_sec', '120',
     'Segundos entre cada sondeo HTTP de respaldo cuando el WebSocket no está disponible (1 a 600 segundos). PEN-LAESH-01.'),
    ('auto_cierre_resultados_dias', '5',
     'Días que una orden puede permanecer en "Resultados Listos" sin ser entregada antes de que el sistema la cierre automáticamente (1 a 30 días). PEN-LAESH-02.'),
    ('draft_order_ttl_horas', '12',
     'Horas de vigencia del borrador local de una solicitud médica en redacción antes de descartarse por antigüedad (1 a 72 horas). PEN-LAESH-03.'),
    ('notif_retencion_dias', '30',
     'Días de antigüedad a partir de los cuales se purgan físicamente las notificaciones ya leídas (7 a 365 días). Las no leídas nunca se purgan. PEN-LAESH-04.')
ON DUPLICATE KEY UPDATE
    `descripcion` = VALUES(`descripcion`);
