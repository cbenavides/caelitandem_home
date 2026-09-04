#!/usr/bin/env bash
# ==============================================================================
# LAESH Bloc Digital — check_cert_expiry.sh
# Verifica vencimiento del cert TLS de laesh.mx
# Alerta si quedan < WARN_DAYS días (default: 14)
# Instalado por 07_security_harden.sh como cron semanal de root
# ==============================================================================
set -euo pipefail

DOMAIN="${LAESH_DOMAIN:-laesh.mx}"
WARN_DAYS="${WARN_DAYS:-14}"
LOG="/opt/laesh/logs/cert-expiry.log"

ts() { date '+%Y-%m-%d %H:%M:%S'; }

# ── Modo A: sin dominio configurado → salir silenciosamente ──────────────────
if [[ "$DOMAIN" == "laesh.mx" ]] && ! dig +short "$DOMAIN" | grep -q .; then
    echo "$(ts) [cert-expiry] SKIP: DNS no resuelve $DOMAIN (Modo A / sin DNS)" >> "$LOG"
    exit 0
fi

# ── Obtener fecha de expiración del cert en producción ───────────────────────
EXPIRY_DATE=$(openssl s_client -connect "${DOMAIN}:443" -servername "$DOMAIN" \
    </dev/null 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null \
    | cut -d= -f2) || {
    echo "$(ts) [cert-expiry] ERROR: no se pudo conectar a ${DOMAIN}:443" >> "$LOG"
    exit 1
}

# ── Calcular días restantes ───────────────────────────────────────────────────
EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

echo "$(ts) [cert-expiry] $DOMAIN — vence en $DAYS_LEFT días ($EXPIRY_DATE)" >> "$LOG"

# ── Alerta si quedan menos de WARN_DAYS días ──────────────────────────────────
if (( DAYS_LEFT < WARN_DAYS )); then
    MSG="⚠️  LAESH CERT EXPIRY WARNING: ${DOMAIN} vence en ${DAYS_LEFT} días (${EXPIRY_DATE})."
    MSG+=" Ejecutar: certbot renew --force-renewal"
    echo "$(ts) [cert-expiry] ALERT: $MSG" >> "$LOG"

    # Intentar renovación automática si certbot está disponible
    if command -v certbot &>/dev/null; then
        echo "$(ts) [cert-expiry] Intentando renovación automática..." >> "$LOG"
        certbot renew --quiet 2>>"$LOG" && \
            systemctl reload nginx >> "$LOG" 2>&1 && \
            echo "$(ts) [cert-expiry] Renovación exitosa." >> "$LOG" || \
            echo "$(ts) [cert-expiry] ERROR en renovación — revisión manual requerida." >> "$LOG"
    fi

    # Enviar alerta al journal del sistema (visible en journalctl)
    logger -t "laesh-cert-expiry" "$MSG"
    exit 2   # exit 2 = alerta (no error fatal para cron)
fi

echo "$(ts) [cert-expiry] OK: ${DAYS_LEFT} días restantes." >> "$LOG"
exit 0
