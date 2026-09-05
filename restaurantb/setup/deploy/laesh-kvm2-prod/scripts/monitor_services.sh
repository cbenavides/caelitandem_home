#!/usr/bin/env bash
# ==============================================================================
# LAESH — monitor_services.sh
# Monitoreo de servicios críticos: Nginx, MariaDB, Swoole, HTTPS E2E.
# Ejecutado por cron cada 10 minutos (raíz del pipeline: 07_security_harden.sh).
# Usa flock para evitar ejecuciones solapadas si un ciclo tarda más de 10 min.
#
# Lógica de reintento por servicio:
#   - 3 verificaciones separadas por 30 s (RETRY_WAIT=30s)
#   - Solo se envía alerta si los 3 intentos fallan
#   - Si el servicio se recupera en algún reintento: no se envía alerta
#   - Cooldown anti-spam: no re-alerta el mismo servicio por 30 min
#     (estado en /opt/laesh/monitor/<servicio>.last_alert)
#
# Servicios monitoreados:
#   nginx      → systemctl + HTTP probe localhost:80
#   mariadb    → systemctl + mariadb ping
#   swoole     → systemctl + curl http://127.0.0.1:9502/status
#   https_e2e  → curl HTTPS /laesh/ (prueba Nginx+FPM+PHP stack completo)
#
# Log: /opt/laesh/logs/monitor-services.log
# ==============================================================================

set -uo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
LOG="/opt/laesh/logs/monitor-services.log"
STATE_DIR="/opt/laesh/monitor"
SEND_ALERT="/opt/laesh/scripts/send_alert.sh"
LOCK_FILE="/tmp/laesh-monitor.lock"
RETRIES=3
RETRY_WAIT=30    # segundos entre reintentos (30s — distingue blip transitorio de caída real)
COOLDOWN=1800    # segundos antes de re-alertar el mismo servicio (30 min)
TS() { date '+%Y-%m-%d %H:%M:%S'; }

# ── Crear dirs necesarios ─────────────────────────────────────────────────────
mkdir -p "$STATE_DIR" "$( dirname "$LOG" )"

# ── flock: evitar ejecuciones solapadas ──────────────────────────────────────
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "[$( TS )] [SKIP] Monitor ya en ejecución (lock activo). Saliendo." >> "$LOG"
    exit 0
fi

# ── Función: verificar un servicio con reintentos ────────────────────────────
# Retorna 0 si el servicio está sano, 1 si falló en los 3 intentos.
check_with_retries() {
    local name="$1"
    local check_fn="$2"   # nombre de función que retorna 0=ok / 1=fail
    local attempt

    for attempt in $(seq 1 $RETRIES); do
        if $check_fn; then
            if [ "$attempt" -gt 1 ]; then
                echo "[$( TS )] [RECOVERED] ${name} — OK en intento ${attempt}/${RETRIES}" >> "$LOG"
            fi
            return 0
        fi
        echo "[$( TS )] [FAIL ${attempt}/${RETRIES}] ${name} no responde" >> "$LOG"
        if [ "$attempt" -lt $RETRIES ]; then
            sleep $RETRY_WAIT
        fi
    done
    return 1
}

# ── Función: enviar alerta con cooldown ─────────────────────────────────────
alert_if_needed() {
    local name="$1"
    local subject="$2"
    local body="$3"
    local state_file="${STATE_DIR}/${name}.last_alert"
    local now; now=$(date +%s)

    # Cooldown anti-spam
    if [ -f "$state_file" ]; then
        local last_alert; last_alert=$(cat "$state_file" 2>/dev/null || echo 0)
        local elapsed=$(( now - last_alert ))
        if [ $elapsed -lt $COOLDOWN ]; then
            local remaining=$(( COOLDOWN - elapsed ))
            echo "[$( TS )] [COOLDOWN] ${name} — próxima alerta en ${remaining}s" >> "$LOG"
            return 0
        fi
    fi

    echo "[$( TS )] [ALERT] Enviando alerta SMTP: ${subject}" >> "$LOG"
    if bash "$SEND_ALERT" "$subject" "$body"; then
        echo "$now" > "$state_file"
    fi
}

