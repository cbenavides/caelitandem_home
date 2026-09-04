#!/usr/bin/env bash
# ==============================================================================
# LAESH — disk_monitor.sh
# Monitoreo de espacio en disco /opt/laesh y alerta si supera umbral.
# Instalado por 07_security_harden.sh como cron diario (root, 06:00 AM).
#
# Umbrales:
#   WARN  ≥ 70%  → entrada WARNING en /opt/laesh/logs/disk-monitor.log
#   CRIT  ≥ 85%  → entrada CRITICAL + resumen de logs grandes
#
# No envía email (no hay MTA configurado en KVM2 básico).
# Para alertas externas: redirigir CRIT a un webhook o integrar con UptimeRobot.
# ==============================================================================

LOG="/opt/laesh/logs/disk-monitor.log"
WARN_PCT=70
CRIT_PCT=85
TS=$(date '+%Y-%m-%d %H:%M:%S')

# ── Uso de /opt/laesh ────────────────────────────────────────────────────────
USED_PCT=$(df /opt/laesh 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}')
AVAIL=$(df -h /opt/laesh 2>/dev/null | awk 'NR==2 {print $4}')
TOTAL=$(df -h /opt/laesh 2>/dev/null | awk 'NR==2 {print $2}')

if [[ -z "$USED_PCT" ]]; then
    echo "[$TS] [ERROR] No se pudo leer df /opt/laesh" >> "$LOG"
    exit 1
fi

# ── Evaluar umbral ────────────────────────────────────────────────────────────
if (( USED_PCT >= CRIT_PCT )); then
    LEVEL="CRITICAL"
    echo "[$TS] [$LEVEL] /opt/laesh: ${USED_PCT}% usado — ${AVAIL} libre de ${TOTAL}" >> "$LOG"
    # Mostrar top 10 archivos más grandes en /opt/laesh/logs (posibles culpables)
    echo "[$TS] [$LEVEL] Top logs por tamaño:" >> "$LOG"
    find /opt/laesh/logs -type f -name "*.log" -printf '%s\t%p\n' 2>/dev/null \
        | sort -rn | head -10 \
        | awk '{printf "  %s MB\t%s\n", int($1/1048576), $2}' >> "$LOG"
    # También revisar /opt/laesh/uploads (PDFs acumulados)
    UPLOAD_SIZE=$(du -sh /opt/laesh/uploads 2>/dev/null | cut -f1)
    echo "[$TS] [$LEVEL] /opt/laesh/uploads: ${UPLOAD_SIZE}" >> "$LOG"
elif (( USED_PCT >= WARN_PCT )); then
    LEVEL="WARNING"
    echo "[$TS] [$LEVEL] /opt/laesh: ${USED_PCT}% usado — ${AVAIL} libre de ${TOTAL}" >> "$LOG"
else
    LEVEL="OK"
    echo "[$TS] [$LEVEL] /opt/laesh: ${USED_PCT}% usado — ${AVAIL} libre de ${TOTAL}" >> "$LOG"
fi

# ── Verificar también el root filesystem ─────────────────────────────────────
ROOT_PCT=$(df / 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}')
if (( ROOT_PCT >= CRIT_PCT )); then
    echo "[$TS] [CRITICAL] Filesystem raíz: ${ROOT_PCT}% — URGENTE: limpiar /var/cache o logs del sistema" >> "$LOG"
elif (( ROOT_PCT >= WARN_PCT )); then
    echo "[$TS] [WARNING]  Filesystem raíz: ${ROOT_PCT}% usado" >> "$LOG"
fi

exit 0
