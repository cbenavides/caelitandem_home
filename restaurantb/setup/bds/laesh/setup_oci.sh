#!/usr/bin/env bash
# ==============================================================================
# setup_oci.sh — Setup Orchestrator LAESH · OCI VM
#
# Equivalente a setup.sh pero adaptado a la infraestructura OCI:
#   • MariaDB en contenedor Docker  laesh_db  (no restaurantb_db)
#   • Binary: mariadb (no mysql)
#   • Root password: laesh_oci_root_2026  (diferente de local comite_2026)
#   • App password: laesh_oci_app_2026  (OCI www.conf env[DB_PASS])
#   • PHP-FPM: nativo php8.1 (no contenedor restaurantb_phpfpm)
#   • Script PHP: ruta OCI /home/ubuntu/laesh-stack/www/...
#
# Pipeline:
#   Paso 0  → DDL Delight-Auth directo (SIN 01_install_auth.sh — incompatible)
#   Paso 1  → DROP + recrear BD (controlado — solo con --drop flag)
#   Paso 2  → SQL 00–09 (10 scripts en orden)
#   Paso 3  → ALTER USER laesh_app → contraseña OCI
#   Paso 4  → Seed usuarios via php8.1 directo
#
# Uso:
#   bash setup/bds/laesh/setup_oci.sh           # sin DROP (idempotente)
#   bash setup/bds/laesh/setup_oci.sh --drop    # DROP + recrear BD completa
#
# Variables sobreescribibles:
#   OCI_HOST        Host OCI (default: 127.0.0.1 — ejecutar en el propio OCI o via tunnel)
#   OCI_DB_PORT     Puerto MariaDB expuesto (default: 6002)
#   OCI_ROOT_PASS   Contraseña root MariaDB OCI (default: laesh_oci_root_2026)
#   OCI_APP_PASS    Contraseña laesh_app en OCI (default: laesh_oci_app_2026)
#   OCI_DB_CONTAINER  Nombre contenedor Docker MariaDB (default: laesh_db)
#   OCI_PHP_BIN     Binario PHP nativo en OCI (default: php8.1)
#   OCI_WEB_DIR     Raíz laesh-stack www/ en OCI (default: /home/ubuntu/laesh-stack/www)
# ==============================================================================

set -euo pipefail

# ── Configuración OCI ────────────────────────────────────────────────────────
OCI_HOST="${OCI_HOST:-127.0.0.1}"
OCI_DB_PORT="${OCI_DB_PORT:-6002}"
OCI_ROOT_PASS="${OCI_ROOT_PASS:-laesh_oci_root_2026}"
OCI_APP_PASS="${OCI_APP_PASS:-laesh_oci_app_2026}"
OCI_DB_CONTAINER="${OCI_DB_CONTAINER:-laesh_db}"
OCI_PHP_BIN="${OCI_PHP_BIN:-php8.1}"
OCI_WEB_DIR="${OCI_WEB_DIR:-/home/ubuntu/laesh-stack/www}"

DROP_DB=false
if [[ "${1:-}" == "--drop" ]]; then
    DROP_DB=true
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Comando MariaDB via docker exec (usa binary 'mariadb' del contenedor OCI)
MCMD="docker exec -i ${OCI_DB_CONTAINER} mariadb -u root -p${OCI_ROOT_PASS}"

# ── Verificar contenedor OCI corriendo ────────────────────────────────────────
if ! docker ps --format '{{.Names}}' | grep -q "^${OCI_DB_CONTAINER}$"; then
    echo "[ERROR] Contenedor '${OCI_DB_CONTAINER}' no está corriendo."
    echo "        cd /home/ubuntu/laesh-stack && docker compose up -d"
    exit 1
fi

echo "=================================================================="
echo " LAESH Bloc Digital — Setup BD (OCI VM)"
echo " Contenedor: ${OCI_DB_CONTAINER} | Puerto: ${OCI_DB_PORT}"
echo " DROP mode:  ${DROP_DB}"
echo "=================================================================="