# ── Función: marcar servicio como recuperado ─────────────────────────────────
clear_alert_state() {
    local name="$1"
    rm -f "${STATE_DIR}/${name}.last_alert" 2>/dev/null || true
}

# ── Checks individuales ──────────────────────────────────────────────────────

check_nginx() {
    # Systemctl activo + responde HTTP en loopback
    systemctl is-active --quiet nginx 2>/dev/null && \
    curl -sf http://127.0.0.1/ -o /dev/null --max-time 5 2>/dev/null
}

check_mariadb() {
    # Systemctl activo + ping nativo
    # Guard: si .mariadb-root.cnf no existe (LAESH_ROOT_PASS no fue definida en setup),
    # verificar solo con systemctl para evitar falsos positivos continuos.
    systemctl is-active --quiet mariadb 2>/dev/null || return 1
    if [ -f /opt/laesh/configs/.mariadb-root.cnf ]; then
        mariadb --defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf \
            -e "SELECT 1" &>/dev/null 2>/dev/null
    else
        # Fallback: solo systemctl (no podemos conectar sin credenciales)
        echo "[$( TS )] [WARN] .mariadb-root.cnf no encontrado — verificando solo via systemctl" >> "$LOG"
        return 0
    fi
}

check_swoole() {
    # Systemctl activo + endpoint /status responde con "online"
    systemctl is-active --quiet swoole-laesh 2>/dev/null && \
    curl -sf http://127.0.0.1:9502/status --max-time 5 2>/dev/null | grep -q '"status":"online"'
}

check_https_e2e() {
    # Prueba stack completo: Nginx TLS → PHP-FPM → index.php
    # La app se sirve en / (no en /laesh/ — URL raíz activa desde 2026-09-05).
    # -k: acepta self-signed (Modo A); --max-time 10: timeout conservador
    curl -sf -k https://127.0.0.1/ -H "Host: localhost" \
        -o /dev/null --max-time 10 2>/dev/null
}

BACKUP_DIR="/opt/laesh/backups/db"
BACKUP_DB_NAME="laesh_db"  # nombre de la BD — para mensajes de alerta
BACKUP_MAX_AGE=7200    # 90 min (cron horario → tolerancia x1.5 ciclos)
BACKUP_MIN_BYTES=10240 # 10 KB — dump válido mínimo

check_backup_fresh() {
    # Verifica que el último backup horario existe, es reciente y tiene tamaño razonable.
    # Falla si: no hay backups, el más reciente es > BACKUP_MAX_AGE, o < BACKUP_MIN_BYTES.
    local latest
    latest=$(ls -t "${BACKUP_DIR}"/laesh_db_[0-9]*.sql.gz 2>/dev/null | head -1)
    [ -z "$latest" ] && return 1
    local age=$(( $(date +%s) - $(stat -c%Y "$latest") ))
    local size; size=$(stat -c%s "$latest" 2>/dev/null || echo 0)
    [ "$age" -lt "$BACKUP_MAX_AGE" ] && [ "$size" -gt "$BACKUP_MIN_BYTES" ]
}

# ── Main: verificar cada servicio ────────────────────────────────────────────
echo "[$( TS )] [START] Ciclo de monitoreo" >> "$LOG"
FAILURES=()
DETAILS=""

# Nginx
if ! check_with_retries "nginx" check_nginx; then
    FAILURES+=("nginx")
    DETAILS+="• Nginx: CAÍDO — systemctl status nginx / journalctl -u nginx\n"
    alert_if_needed "nginx" \
        "CRÍTICO: Nginx caído en $(hostname -s)" \
        "Nginx no responde tras ${RETRIES} intentos (intervalo: ${RETRY_WAIT}s cada uno).\n\nSystemctl:\n$(systemctl status nginx --no-pager -l 2>&1 | tail -15)\n\nÚltimos errores:\n$(tail -20 /opt/laesh/logs/nginx-error.log 2>/dev/null)"
else
    clear_alert_state "nginx"
fi

