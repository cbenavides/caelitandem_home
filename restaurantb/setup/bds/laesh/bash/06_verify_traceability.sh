#!/usr/bin/env bash
# ==============================================================================
# 04_verify_traceability.sh — Verifica que Gaps G2–G5 estén activos en producción
#
# Uso (en servidor KVM2):
#   H_ROOT_PASS='comite_2026' bash /home/sysadmin/laesh-src/setup/bds/laesh/bash/04_verify_traceability.sh
#
# Nota: corre como sysadmin (no root) → usa "sudo mariadb" internamente.
# ==============================================================================

# -u (variables sin definir = error) y pipefail, pero NO -e (manejamos errores explícitamente)
set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  △${NC} $*"; }
fail() { echo -e "${RED}  ✗${NC} $*"; ERRORS=$((ERRORS+1)); }

ERRORS=0

# ── Construir comando MariaDB ─────────────────────────────────────────────────
# En KVM2 sysadmin no puede conectar como root sin sudo.
# Se prueba: 1) .mariadb-root.cnf con sudo  2) -p con sudo  3) sin sudo como fallback
if [ -f /opt/laesh/configs/.mariadb-root.cnf ]; then
    MCMD="sudo mariadb --defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf laesh_db"
elif [[ -n "${H_ROOT_PASS:-}" ]]; then
    MCMD="sudo mariadb -u root -p${H_ROOT_PASS} laesh_db"
else
    echo "[ERROR] Sin credenciales MariaDB."
    echo "        Ejecutar: H_ROOT_PASS='comite_2026' bash 04_verify_traceability.sh"
    exit 1
fi

# Función helper: ejecuta consulta y devuelve resultado; imprime error si falla
db() {
    local result
    result=$(${MCMD} -N -e "$1" 2>/tmp/laesh_verify_err) || {
        echo "[db-error] $(cat /tmp/laesh_verify_err 2>/dev/null)" >&2
        echo ""
        return 1
    }
    echo "$result"
}

echo "=================================================================="
echo " LAESH — Verificación Trazabilidad E2E (G2, G3, G4, G5)"
echo "=================================================================="

# ── G3/G4/G5 — Columnas en sys_logs ──────────────────────────────────────────
echo ""
echo "── Columnas sys_logs (G3: request_id | G4: url, metodo | G5: session_id)"

