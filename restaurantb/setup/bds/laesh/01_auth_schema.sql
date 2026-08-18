-- =============================================================================
-- LAESH Bloc Digital — Script 01: Auth Schema (Delight-PHP/Auth)
-- =============================================================================
-- IMPORTANTE: Las tablas de Delight-Auth (users, users_remembered,
-- users_throttling, users_audit_log, users_2fa, users_confirmations,
-- users_resets) se crean EXCLUSIVAMENTE mediante $auth->install().
-- Este script NO contiene DDL manual para esas tablas.
-- Ver Decisión D-12 en et/DECISIONS.md y Regla R14.7.
-- =============================================================================
-- Para instalar el schema Delight-Auth, ejecutar desde PHP:
--
--   require_once 'commons/autoload.php';
--   require_once 'commons/commons.php';
--   $pdo = \Common\DB::connect();
--   $auth = new \Delight\Auth\Auth($pdo);
--   $auth->install();
--
-- O bien ejecutar el script de instalación:
--   php laesh-swbldi/commons/install_auth.php
-- =============================================================================

USE `laesh_db`;

-- Script placeholder: instrucción para el instalador.
-- No contiene DDL — ver comentario de cabecera.
SELECT 'Delight-Auth DDL: ejecutar $auth->install() desde PHP antes de continuar.' AS instruccion;