# MariaDB
if ! check_with_retries "mariadb" check_mariadb; then
    FAILURES+=("mariadb")
    DETAILS+="• MariaDB: CAÍDO — systemctl status mariadb / journalctl -u mariadb\n"
    alert_if_needed "mariadb" \
        "CRÍTICO: MariaDB caído en $(hostname -s)" \
        "MariaDB no responde tras ${RETRIES} intentos (intervalo: ${RETRY_WAIT}s cada uno).\n\nSystemctl:\n$(systemctl status mariadb --no-pager -l 2>&1 | tail -15)\n\nError log:\n$(tail -20 /opt/laesh/logs/mariadb-error.log 2>/dev/null)"
else
    clear_alert_state "mariadb"
fi

# Swoole
if ! check_with_retries "swoole" check_swoole; then
    FAILURES+=("swoole")
    DETAILS+="• Swoole: CAÍDO — systemctl status swoole-laesh / journalctl -u swoole-laesh\n"
    alert_if_needed "swoole" \
        "ALERTA: Swoole WS caído en $(hostname -s)" \
        "Swoole WebSocket server no responde tras ${RETRIES} intentos.\n\nSystemctl:\n$(systemctl status swoole-laesh --no-pager -l 2>&1 | tail -15)\n\nSwoole log:\n$(tail -20 /opt/laesh/logs/swoole.log 2>/dev/null)"
else
    clear_alert_state "swoole"
fi

# HTTPS E2E (solo si Nginx está activo — evitar alerta duplicada)
if [[ ! " ${FAILURES[*]} " =~ " nginx " ]]; then
    if ! check_with_retries "https_e2e" check_https_e2e; then
        FAILURES+=("https_e2e")
        DETAILS+="• HTTPS E2E: FALLA — Nginx activo pero / no responde (PHP-FPM?)\n"
        alert_if_needed "https_e2e" \
            "CRÍTICO: Stack HTTPS E2E falla en $(hostname -s)" \
            "Nginx está activo pero la ruta HTTPS / no responde.\nProbable causa: PHP-FPM caído o OOM killer.\n\nPHP-FPM status:\n$(systemctl status php8.3-fpm --no-pager -l 2>&1 | tail -10)\n\nError log FPM:\n$(tail -20 /opt/laesh/logs/php-fpm-error.log 2>/dev/null)"
    else
        clear_alert_state "https_e2e"
    fi
fi

# Backup staleness (solo verificar en horas exactas para reducir ruido)
# El cron de backup corre en :00 de cada hora; el monitor corre cada 10 min.
# Alertar si el último backup supera BACKUP_MAX_AGE (90 min) o está vacío.
if ! check_with_retries "backup_fresh" check_backup_fresh; then
    FAILURES+=("backup_fresh")
    LATEST=$(ls -t "${BACKUP_DIR}"/laesh_db_[0-9]*.sql.gz 2>/dev/null | head -1 || echo "(ninguno)")
    DETAILS+="• Backup BD: OBSOLETO/VACÍO — último: ${LATEST}\n"
    alert_if_needed "backup_fresh" \
        "ALERTA: Backup DB obsoleto/vacío en $(hostname -s)" \
        "El último backup de ${BACKUP_DB_NAME} supera ${BACKUP_MAX_AGE}s de antigüedad o tiene < ${BACKUP_MIN_BYTES} bytes.\n\nÚltimo archivo: ${LATEST}\n\nLog backup:\n$(tail -10 /opt/laesh/logs/backup-db.log 2>/dev/null)\n\nVerificar cron:\n  crontab -l | grep backup\n  sudo bash /opt/laesh/scripts/backup_db.sh  (manual)"
else
    clear_alert_state "backup_fresh"
fi

# ── Resumen del ciclo ─────────────────────────────────────────────────────────
if [ ${#FAILURES[@]} -eq 0 ]; then
    echo "[$( TS )] [OK] Todos los servicios sanos (nginx, mariadb, swoole, https_e2e, backup_fresh)" >> "$LOG"
else
    echo "[$( TS )] [CRITICAL] Servicios fallidos: ${FAILURES[*]}" >> "$LOG"
fi

echo "[$( TS )] [END] Ciclo completado" >> "$LOG"
flock -u 9
exit 0
