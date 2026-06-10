#!/bin/sh
# ============================================================
#  docker-entrypoint-ssl.sh
#  Selecciona el certificado SSL correcto en runtime:
#    - Si el volumen /etc/apache2/ssl/ contiene server.crt
#      y server.key válidos → usa esos (cert real/custom)
#    - Si no → usa el auto-firmado de /etc/ssl/restaurantb/
#              generado durante el build de la imagen
#  Crea un symlink en /run/ssl-active/ apuntando al cert activo.
#  Luego cede la ejecución al entrypoint original de PHP-Apache.
# ============================================================

set -e

ACTIVE_DIR="/run/ssl-active"
VOLUME_CRT="/etc/apache2/ssl/server.crt"
VOLUME_KEY="/etc/apache2/ssl/server.key"
FALLBACK_CRT="/etc/ssl/restaurantb/server.crt"
FALLBACK_KEY="/etc/ssl/restaurantb/server.key"

mkdir -p "$ACTIVE_DIR"

if [ -f "$VOLUME_CRT" ] && [ -f "$VOLUME_KEY" ] && [ -s "$VOLUME_CRT" ]; then
    echo "[SSL] Usando certificado del volumen: $VOLUME_CRT"
    ln -sf "$VOLUME_CRT" "$ACTIVE_DIR/server.crt"
    ln -sf "$VOLUME_KEY" "$ACTIVE_DIR/server.key"
else
    echo "[SSL] Volumen ssl/ vacío — usando certificado auto-firmado (fallback)"
    ln -sf "$FALLBACK_CRT" "$ACTIVE_DIR/server.crt"
    ln -sf "$FALLBACK_KEY" "$ACTIVE_DIR/server.key"
fi

# Ceder al entrypoint original de la imagen php:8.3-apache
exec docker-php-entrypoint "$@"
