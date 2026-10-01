#!/usr/bin/env bash
# ==============================================================================
# LAESH — ws_bridge_check.sh
# Verifica que PHP (FPM y crons) y swoole-laesh usen la MISMA llave interna del
# bridge (/publish, /revoke). Si difieren, Swoole responde 403 y ninguna
# notificación llega en tiempo real (incidente 2026-09-30 21:42–22:00, PEN-LAESH-18).
#
# Compara huellas (8 hex del SHA-256 de la llave, no reversibles):
#   • Swoole:   token_fp de GET http://127.0.0.1:9502/status
#   • PHP-FPM:  derivada de env[LAESH_JWT_SECRET] del pool laesh.conf
#   • Crons:    derivada de LAESH_JWT_SECRET de /etc/cron.d/laesh-* (solo si root)
# Llave = hash_hmac('sha256', 'ws-internal-bridge', LAESH_JWT_SECRET) — mismo cálculo
# que Notifier::resolveInternalToken() y swoole_server.php.
# El secreto nunca se imprime ni pasa por argumentos: llega al proceso php por env.
#
# Uso:   bash ws_bridge_check.sh          (deploy.sh lo ejecuta vía ssh 'bash -s')
# Salida: 0 = coinciden · 1 = DESFASE · 2 = no verificable (Swoole caído o sin token_fp)
# ==============================================================================
set -uo pipefail

STATUS_URL="${LAESH_WS_STATUS_URL:-http://127.0.0.1:9502/status}"
PHP_BIN="$(command -v php8.3 || command -v php || true)"
POOL="${LAESH_FPM_POOL:-$(ls /etc/php/*/fpm/pool.d/laesh.conf 2>/dev/null | head -1)}"

[[ -n "$PHP_BIN" ]] || { echo "ws_bridge_check: php no encontrado"; exit 2; }

# Huella de la llave derivada de un secreto (recibido por env, nunca por argv)
fp_de_secreto() {
    S="$1" "$PHP_BIN" -r 'echo substr(hash("sha256", hash_hmac("sha256", "ws-internal-bridge", getenv("S"))), 0, 8);'
}
# Valor de LAESH_JWT_SECRET en un archivo (pool: env[...] = "..." · cron/.env: KEY=valor)
secreto_de() {
    local v
    v="$(sed -n -e 's/^env\[LAESH_JWT_SECRET\][[:space:]]*=[[:space:]]*//p' -e 's/^LAESH_JWT_SECRET=//p' "$1" 2>/dev/null | tail -1)"
    v="${v#\"}"; v="${v%\"}"
    printf '%s' "$v"
}

status_json="$(curl -sf --max-time 5 "$STATUS_URL" 2>/dev/null)" \
    || { echo "ws_bridge_check: swoole-laesh no responde en ${STATUS_URL}"; exit 2; }
fp_swoole="$(printf '%s' "$status_json" | "$PHP_BIN" -r '$j = json_decode(stream_get_contents(STDIN), true); echo $j["token_fp"] ?? "";')"
[[ -n "$fp_swoole" ]] || { echo "ws_bridge_check: /status sin token_fp (swoole_server.php anterior al 2026-10-01)"; exit 2; }

rc=0
reporte="swoole=${fp_swoole}"

if [[ -n "$POOL" && -r "$POOL" ]]; then
    sec="$(secreto_de "$POOL")"
    if [[ -n "$sec" ]]; then
        fp="$(fp_de_secreto "$sec")"
        reporte+=" php-fpm=${fp}"
        [[ "$fp" == "$fp_swoole" ]] || { reporte+="(≠)"; rc=1; }
    fi
else
    reporte+=" php-fpm=?(pool no legible)"
fi

# Crons: solo legibles por root (monitor_services.sh corre como root)
for f in /etc/cron.d/laesh-notificaciones-retry /etc/cron.d/laesh-cache-renew; do
    [[ -r "$f" ]] || continue
    sec="$(secreto_de "$f")"
    [[ -n "$sec" ]] || continue
    fp="$(fp_de_secreto "$sec")"
    reporte+=" $(basename "$f")=${fp}"
    [[ "$fp" == "$fp_swoole" ]] || { reporte+="(≠)"; rc=1; }
done

if [[ $rc -eq 0 ]]; then
    echo "ws_bridge_check: OK — llave interna alineada (${reporte})"
else
    echo "ws_bridge_check: DESFASE — Swoole rechazará con 403 (${reporte}). Revisar LAESH_JWT_SECRET en /opt/laesh/configs/.env, pool laesh.conf y /etc/cron.d/laesh-*; luego reiniciar swoole-laesh."
fi
exit $rc
