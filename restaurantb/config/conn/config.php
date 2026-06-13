<?php
/**
 * Configuración general del sistema AGUA v2
 * Este archivo centraliza las credenciales y rutas para facilitar la migración.
 */

// Configuración de la Base de Datos
define('DB_HOST', getenv('DB_HOST') ?: '127.0.0.1');
define('DB_PORT', (int)(getenv('DB_PORT') ?: 7002));
define('DB_USER', getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('DB_PASS') ?: 'comite_2026'); // Ajustar según entorno XAMPP
define('DB_NAME', getenv('DB_NAME') ?: 'aguayd_os');

// Configuración de Rutas
define('APP_ROOT', dirname(__DIR__));
define('URL_BASE', '/agua/'); // Ajustar si el alias en Apache de XAMPP cambia

// Configuración de Errores (Útil para desarrollo en Windows/PHP 7.4)
error_reporting(E_ALL);
ini_set('display_errors', 1);
?>
