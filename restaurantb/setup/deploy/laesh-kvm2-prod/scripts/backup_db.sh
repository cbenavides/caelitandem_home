#!/usr/bin/env bash
# ==============================================================================
# LAESH — backup_db.sh
# Dump de laesh_db → /opt/laesh/backups/db/
# Retiene últimos 7 días (diario) y últimas 4 semanas (semanal)
# Uso:
#   ./scripts/backup_db.sh              # dump full
#   ./scripts/backup_db.sh --weekly     # etiqueta como semanal (retención mayor)
# Instalado como cron horario por 07_security_harden.sh
#
# Alertas SMTP: send_alert.sh se invoca si el dump falla o produce un archivo
# sospechosamente pequeño (< MIN_BYTES = fallo silencioso de mariadb-dump).
# ==============================================================================
set -euo pipefail

DB_NAME="laesh_db"
BACKUP_DIR="/opt/laesh/backups/db"
LOG="/opt/laesh/logs/backup-db.log"
SEND_ALERT="/opt/laesh/scripts/send_alert.sh"
MIN_BYTES=10240   # 10 KB — dump vacío produce ~20 bytes (fallo silencioso)
WEEKLY=false
[[ "${1:-}" == "--weekly" ]] && WEEKLY=true

ts() { date '+%Y-%m-%d %H:%M:%S'; }
STAMP=$(date '+%Y%m%d_%H%M%S')

mkdir -p "$BACKUP_DIR"

# ── Nombre del archivo ────────────────────────────────────────────────────────
if $WEEKLY; then
    FILE="${BACKUP_DIR}/laesh_db_weekly_$(date '+%Y_W%V').sql.gz"
    KEEP_DAYS=35   # ~4 semanas
else
    FILE="${BACKUP_DIR}/laesh_db_${STAMP}.sql.gz"
    KEEP_DAYS=7
fi

# ── Trap de error — alerta SMTP en cualquier fallo del script ─────────────────
# Se activa si set -e dispara (fallo de mariadb-dump, gzip, etc.) o exit 1 explícito.
# _BACKUP_OK=true se fija solo al final, antes de exit 0 exitoso.
# Esto evita que el trap también dispare al exit 0 normal.
_BACKUP_OK=false
_alert_on_exit() {
    local rc=$?
    $_BACKUP_OK && return 0   # salida exitosa — no alertar
    local ctx
    ctx="$(tail -10 "$LOG" 2>/dev/null || echo '(sin log)')"
    echo "$(ts) [backup_db] ALERT SMTP enviada (rc=${rc})" >> "$LOG"
    bash "$SEND_ALERT" \
        "ERROR: backup_db falló en $(hostname -s)" \
        "El dump de '${DB_NAME}' falló con código de salida ${rc}.\n\nArchivo destino: ${FILE}\n\nÚltimas líneas del log:\n${ctx}" \
        2>/dev/null || true
}
trap '_alert_on_exit' EXIT

# ── Verificar .mariadb-root.cnf ───────────────────────────────────────────────
MCNF="/opt/laesh/configs/.mariadb-root.cnf"
if [ ! -f "$MCNF" ]; then
    echo "$(ts) [backup_db] ERROR — .mariadb-root.cnf no encontrado en $MCNF" >> "$LOG"
    exit 1
fi

echo "$(ts) [backup_db] Dump → $FILE" >> "$LOG"

# ── Dump con credenciales root via .mariadb-root.cnf (socket auth + password) ─
# Paso 4 establece contraseña root → unix_socket sin password falla ("Access denied").
# .mariadb-root.cnf tiene host=localhost + socket=/run/mysqld/mysqld.sock + password.
# Creado por 04_configure_stack.sh con chmod 600 root:root.
mariadb-dump \
    --defaults-extra-file="$MCNF" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --add-drop-table \
    --default-character-set=utf8mb4 \
    "$DB_NAME" \
  | gzip -9 > "$FILE"

# ── Validar tamaño del dump (atrapa fallos silenciosos) ───────────────────────
# mariadb-dump puede fallar y dejar un .gz válido pero vacío (20 bytes).
# set -e no lo detecta porque el pipe termina con código 0.
SIZE_BYTES=$(stat -c%s "$FILE" 2>/dev/null || echo 0)
if [ "$SIZE_BYTES" -lt "$MIN_BYTES" ]; then
    echo "$(ts) [backup_db] ERROR — dump sospechosamente pequeño: ${SIZE_BYTES} bytes (mín: ${MIN_BYTES})" >> "$LOG"
    rm -f "$FILE"   # eliminar archivo vacío para que monitor detecte ausencia
    # Alerta con detalle específico de dump vacío (distinto del trap genérico)
    bash "$SEND_ALERT" \
        "ERROR: backup_db dump vacío en $(hostname -s)" \
        "El archivo ${FILE} tiene solo ${SIZE_BYTES} bytes (esperado > ${MIN_BYTES}).\nPosible: fallo silencioso de mariadb-dump, BD vacía o error de permisos.\n\nVerificar:\n  sudo mariadb --defaults-extra-file=${MCNF} -e 'SHOW TABLES IN ${DB_NAME}'" \
        2>/dev/null || true
    exit 1
fi

SIZE=$(du -sh "$FILE" | cut -f1)
echo "$(ts) [backup_db] OK — $FILE ($SIZE)" >> "$LOG"

# ── Limpieza de backups viejos ────────────────────────────────────────────────
DELETED=$(find "$BACKUP_DIR" -name "laesh_db_*.sql.gz" \
    ! -name "laesh_db_weekly_*" \
    -mtime "+${KEEP_DAYS}" -type f -delete -print | wc -l)
[[ "$DELETED" -gt 0 ]] && echo "$(ts) [backup_db] Limpieza: $DELETED backups viejos eliminados." >> "$LOG"

_BACKUP_OK=true   # marcar éxito — el trap EXIT no enviará alerta
exit 0
