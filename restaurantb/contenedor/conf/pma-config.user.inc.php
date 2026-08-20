<?php
// ============================================================
//  pma-config.user.inc.php — Configuración phpMyAdmin
//  Montado en /etc/phpmyadmin/config.user.inc.php
// ============================================================

// Blowfish secret para cookies de autenticación (mín. 32 chars)
$cfg['blowfish_secret'] = 'restaurantb_pma_secret_2026_cbm!';

// Modo de autenticación
$cfg['Servers'][1]['auth_type'] = 'cookie';

// Permitir conexión a cualquier host MySQL (útil en Docker)
$cfg['AllowArbitraryServer'] = true;

// BD de configuración phpMyAdmin (usuario pma)
$cfg['Servers'][1]['controluser'] = 'pma';
$cfg['Servers'][1]['controlpass'] = 'pma_pass_2026';
$cfg['Servers'][1]['pmadb']       = 'phpmyadmin';
