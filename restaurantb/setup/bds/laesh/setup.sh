#!/usr/bin/env bash
# ==============================================================================
# Setup Orchestrator — LAESH Bloc Digital Database
#
# Pipeline completo (idempotente):
#   Paso 0  → bash/01_install_auth.sh    Tablas Delight-Auth (CREATE IF NOT EXISTS)
#   Paso 01 → 00_database.sql … 08_stored_procedures.sql  (9 scripts SQL)
#   Paso 10 → bash/02_seed_users.sh      Usuarios semilla (3 perfiles)
#
# Variables de entorno sobreescribibles:
#   DB_HOST, DB_PORT, DB_USER, DB_PASS   (conexión mysql directo al puerto expuesto)
#   DB_CONTAINER  (default: restaurantb_db)   usada por bash/01_install_auth.sh
#   WEB_CONTAINER (default: restaurantb_phpfpm) usada por bash/02_seed_users.sh
#
# Uso:
#   bash setup/bds/laesh/setup.sh
# ==============================================================================

set -euo pipefail

# Credenciales — conexión directa al puerto expuesto del contenedor
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-6002}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-comite_2026}"

# Para exportar a los scripts bash hijos
export DB_CONTAINER="${DB_CONTAINER:-restaurantb_db}"
export WEB_CONTAINER="${WEB_CONTAINER:-restaurantb_phpfpm}"
# Pasar credenciales también
export DB_NAME="${DB_NAME:-laesh_db}"
export DB_USER
export DB_PASS

# Directorio de este script (setup/bds/laesh/)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

MYSQL_CMD="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS"

echo "=================================================================="
echo " LAESH Bloc Digital — Setup de Base de Datos"
echo " Host: $DB_HOST:$DB_PORT | DB: laesh_db"
echo "=================================================================="

# ── PASO 0: Tablas Delight-Auth (CREATE TABLE IF NOT EXISTS) ───────────────────
# DDL directo — más confiable que $auth->install() en esta versión de Delight-Auth.
echo ""
echo "── Paso 0: Instalando tablas Delight-Auth... ──────────────────────"
bash "${DIR}/bash/01_install_auth.sh"
echo ""

# Función para ejecutar SQL con reporte de estado
run_sql() {
    local script="$1"
    local desc="$2"
    echo "→ Ejecutando $script ($desc)..."
    $MYSQL_CMD < "$DIR/$script"
    echo "  ✓ OK"
}

# ── PASOS 01–09: Schema + seed SQL ───────────────────────────────────────────
echo "── Pasos 01–09: Schema + Seed SQL ─────────────────────────────────"
run_sql "00_database.sql"             "Base de datos y usuario de app"
run_sql "01_auth_schema.sql"          "Auth schema placeholder (tablas ya creadas en paso 0)"
run_sql "02_core_schema.sql"          "Core: CONFIGURACIONES, WEB_CONTENIDOS, ESTUDIOS, CATALOGOS_UI"
run_sql "03_transactional_schema.sql" "Transaccional: ORDENES, NOTIFICACIONES, HISTORIAL"
run_sql "04_auth_extensions.sql"      "Auth Extensions: EMPLEADOS, PERFILES_MEDICOS, RBAC"
run_sql "05_system_tables.sql"        "Sistema: SYS_LOGS, FALLBACK_LOG + Event Scheduler"
run_sql "06_indexes.sql"              "Índices de rendimiento"
run_sql "07_seed_catalogs.sql"        "Datos semilla: catálogos, estudios, configuraciones"
run_sql "08_stored_procedures.sql"    "Procedimientos: CrearOrden, ProcesarPDF"
echo ""

# ── PASO 10: Usuarios semilla (ADMIN, RECEPCION, MEDICO) ──────────────────────
echo "── Paso 10: Sembrando usuarios semilla... ──────────────────────────"
bash "${DIR}/bash/02_seed_users.sh"

echo ""
echo "=================================================================="
echo " ✅ Setup completo: laesh_db configurada y sembrada exitosamente."
echo ""
echo " Credenciales de app: laesh_app / laesh_2026_dev"
echo " (cambiar contraseña antes de deploy a producción OCI)"
echo " Acceso: https://192.168.0.120:8443/laesh/"
echo "=================================================================="
