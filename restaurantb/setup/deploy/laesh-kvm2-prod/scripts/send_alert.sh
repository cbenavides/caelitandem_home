#!/usr/bin/env bash
# ==============================================================================
# LAESH — send_alert.sh
# Envía alerta por correo vía swaks usando /opt/laesh/configs/swaks.conf.
#
# Uso:
#   send_alert.sh "Asunto" "Cuerpo del mensaje"
#   send_alert.sh "CRÍTICO: Nginx caído" "$(hostname) $(date '+%F %T') — Nginx no responde tras 3 reintentos"
#
# Salida:
#   0 = correo enviado correctamente
#   1 = fallo de envío (swaks no disponible o error SMTP)
#
# Seguridad:
#   swaks.conf tiene chmod 600 root:root — este script debe ejecutarse como root.
#   El cuerpo del mensaje NO debe incluir contraseñas ni tokens.
# ==============================================================================

SWAKS_CFG="/opt/laesh/configs/swaks.conf"
ALERT_LOG="/opt/laesh/logs/alerts-smtp.log"
HOSTNAME_SHORT="$(hostname -s)"
TS="$(date '+%Y-%m-%d %H:%M:%S')"

SUBJECT="${1:-Alerta LAESH KVM2}"
BODY="${2:-Sin detalle}"

# ── Verificar dependencias ────────────────────────────────────────────────────
if ! command -v swaks &>/dev/null; then
    echo "[$TS] [ERROR] swaks no instalado — apt-get install -y swaks" >> "$ALERT_LOG"
    exit 1
fi

if [ ! -f "$SWAKS_CFG" ]; then
    echo "[$TS] [ERROR] swaks.conf no encontrado: $SWAKS_CFG" >> "$ALERT_LOG"
    exit 1
fi

# ── Componer cuerpo con contexto del servidor ─────────────────────────────────
FULL_BODY="[LAESH KVM2 — ${HOSTNAME_SHORT}]
Timestamp : ${TS}
Host      : $(hostname -f 2>/dev/null || hostname)
IP pública: $(curl -sf --max-time 5 https://api.ipify.org 2>/dev/null || echo '?')

${BODY}

────────────────────────────────────────────────
Estado del stack al momento de la alerta:
$(systemctl is-active nginx php8.3-fpm mariadb swoole-laesh 2>/dev/null \
  | paste - - - - \
  | awk 'BEGIN{split("nginx php8.3-fpm mariadb swoole-laesh",s," ")} \
         {for(i=1;i<=NF;i++) printf "  %-20s %s\n", s[i], $i}' 2>/dev/null || echo '  (no disponible)')
────────────────────────────────────────────────
Logs recientes:
$(tail -5 /opt/laesh/logs/monitor-services.log 2>/dev/null || echo '  (sin log)')
"

# ── Enviar ────────────────────────────────────────────────────────────────────
SWAKS_OUT=$(swaks \
    --config "$SWAKS_CFG" \
    --h-Subject "[LAESH KVM2] ${SUBJECT}" \
    --add-header "X-Monitor-Host: ${HOSTNAME_SHORT}" \
    --body "$FULL_BODY" 2>&1)

SWAKS_RC=$?

if [ $SWAKS_RC -eq 0 ]; then
    echo "[$TS] [OK] Alerta enviada: ${SUBJECT}" >> "$ALERT_LOG"
    exit 0
else
    echo "[$TS] [ERROR] Fallo al enviar alerta (rc=$SWAKS_RC): ${SUBJECT}" >> "$ALERT_LOG"
    echo "[$TS] [ERROR] swaks output: $(echo "$SWAKS_OUT" | head -3)" >> "$ALERT_LOG"
    exit 1
fi