COLS=$(db "
    SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'laesh_db' AND TABLE_NAME = 'sys_logs';
") || { fail "No se pudo consultar INFORMATION_SCHEMA — verificar credenciales"; }

if [[ -n "$COLS" ]]; then
    for col in request_id url metodo session_id; do
        if echo "$COLS" | grep -q "$col"; then
            ok "Columna '${col}' presente"
        else
            fail "Columna '${col}' AUSENTE — re-ejecutar migrations/m001_sys_logs_traceability.sql"
        fi
    done
fi

# ── Event Scheduler ───────────────────────────────────────────────────────────
echo ""
echo "── Event Scheduler (purga automática sys_logs)"

ES=$(db "SHOW VARIABLES LIKE 'event_scheduler';" | awk '{print $2}') || ES="ERROR"
if [[ "${ES^^}" == "ON" ]]; then
    ok "event_scheduler = ON"
else
    fail "event_scheduler = '${ES}' — ejecutar: sudo mariadb -u root -p'comite_2026' -e \"SET GLOBAL event_scheduler = ON;\""
fi

EVT=$(db "
    SELECT STATUS FROM INFORMATION_SCHEMA.EVENTS
    WHERE EVENT_SCHEMA = 'laesh_db' AND EVENT_NAME = 'evt_purga_sys_logs';
") || EVT=""
if [[ "${EVT}" == "ENABLED" ]]; then
    ok "evt_purga_sys_logs = ENABLED (DEBUG/INFO>30d, WARN>90d)"
elif [[ -z "${EVT}" ]]; then
    fail "evt_purga_sys_logs NO EXISTE — re-ejecutar 05_system_tables.sql"
else
    warn "evt_purga_sys_logs existe pero status = '${EVT}'"
fi

# ── G3/G4/G5 — Registros recientes con columnas pobladas ─────────────────────
echo ""
echo "── Registros recientes en sys_logs (últimos 10 min)"

RECENT=$(db "SELECT COUNT(*) FROM sys_logs WHERE created_at >= NOW() - INTERVAL 10 MINUTE;") || RECENT=0
echo "   Total últimos 10 min: ${RECENT}"

if [[ "$RECENT" -gt 0 ]]; then
    WITH_RID=$(db "SELECT COUNT(*) FROM sys_logs
        WHERE created_at >= NOW() - INTERVAL 10 MINUTE AND request_id IS NOT NULL;") || WITH_RID=0
    if [[ "$WITH_RID" -gt 0 ]]; then
        ok "G3 activo — ${WITH_RID}/${RECENT} registros tienen request_id"
    else
        warn "G3: todos los registros tienen request_id = NULL"
        warn "    ¿Logger.php fue desplegado? Sync + reload php8.3-fpm pendiente."
    fi

    WITH_URL=$(db "SELECT COUNT(*) FROM sys_logs
        WHERE created_at >= NOW() - INTERVAL 10 MINUTE AND url IS NOT NULL;") || WITH_URL=0
    if [[ "$WITH_URL" -gt 0 ]]; then
        ok "G4 activo — ${WITH_URL}/${RECENT} registros tienen url/metodo"
    else
        warn "G4: url = NULL (normal si solo corrieron crons/CLI en este periodo)"
    fi

    WITH_SID=$(db "SELECT COUNT(*) FROM sys_logs
        WHERE created_at >= NOW() - INTERVAL 10 MINUTE AND session_id IS NOT NULL;") || WITH_SID=0
    if [[ "$WITH_SID" -gt 0 ]]; then
        ok "G5 activo — ${WITH_SID}/${RECENT} registros tienen session_id"
    else
        warn "G5: session_id = NULL (normal en crons/CLI; aparece en requests de usuario)"
    fi
else
    warn "Sin registros en últimos 10 min — haz una acción en https://laesh.mx y re-ejecuta"
fi

# ── G2 — RBAC events ─────────────────────────────────────────────────────────
echo ""
echo "── G2: RBAC events en sys_logs (últimas 24h)"

RBAC_DENY=$(db "SELECT COUNT(*) FROM sys_logs
    WHERE level='WARN' AND message LIKE 'RBAC: denegado%'
    AND created_at >= NOW() - INTERVAL 24 HOUR;") || RBAC_DENY=0
RBAC_REDIR=$(db "SELECT COUNT(*) FROM sys_logs
    WHERE level='INFO' AND message LIKE 'RBAC: sesión no autenticada%'
    AND created_at >= NOW() - INTERVAL 24 HOUR;") || RBAC_REDIR=0

if [[ "$RBAC_DENY" -gt 0 ]] || [[ "$RBAC_REDIR" -gt 0 ]]; then
    ok "G2 activo — ${RBAC_DENY} denegaciones WARN + ${RBAC_REDIR} redirects INFO"
else
    warn "G2: sin RBAC events en 24h — normal si nadie intentó acceso no autorizado"
    warn "    Para probar: abre una ventana privada y accede a https://laesh.mx/laesh/adrc/"
fi

# ── Últimas 3 filas completas ─────────────────────────────────────────────────
echo ""
echo "── Últimas 3 entradas en sys_logs:"
${MCMD} -e "
    SELECT id, level, LEFT(message,55) AS msg,
           request_id, metodo, LEFT(url,35) AS url,
           session_id, created_at
    FROM sys_logs ORDER BY id DESC LIMIT 3;
" 2>/dev/null || warn "Sin registros en sys_logs aún"

# ── app.log — verificar nuevo formato ────────────────────────────────────────
echo ""
echo "── Formato app.log (últimas 5 líneas — busca [REQ:xxxx]):"
APP_LOG="/opt/laesh/logs/app.log"
if [ -f "$APP_LOG" ]; then
    sudo tail -5 "$APP_LOG" 2>/dev/null
else
    warn "app.log aún no existe — se crea en el primer Logger::log() de la app"
fi

# ── Resultado final ───────────────────────────────────────────────────────────
echo ""
echo "=================================================================="
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN} ✅ Sin errores estructurales — G2/G3/G4/G5 configurados${NC}"
else
    echo -e "${RED} ✗ ${ERRORS} problema(s) — revisar ✗ arriba${NC}"
fi
echo "=================================================================="