# ── PASO 0: Tablas Delight-Auth (DDL directo al contenedor OCI) ───────────────
# 01_install_auth.sh usa 'restaurantb_db' y es incompatible con OCI.
# Aquí ejecutamos el mismo DDL directamente contra laesh_db.
echo ""
echo "── Paso 0: Tablas Delight-Auth (DDL directo) ──────────────────────"

run_auth_sql() {
    docker exec -i "${OCI_DB_CONTAINER}" \
        mariadb -u root -p"${OCI_ROOT_PASS}" laesh_db <<< "$1" 2>/dev/null
}

# Solo si la BD ya existe (post paso 1 si --drop, o existente si no --drop)
# Usamos run_sql_file para los scripts principales — aquí creamos la BD primero si hace falta

# Si no hay --drop, verificar que la BD exista
if ! $DROP_DB; then
    DB_EXISTS=$(${MCMD} -e "SHOW DATABASES LIKE 'laesh_db';" 2>/dev/null | grep -c "laesh_db" || true)
    if [[ "$DB_EXISTS" -eq 0 ]]; then
        echo "  BD laesh_db no existe — creando (sin DROP)..."
        ${MCMD} -e "CREATE DATABASE IF NOT EXISTS laesh_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
        ${MCMD} -e "CREATE USER IF NOT EXISTS 'laesh_app'@'%' IDENTIFIED BY 'laesh_2026_dev';" 2>/dev/null
        ${MCMD} -e "GRANT ALL PRIVILEGES ON laesh_db.* TO 'laesh_app'@'%'; FLUSH PRIVILEGES;" 2>/dev/null
    fi
fi

# ── PASO 1: DROP + recrear BD (solo con --drop) ───────────────────────────────
if $DROP_DB; then
    echo ""
    echo "── Paso 1: DROP + recrear laesh_db ────────────────────────────────"
    echo "   ⚠  Destruyendo BD laesh_db en contenedor ${OCI_DB_CONTAINER}..."
    ${MCMD} -e "DROP DATABASE IF EXISTS laesh_db;" 2>/dev/null
    echo "  ✓ DROP completado"
fi

# ── PASO 1.5: mariadb-upgrade (idempotente) ───────────────────────────────────
# Necesario cuando el contenedor se actualizó de versión (ej. 11.8→12.3).
# Sin esto, DROP/CREATE PROCEDURE falla con HY000-1558 (mysql.proc desactualizado).
# mariadb-upgrade es idempotente: si ya está actualizado, termina sin error.
echo ""
echo "── Paso 1.5: mariadb-upgrade (sincronizar tablas sistema) ─────────"
if docker exec "${OCI_DB_CONTAINER}" \
       mariadb-upgrade -u root -p"${OCI_ROOT_PASS}" --silent 2>/dev/null; then
    echo "  ✓ mariadb-upgrade OK"
else
    echo "  ~ mariadb-upgrade: ya actualizado o no disponible — continuando"
fi

# ── PASO 2: SQL 00–09 via contenedor ─────────────────────────────────────────
# run_sql_file: idempotente (CREATE TABLE IF NOT EXISTS, INSERT IGNORE, etc.)
# run_sql_file_warn: igual pero no aborta en error — para scripts que pueden
#   fallar inofensivamente si el objeto ya existe (SPs, vistas).
run_sql_file() {
    local script="$1"
    local desc="$2"
    echo "→ Ejecutando ${script} (${desc})..."
    docker exec -i "${OCI_DB_CONTAINER}" \
        mariadb -u root -p"${OCI_ROOT_PASS}" < "${DIR}/${script}" 2>/dev/null
    echo "  ✓ OK"
}

