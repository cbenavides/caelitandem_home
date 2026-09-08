#!/usr/bin/env bash
# ==============================================================================
# LAESH — disk_monitor.sh
# Monitoreo de espacio en disco /opt/laesh y alerta si supera umbral.
# Instalado por 07_security_harden.sh como cron diario (root, 06:00 AM).
#
# Umbrales:
#   WARN  ≥ 70%  → entrada WARNING en log + alerta SMTP
#   CRIT  ≥ 85%  → entrada CRITICAL + resumen de logs grandes + alerta SMTP
#
# Alerta SMTP: vía send_alert.sh (swaks.conf root:root).
# ==============================================================================

LOG="/opt/laesh/logs/disk-monitor.log"
SEND_ALERT="/opt/laesh/scripts/send_alert.sh"
WARN_PCT=70
CRIT_PCT=85
TS=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname -s)

# ── Uso de /opt/laesh ────────────────────────────────────────────────────────
USED_PCT=$(df /opt/laesh 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}')
AVAIL=$(df -h /opt/laesh 2>/dev/null | awk 'NR==2 {print $4}')
TOTAL=$(df -h /opt/laesh 2>/dev/null | awk 'NR==2 {print $2}')

if [[ -z "$USED_PCT" ]]; then
    echo "[$TS] [ERROR] No se pudo leer df /opt/laesh" >> "$LOG"
    exit 1
fi

# ── Evaluar umbral /opt/laesh ─────────────────────────────────────────────────
if (( USED_PCT >= CRIT_PCT )); then
    LEVEL="CRITICAL"
    echo "[$TS] [$LEVEL] /opt/laesh: ${USED_PCT}% usado — ${AVAIL} libre de ${TOTAL}" >> "$LOG"
    # Top 10 archivos de log más grandes (posibles culpables)
    echo "[$TS] [$LEVEL] Top logs por tamaño:" >> "$LOG"
    find /opt/laesh/logs -type f -name "*.log" -printf '%s\t%p\n' 2>/dev/null \
        | sort -rn | head -10 \
        | awk '{printf "  %s MB\t%s\n", int($1/1048576), $2}' >> "$LOG"
    UPLOAD_SIZE=$(du -sh /opt/laesh/uploads 2>/dev/null | cut -f1)
    echo "[$TS] [$LEVEL] /opt/laesh/uploads: ${UPLOAD_SIZE}" >> "$LOG"
    # ── Alerta SMTP ──────────────────────────────────────────────────────────
    TOP_LOGS=$(find /opt/laesh/logs -type f -name "*.log" -printf '%s\t%p\n' 2>/dev/null \
        | sort -rn | head -5 \
        | awk '{printf "  %s MB  %s\n", int($1/1048576), $2}')
    bash "$SEND_ALERT" \
        "🚨 DISCO CRÍTICO ≥${CRIT_PCT}% en ${HOST}" \
        "/opt/laesh: ${USED_PCT}% usado — solo ${AVAIL} libres de ${TOTAL}.\n\nTop logs:\n${TOP_LOGS}\n\nuploads: ${UPLOAD_SIZE}\n\nAcción urgente: rotar o limpiar logs / backups antiguos."

elif (( USED_PCT >= WARN_PCT )); then
    LEVEL="WARNING"
    echo "[$TS] [$LEVEL] /opt/laesh: ${USED_PCT}% usado — ${AVAIL} libre de ${TOTAL}" >> "$LOG"
    # ── Alerta SMTP ──────────────────────────────────────────────────────────
    bash "$SEND_ALERT" \
        "⚠️ Disco en WARNING ≥${WARN_PCT}% en ${HOST}" \
        "/opt/laesh: ${USED_PCT}% usado — ${AVAIL} libres de ${TOTAL}.\n\nVerificar tendencia antes de que llegue al ${CRIT_PCT}% crítico."
else
    LEVEL="OK"
    echo "[$TS] [$LEVEL] /opt/laesh: ${USED_PCT}% usado — ${AVAIL} libre de ${TOTAL}" >> "$LOG"
fi

# ── Verificar también el root filesystem ─────────────────────────────────────
ROOT_PCT=$(df / 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}')
if (( ROOT_PCT >= CRIT_PCT )); then
    echo "[$TS] [CRITICAL] Filesystem raíz: ${ROOT_PCT}% — URGENTE: limpiar /var/cache o logs del sistema" >> "$LOG"
    bash "$SEND_ALERT" \
        "🚨 RAÍZ CRÍTICA ≥${CRIT_PCT}% en ${HOST}" \
        "Filesystem /: ${ROOT_PCT}% usado.\n\nAcción urgente:\n  sudo apt clean\n  sudo journalctl --vacuum-size=200M\n  du -sh /var/log/* | sort -rh | head -10"
elif (( ROOT_PCT >= WARN_PCT )); then
    echo "[$TS] [WARNING]  Filesystem raíz: ${ROOT_PCT}% usado" >> "$LOG"
    bash "$SEND_ALERT" \
        "⚠️ Raíz en WARNING ≥${WARN_PCT}% en ${HOST}" \
        "Filesystem /: ${ROOT_PCT}% usado. Vigilar antes de llegar al ${CRIT_PCT}%."
fi

exit 0
