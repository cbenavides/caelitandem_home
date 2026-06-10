-- ============================================================
--  00_remote_access.sql
--  Se ejecuta automáticamente en el primer arranque del
--  contenedor MariaDB (directorio docker-entrypoint-initdb.d).
--
--  Objetivo: permitir que el usuario de aplicación y root
--  sean accesibles desde CUALQUIER host de la red Docker
--  y desde hosts externos vía el puerto mapeado (DB_PORT).
-- ============================================================

-- Otorgar todos los privilegios al usuario de aplicación
-- desde cualquier host (requerido para acceso externo)
GRANT ALL PRIVILEGES ON `restaurantb`.* TO 'restaurantb_usr'@'%'
  IDENTIFIED BY 'rb_pass_2026';

-- Permitir conexión root desde red interna Docker y hosts LAN
-- (phpMyAdmin la usa internamente con host='db')
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'
  IDENTIFIED BY 'comite_2026'
  WITH GRANT OPTION;

FLUSH PRIVILEGES;
