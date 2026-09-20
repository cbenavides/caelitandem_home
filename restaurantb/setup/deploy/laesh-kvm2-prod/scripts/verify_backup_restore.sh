#!/usr/bin/env bash
# ==============================================================================
# LAESH — verify_backup_restore.sh
#
# BAJO (auditoría 2026-09-20): backup_db.sh valida tamaño del dump y alerta si
# falla, pero nunca prueba RESTAURARLO — un dump corrupto por una causa
# distinta a "tamaño pequeño" (charset incorrecto, dependencias circulares
# entre stored procedures, mariadb-dump con --routines fallando en silencio en
# algún objeto puntual) no se detectaría hasta el momento real de un desastre.
#
# Restaura el backup MÁS RECIENTE en una BD desechable ('laesh_db_restore_test'),
# verifica objetos clave (tablas, vistas, stored procedures — no solo "restauró
# sin error", sino "restauró lo que se espera que tenga"), y la elimina al
# final. NO toca laesh_db real en ningún momento.
#
# Uso:
#   ./scripts/verify_backup_restore.sh                    # backup diario más reciente
#   ./scripts/verify_backup_restore.sh /ruta/a/archivo.sql.gz   # archivo específico
#
# Pensado para cron SEMANAL (no horario como backup_db.sh — restaurar un dump
# completo es una operación pesada; probarlo cada hora sería desproporcionado
# frente al riesgo real que mitiga).
# ==============================================================================
set -euo pipefail

TEST_DB="laesh_db_restore_test"
BACKUP_DIR="/opt/laesh/backups/db"
LOG="/opt/laesh/logs/backup-db.log"
SEND_ALERT="/opt/laesh/scripts/send_alert.sh"
MCNF="/opt/laesh/configs/.mariadb-root.cnf"

ts() { date '+%Y-%m-%d %H:%M:%S'; }

if [ ! -f "$MCNF" ]; then
    echo "$(ts) [verify_backup_restore] ERROR — .mariadb-root.cnf no encontrado en $MCNF" >> "$LOG"
    exit 1
fi
MROOT="mariadb --defaults-extra-file=${MCNF}"

# ── Archivo a restaurar ───────────────────────────────────────────────────────
FILE="${1:-}"
if [ -z "$FILE" ]; then
    FILE=$(find "$BACKUP_DIR" -name "laesh_db_*.sql.gz" ! -name "laesh_db_weekly_*" -type f -printf '%T@ %p\n' 2>/dev/null \
        | sort -rn | head -1 | cut -d' ' -f2- || true)
fi
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "$(ts) [verify_backup_restore] ERROR — no se encontró ningún backup para restaurar (buscado: ${FILE:-'(ninguno)'})" >> "$LOG"
    bash "$SEND_ALERT" \
        "ERROR: verify_backup_restore no encontró backup en $(hostname -s)" \
        "No se encontró ningún archivo laesh_db_*.sql.gz en ${BACKUP_DIR}." \
        2>/dev/null || true
    exit 1
fi

echo "$(ts) [verify_backup_restore] Restaurando ${FILE} → ${TEST_DB} (BD desechable)..." >> "$LOG"

# ── Limpieza defensiva por si un run anterior murió a medias ─────────────────
${MROOT} -e "DROP DATABASE IF EXISTS ${TEST_DB};" 2>/dev/null || true

_FAIL_REASON=""
_cleanup_and_report() {
    local rc=$?
    ${MROOT} -e "DROP DATABASE IF EXISTS ${TEST_DB};" 2>/dev/null || true
    if [ -n "$_FAIL_REASON" ] || [ "$rc" -ne 0 ]; then
        echo "$(ts) [verify_backup_restore] ERROR — ${_FAIL_REASON:-fallo inesperado (rc=$rc)}" >> "$LOG"
        bash "$SEND_ALERT" \
            "ERROR: verify_backup_restore falló en $(hostname -s)" \
            "Backup probado: ${FILE}\nMotivo: ${_FAIL_REASON:-código de salida ${rc}}\n\nEsto NO significa que laesh_db real esté afectada — solo que este backup en particular no restauró correctamente. Investigar antes de confiar en él para un desastre real." \
            2>/dev/null || true
    fi
}
trap '_cleanup_and_report' EXIT

${MROOT} -e "CREATE DATABASE ${TEST_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

if ! gunzip -c "$FILE" | ${MROOT} "$TEST_DB" 2>>"$LOG"; then
    _FAIL_REASON="gunzip/mariadb devolvió error al restaurar ${FILE}"
    exit 1
fi

# ── Verificar objetos clave — no solo "restauró sin error" ────────────────────
# Tablas centrales del flujo de negocio (si faltan, el dump está incompleto
# aunque haya "restaurado" sin lanzar ningún error SQL).
for _tbl in users ordenes pacientes notificaciones detalle_ordenes historial_estados_orden; do
    _exists=$(${MROOT} "$TEST_DB" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${TEST_DB}' AND table_name='${_tbl}';" 2>/dev/null || echo 0)
    if [ "$_exists" != "1" ]; then
        _FAIL_REASON="tabla '${_tbl}' ausente tras restaurar — dump incompleto"
        exit 1
    fi
done

# Stored procedures críticos — un --routines fallando en silencio en un SP
# puntual (ej. error de sintaxis en el dump, DELIMITER mal escapado) deja la
# tabla presente pero la lógica de negocio rota.
for _sp in CrearOrdenLaboratorio CambiarEstadoOrden; do
    _exists=$(${MROOT} "$TEST_DB" -N -e "SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='${TEST_DB}' AND ROUTINE_NAME='${_sp}';" 2>/dev/null || echo 0)
    if [ "$_exists" != "1" ]; then
        _FAIL_REASON="stored procedure '${_sp}' ausente tras restaurar — --routines falló en silencio"
        exit 1
    fi
done

_USERS_COUNT=$(${MROOT} "$TEST_DB" -N -e "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "ERROR")
if [ "$_USERS_COUNT" = "ERROR" ]; then
    _FAIL_REASON="no se pudo hacer SELECT sobre 'users' tras restaurar"
    exit 1
fi

echo "$(ts) [verify_backup_restore] OK — ${FILE} restauró correctamente (${_USERS_COUNT} usuarios, tablas y SPs clave presentes). BD de prueba eliminada." >> "$LOG"
exit 0
