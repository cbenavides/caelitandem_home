#!/usr/bin/env bash
# ==============================================================================
# LAESH — laesh-status.sh
# Resumen rápido del estado de todos los servicios del stack
# Uso: sudo ./scripts/laesh-status.sh
# ==============================================================================

ts() { date '+%Y-%m-%d %H:%M:%S'; }
ok()  { echo "  ✓  $1"; }
warn(){ echo "  △  $1"; }
err() { echo "  ✗  $1"; }

echo ""
echo "══════════════════════════════════════════════════════"
echo "  LAESH Bloc Digital — Stack Status  $(ts)"
echo "══════════════════════════════════════════════════════"

# MariaDB
if systemctl is-active --quiet mariadb; then
    VER=$(mariadb --version 2>/dev/null | grep -oP 'Distrib \K[\d.]+' || echo "?")
    ok "MariaDB $VER — activo"
else
    err "MariaDB — INACTIVO"
fi

# PHP-FPM
if systemctl is-active --quiet php8.3-fpm; then
    ok "PHP-FPM 8.3 — activo"
else
    err "PHP-FPM 8.3 — INACTIVO"
fi

# Swoole service
if systemctl is-active --quiet swoole-laesh; then
    ok "Swoole service — activo"
else
    err "Swoole service — INACTIVO"
fi

# Swoole HTTP bridge
if curl -sf --max-time 3 http://127.0.0.1:9502/status &>/dev/null; then
    ok "Swoole bridge /status — respondiendo"
else
    warn "Swoole bridge /status — sin respuesta"
fi

# Nginx
if systemctl is-active --quiet nginx; then
    ok "Nginx — activo"
else
    err "Nginx — INACTIVO"
fi

# UFW
if ufw status 2>/dev/null | grep -q "Status: active"; then
    ok "UFW Firewall — activo"
else
    warn "UFW Firewall — inactivo o no instalado"
fi

# Swap
SWAP=$(free -h | awk '/Swap:/ {print $2}')
if [[ "$SWAP" == "0B" || -z "$SWAP" ]]; then
    warn "Swap — 0 (¿fallocate no ejecutado?)"
else
    ok "Swap — $SWAP disponible"
fi

# Disco /opt/laesh
DISK=$(df -h /opt/laesh 2>/dev/null | awk 'NR==2 {print $4 " libre de " $2 " ("$5" usado)"}')
echo "  📁  Disco /opt/laesh: $DISK"

# Logs recientes (últimas 5 líneas de error)
echo ""
echo "── Últimos errores Nginx ────────────────────────────"
tail -5 /opt/laesh/logs/nginx-error.log 2>/dev/null || echo "  (sin log)"

echo "── Últimos errores PHP-FPM ──────────────────────────"
tail -5 /opt/laesh/logs/php-fpm-error.log 2>/dev/null || echo "  (sin log)"

echo "══════════════════════════════════════════════════════"
