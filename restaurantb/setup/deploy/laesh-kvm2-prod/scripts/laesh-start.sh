#!/usr/bin/env bash
# ==============================================================================
# LAESH — laesh-start.sh
# Arranca todos los servicios del stack en orden correcto
# Uso: sudo ./scripts/laesh-start.sh
# ==============================================================================
set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }

echo "$(ts) [laesh-start] Iniciando stack LAESH..."

systemctl start mariadb
echo "$(ts) [laesh-start] ✓ MariaDB"

systemctl start php8.3-fpm
echo "$(ts) [laesh-start] ✓ PHP-FPM 8.3"

systemctl start swoole-laesh
echo "$(ts) [laesh-start] ✓ Swoole"

systemctl start nginx
echo "$(ts) [laesh-start] ✓ Nginx"

sleep 2

# Verificar Swoole bridge
if curl -sf http://127.0.0.1:9502/status &>/dev/null; then
    echo "$(ts) [laesh-start] ✓ Swoole bridge /status OK"
else
    echo "$(ts) [laesh-start] △ Swoole bridge no responde aún (puede tardar unos segundos)"
fi

echo ""
echo "✅  Stack LAESH iniciado. Ver: sudo ./scripts/laesh-status.sh"
