#!/bin/sh
# ============================================================
#  docker-entrypoint-fpm.sh — PHP-FPM entrypoint (restaurantb)
#  Reemplaza: docker-entrypoint-ssl.sh (que combinaba FPM + Apache SSL)
#
#  Solo hace lo necesario para PHP-FPM:
#    - Crear directorio de logs de la app (bind-mount ../www)
#    - Ceder al CMD (php-fpm)
#  El SSL y el proxy WS ahora son responsabilidad del contenedor nginx.
# ============================================================

set -e

# Directorio de logs de la app restaurant (necesita escritura)
mkdir -p /var/www/html/restaurant/logs
chmod 777 /var/www/html/restaurant/logs

exec "$@"
