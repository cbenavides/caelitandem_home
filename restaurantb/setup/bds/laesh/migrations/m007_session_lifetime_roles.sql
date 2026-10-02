-- =============================================================================
-- m007 — Ciclo de Sesiones Diferenciadas por Rol y Hora Fija de Corte (2026-10-01)
--
-- Incorpora 4 claves de configuración en la tabla `configuraciones` para el
-- Proyecto 2 (LAESH Bloc Digital & Recepción):
--   1. session_expiration_time:      Hora fija del día (HH:MM 24h) de corte (default 04:30).
--   2. session_lifetime_medico_dias: Días de vigencia para Médicos (1 a 90, default 90).
--   3. session_lifetime_recepcion_dias: Días para Recepción (1 a 3, default 1).
--   4. session_lifetime_admin_dias:  Días para Administrador (1 a 7, default 1).
--
-- Completamente idempotente — seguro de re-ejecutar.
-- =============================================================================

USE `laesh_db`;

INSERT INTO `configuraciones` (`clave`, `valor`, `descripcion`) VALUES
    ('session_expiration_time', '04:30',
     'Hora fija del día en formato 24h (HH:MM) en que vencerán las sesiones al cumplirse sus días de vigencia. Aplica a los 3 roles (Médicos, Recepción, Admin). Recomendado: 04:30 (madrugada, antes del cron de las 05:00 AM).'),
    ('session_lifetime_medico_dias', '90',
     'Días consecutivos de sesión activa para Médicos sin solicitar contraseña (1 a 90 días). Cuenta con Auto-Refresh Server-Side cada 29 días mientras haya actividad clínica.'),
    ('session_lifetime_recepcion_dias', '1',
     'Días de sesión activa para Recepción en terminal compartida de mostrador (1 a 3 días). Vence a la hora global configurada para forzar inicio limpio en nuevo turno.'),
    ('session_lifetime_admin_dias', '1',
     'Días de sesión activa para Administrador del Sistema (1 a 7 días). Vence a la hora global. Protección perimetral para superusuario con acceso a infraestructura.')
ON DUPLICATE KEY UPDATE
    `descripcion` = VALUES(`descripcion`);