run_sql_file_warn() {
    local script="$1"
    local desc="$2"
    echo "→ Ejecutando ${script} (${desc})..."
    local out
    out=$(docker exec -i "${OCI_DB_CONTAINER}" \
        mariadb -u root -p"${OCI_ROOT_PASS}" < "${DIR}/${script}" 2>&1) || {
        echo "  ⚠ WARN: ${script} reportó error (no fatal) — ver detalle:"
        echo "${out}" | head -5 | sed 's/^/    /'
        return 0   # no abortar el pipeline
    }
    echo "  ✓ OK"
}

echo ""
echo "── Paso 2: Schema + Seed SQL (10 scripts) ─────────────────────────"
run_sql_file      "00_database.sql"             "BD + usuario laesh_app (pass dev — se corrige en paso 3)"
run_sql_file      "01_auth_schema.sql"          "Placeholder Auth (tablas ya creadas en paso 0)"
run_sql_file      "02_core_schema.sql"          "Core: configuraciones, web_contenidos, estudios"
run_sql_file      "03_transactional_schema.sql" "Transaccional: ordenes, notificaciones, historial"
run_sql_file      "04_auth_extensions.sql"      "Auth Extensions: empleados, perfiles, RBAC"
run_sql_file      "05_system_tables.sql"        "Sistema: sys_logs, fallback_log"
run_sql_file      "06_indexes.sql"              "Índices de rendimiento"
run_sql_file      "07_seed_catalogs.sql"        "Seed: catálogos, estudios, configuraciones, web_contenidos"
run_sql_file_warn "08_stored_procedures.sql"    "Stored Procedures: CrearOrden, ProcesarPDF"
run_sql_file_warn "09_views.sql"               "Vistas: vw_ordenes_completas, vw_pacientes_historial"

# ── PASO 3: Corregir contraseña laesh_app (dev→OCI) ──────────────────────────
echo ""
echo "── Paso 3: Corrigiendo contraseña laesh_app → OCI ─────────────────"
${MCMD} -e "ALTER USER 'laesh_app'@'%' IDENTIFIED BY '${OCI_APP_PASS}'; FLUSH PRIVILEGES;" 2>/dev/null
echo "  ✓ laesh_app password → OCI (${OCI_APP_PASS})"

# ── PASO 4: Seed usuarios via php8.1 nativo ──────────────────────────────────
echo ""
echo "── Paso 4: Sembrando usuarios (php8.1 nativo) ──────────────────────"

PHP_SCRIPT="${OCI_WEB_DIR}/laesh-swbldi/commons/seed_first_users.php"

if [ ! -f "${PHP_SCRIPT}" ]; then
    echo "[ERROR] Script PHP no encontrado: ${PHP_SCRIPT}"
    echo "        Verifica que el rsync de laesh-swbldi haya completado."
    exit 1
fi

# config.php lee variables con prefijo LAESH_DB_* (no DB_*)
LAESH_DB_HOST="${OCI_HOST}" \
LAESH_DB_PORT="${OCI_DB_PORT}" \
LAESH_DB_USER="laesh_app" \
LAESH_DB_PASS="${OCI_APP_PASS}" \
LAESH_DB_NAME="laesh_db" \
${OCI_PHP_BIN} "${PHP_SCRIPT}"

echo ""
echo "=================================================================="
echo " ✅ Setup OCI completo"
echo ""
echo " BD:       laesh_db en ${OCI_DB_CONTAINER}"
echo " App user: laesh_app / ${OCI_APP_PASS}"
echo " Acceso:   https://caelitandem.lat/laesh/"
echo ""
echo " Usuarios demo (cambiar antes de uso real):"
echo "   ADMIN     9990000001  010120001!"
echo "   RECEPCIÓN 9990000002  010120002!"
echo "   MÉDICO    9990000003  010120003!"
echo "=================================================================="
echo ""
echo " Verificar deploy:"
echo "   bash ${DIR}/bash/03_test_deploy.sh"
echo "=================================================================="
