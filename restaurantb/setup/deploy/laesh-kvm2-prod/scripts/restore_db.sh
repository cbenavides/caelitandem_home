#!/usr/bin/env bash
# ==============================================================================
# LAESH — restore_db.sh
# Restaura laesh_db desde un dump .sql.gz
# Uso: sudo ./scripts/restore_db.sh /opt/laesh/backups/db/laesh_db_20260903_HHMMSS.sql.gz
# ADVERTENCIA: Sobreescribe la BD existente. Confirmar antes de ejecutar.
# ==============================================================================
set -euo pipefail

DUMP_FILE="${1:?USO: $0 <ruta-al-dump.sql.gz>}"
DB_NAME="laesh_db"
LOG="/opt/laesh/logs/restore-db.log"

ts() { date '+%Y-%m-%d %H:%M:%S'; }

# ── Validaciones ──────────────────────────────────────────────────────────────
[[ -f "$DUMP_FILE" ]] || { echo "ERROR: No existe el archivo: $DUMP_FILE"; exit 1; }
[[ "$DUMP_FILE" == *.sql.gz ]] || { echo "ERROR: El archivo debe ser .sql.gz"; exit 1; }

echo ""
echo "⚠️   ADVERTENCIA: Esta operación SOBREESCRIBE la base de datos '$DB_NAME'."
echo "     Dump a restaurar: $DUMP_FILE"
echo "     Tamaño: $(du -sh "$DUMP_FILE" | cut -f1)"
echo ""
read -rp "¿Confirmar restauración? (escribir 'SI' para continuar): " CONFIRM
[[ "$CONFIRM" == "SI" ]] || { echo "Cancelado."; exit 0; }

echo "$(ts) [restore_db] Iniciando restauración desde: $DUMP_FILE" >> "$LOG"

# ── Backup previo de seguridad ────────────────────────────────────────────────
PRE_BACKUP="/opt/laesh/backups/db/pre_restore_$(date '+%Y%m%d_%H%M%S').sql.gz"
echo "$(ts) [restore_db] Creando backup previo: $PRE_BACKUP" >> "$LOG"
mariadb-dump --single-transaction --routines --triggers "$DB_NAME" \
  | gzip -9 > "$PRE_BACKUP" \
  && echo "$(ts) [restore_db] Backup previo OK: $(du -sh "$PRE_BACKUP" | cut -f1)" >> "$LOG" \
  || echo "$(ts) [restore_db] WARN: no se pudo crear backup previo" >> "$LOG"

# ── Restaurar ────────────────────────────────────────────────────────────────
echo "$(ts) [restore_db] Restaurando..." >> "$LOG"
zcat "$DUMP_FILE" | mariadb "$DB_NAME"

echo "$(ts) [restore_db] ✓ Restauración completada: $DB_NAME" >> "$LOG"
echo ""
echo "✅  Restauración completada. Log: $LOG"
echo "    Backup previo guardado en: $PRE_BACKUP"
