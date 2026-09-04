#!/usr/bin/env bash
# ==============================================================================
# LAESH — backup_db.sh
# Dump de laesh_db → /opt/laesh/backups/db/
# Retiene últimos 7 días (diario) y últimos 4 semanas (semanal)
# Uso:
#   ./scripts/backup_db.sh              # dump full
#   ./scripts/backup_db.sh --weekly     # etiqueta como semanal (retención mayor)
# Instalado como cron horario por 07_security_harden.sh
# ==============================================================================
set -euo pipefail

DB_NAME="laesh_db"
BACKUP_DIR="/opt/laesh/backups/db"
LOG="/opt/laesh/logs/backup-db.log"
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

echo "$(ts) [backup_db] Dump → $FILE" >> "$LOG"

# ── Dump con credenciales root via socket ────────────────────────────────────
# No se pasa password en CLI; se usa autenticación unix socket (root@localhost)
mariadb-dump \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --add-drop-table \
    --default-character-set=utf8mb4 \
    "$DB_NAME" \
  | gzip -9 > "$FILE"

SIZE=$(du -sh "$FILE" | cut -f1)
echo "$(ts) [backup_db] OK — $FILE ($SIZE)" >> "$LOG"

# ── Limpieza de backups viejos ────────────────────────────────────────────────
DELETED=$(find "$BACKUP_DIR" -name "laesh_db_*.sql.gz" \
    ! -name "laesh_db_weekly_*" \
    -mtime "+${KEEP_DAYS}" -type f -delete -print | wc -l)
[[ "$DELETED" -gt 0 ]] && echo "$(ts) [backup_db] Limpieza: $DELETED backups viejos eliminados." >> "$LOG"

exit 0
