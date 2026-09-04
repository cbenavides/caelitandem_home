#!/usr/bin/env bash
# ==============================================================================
# LAESH — laesh-stop.sh
# Detiene todos los servicios del stack en orden inverso
# Uso: sudo ./scripts/laesh-stop.sh
# ==============================================================================
set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }

echo "$(ts) [laesh-stop] Deteniendo stack LAESH..."

systemctl stop nginx      && echo "$(ts) [laesh-stop] ✓ Nginx detenido"       || true
systemctl stop swoole-laesh && echo "$(ts) [laesh-stop] ✓ Swoole detenido"    || true
systemctl stop php8.3-fpm && echo "$(ts) [laesh-stop] ✓ PHP-FPM detenido"    || true
systemctl stop mariadb    && echo "$(ts) [laesh-stop] ✓ MariaDB detenido"     || true

echo ""
echo "✅  Stack LAESH detenido."
