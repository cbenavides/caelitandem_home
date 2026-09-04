#!/usr/bin/env bash
# ==============================================================================
# LAESH — swoole-restart.sh
# Reinicia Swoole (ej. tras deploy de código, cambio de config WS)
# Uso: sudo ./scripts/swoole-restart.sh
# ==============================================================================
set -euo pipefail

ts() { date '+%Y-%m-%d %H:%M:%S'; }

echo "$(ts) [swoole-restart] Reiniciando Swoole..."
systemctl restart swoole-laesh

sleep 3

if curl -sf --max-time 5 http://127.0.0.1:9502/status &>/dev/null; then
    echo "$(ts) [swoole-restart] ✓ Swoole bridge /status — OK"
else
    echo "$(ts) [swoole-restart] ✗ Swoole bridge no responde" >&2
    journalctl -u swoole-laesh --since "1 minute ago" --no-pager | tail -20
    exit 1
fi
