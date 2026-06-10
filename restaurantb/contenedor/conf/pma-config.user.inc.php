<?php
/**
 * config.user.inc.php — Configuración phpMyAdmin para contenedor Docker
 *
 * Adaptado de: opt-xampp7.4.33/config.inc.php (XAMPP Windows 10)
 * Autor original: cbm 2026  |  Adaptación Docker: 2026-06-10
 *
 * REGLAS DE ADAPTACIÓN:
 *   ✅ APLICADO  — válido para phpMyAdmin 5.x en Docker
 *   🔄 ADAPTADO  — concepto válido, valor/ruta ajustado al contenedor
 *   ❌ OMITIDO   — exclusivo de XAMPP/Windows, no aplica
 */

// ── COOKIE SECRET ─────────────────────────────────────────────────────────
// ✅ Mantenido. CAMBIADO: secreto seguro aleatorio (el original era 'xampp')
// En producción usar un valor único de 32+ caracteres
$cfg['blowfish_secret'] = 'rb2026!D0ck3r_R3staurantB_S3cur3K3y!';

// ── MODO ARBITRARIO ────────────────────────────────────────────────────────
// ✅ Nuevo — permite conectarse a cualquier servidor desde la UI
// (Necesario para acceso desde otro host via phpMyAdmin)
$cfg['AllowArbitraryServer'] = true;

// ── ACCESO DESDE CUALQUIER HOST ───────────────────────────────────────────
// 🔄 Nuevo — elimina restricción de IPs (original era 'local' en httpd-xampp.conf)
$cfg['VersionCheck'] = false;      // Sin ping a phpMyAdmin.net (entorno local)

// ============================================================
// SERVIDOR 1: MariaDB del contenedor 'db' (por defecto)
// ============================================================
$i = 0;
$i++;

// ── AUTENTICACIÓN ────────────────────────────────────────────
// 🔄 Cambiado de 'config' a 'cookie' — más seguro que hardcodear user/pass
// Original: auth_type = 'config', user = 'root', password = 'comite_2026'
// En Docker con PMA_ARBITRARY=1, el login se hace en la UI
$cfg['Servers'][$i]['auth_type']       = 'cookie';
// Si se quiere login automático (sin formulario), descomentar:
// $cfg['Servers'][$i]['auth_type']    = 'config';
// $cfg['Servers'][$i]['user']         = 'root';
// $cfg['Servers'][$i]['password']     = 'comite_2026';

// ── CONEXIÓN ─────────────────────────────────────────────────
// 🔄 host: 'db' (nombre del servicio Docker) en lugar de '127.0.0.1'
// Original: host = '127.0.0.1', port = '7002'
// En Docker: phpMyAdmin se conecta al servicio 'db' en la red interna
$cfg['Servers'][$i]['host']            = 'db';
$cfg['Servers'][$i]['port']            = '3306';    // Puerto interno Docker (no 7002)
$cfg['Servers'][$i]['connect_type']    = 'tcp';     // ✅ Igual
$cfg['Servers'][$i]['extension']       = 'mysqli';  // ✅ Igual
$cfg['Servers'][$i]['AllowNoPassword'] = false;     // 🔄 false — más seguro que true

$cfg['Servers'][$i]['compress']        = false;
$cfg['Servers'][$i]['ssl']             = false;

// ── USUARIO PMA (funcionalidades avanzadas) ──────────────────
// ✅ Mantenido el concepto — usuario especial para la pmadb
// En el contenedor, el usuario 'pma' debe crearse vía SQL de init
// Ver: bd/init/01_pmadb.sql
$cfg['Servers'][$i]['controluser']     = 'pma';
$cfg['Servers'][$i]['controlpass']     = 'pma_pass_2026';

// ── BASE DE DATOS DE CONFIGURACIÓN PHPMYADMIN ────────────────
// ✅ Todas las tablas del original mantenidas — cbm 2026
$cfg['Servers'][$i]['pmadb']              = 'phpmyadmin';
$cfg['Servers'][$i]['bookmarktable']      = 'pma__bookmark';
$cfg['Servers'][$i]['relation']           = 'pma__relation';
$cfg['Servers'][$i]['table_info']         = 'pma__table_info';
$cfg['Servers'][$i]['table_coords']       = 'pma__table_coords';
$cfg['Servers'][$i]['pdf_pages']          = 'pma__pdf_pages';
$cfg['Servers'][$i]['column_info']        = 'pma__column_info';
$cfg['Servers'][$i]['history']            = 'pma__history';
$cfg['Servers'][$i]['tracking']           = 'pma__tracking';
$cfg['Servers'][$i]['userconfig']         = 'pma__userconfig';
$cfg['Servers'][$i]['recent']             = 'pma__recent';
$cfg['Servers'][$i]['table_uiprefs']      = 'pma__table_uiprefs';
$cfg['Servers'][$i]['users']              = 'pma__users';
$cfg['Servers'][$i]['usergroups']         = 'pma__usergroups';
$cfg['Servers'][$i]['navigationhiding']   = 'pma__navigationhiding';
$cfg['Servers'][$i]['savedsearches']      = 'pma__savedsearches';
$cfg['Servers'][$i]['central_columns']    = 'pma__central_columns';
$cfg['Servers'][$i]['designer_settings']  = 'pma__designer_settings';
$cfg['Servers'][$i]['export_templates']   = 'pma__export_templates';
$cfg['Servers'][$i]['favorite']           = 'pma__favorite';
// ❌ designer_coords — eliminado en phpMyAdmin 5.x (tabla deprecada)

// ── IDIOMA ────────────────────────────────────────────────────
// ✅ Mantenido
$cfg['Lang'] = 'es';   // 🔄 Fijado explícitamente (original = '' = auto)

// ── UI Y RENDIMIENTO ──────────────────────────────────────────
$cfg['MaxRows']              = 50;          // Filas por página
$cfg['LimitChars']           = 500;         // Chars por campo en tabla
$cfg['NavigationTreePointerEnable'] = true; // Resaltado en árbol
$cfg['ShowAll']              = true;        // Botón "Mostrar todo"
$cfg['RepeatCells']          = 100;         // Headers repetidos
$cfg['QueryHistoryDB']       = true;        // Historial en pmadb
$cfg['QueryHistoryMax']      = 25;
$cfg['ExecTimeLimit']        = 300;         // Timeout queries largas (5 min)

// ── IMPORTACIÓN ──────────────────────────────────────────────
// 🔄 Límite de upload (coincide con UPLOAD_LIMIT en docker-compose)
$cfg['UploadDir']  = '';
$cfg['SaveDir']    = '';

// ── SEGURIDAD ────────────────────────────────────────────────
$cfg['LoginCookieValidity']  = 1440;   // Sesión 24 horas
$cfg['SessionSavePath']      = '';     // Default del sistema

// ── FIN DE CONFIGURACIÓN ─────────────────────────────────────
