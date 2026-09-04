#!/usr/bin/env bash
# ==============================================================================
# setup_hostinger.sh — Setup Orchestrator LAESH · Hostinger KVM 2
#
# Stack Hostinger: Nginx nativo + PHP 8.3-FPM nativo + MariaDB 11.8 nativo
# (sin Docker para ningún componente — diferencia clave vs OCI)
#
# Pipeline:
#   Paso 1  → DROP + recrear BD (solo con --drop)
#   Paso 2  → SQL 00–09 (10 scripts en orden)
#   Paso 3  → ALTER USER laesh_app → contraseña producción
#   Paso 3b → Least Privilege: REVOKE ALL + GRANT DML-only (SELECT,INSERT,UPDATE,DELETE)
#   Paso 4  → Seed usuarios via php8.3 nativo
#
# Uso:
#   bash setup/bds/laesh/setup_hostinger.sh           # sin DROP (idempotente)
#   bash setup/bds/laesh/setup_hostinger.sh --drop    # DROP + recrear BD completa
#
# Variables sobreescribibles:
#   H_DB_HOST      Host MariaDB (default: 127.0.0.1)
#   H_DB_PORT      Puerto MariaDB (default: 3306)
#   H_ROOT_PASS    Contraseña root nativa (default: — DEBE pasarse como env var)
#   H_APP_PASS     Contraseña laesh_app producción (default: — DEBE pasarse)
#   H_PHP_BIN      Binario PHP nativo (default: php8.3)
#   H_WEB_DIR      Raíz www en servidor (default: /opt/laesh/www)
#
# Ejemplo real en Hostinger:
#   H_ROOT_PASS='MiRootSeguro2026!' \
#   H_APP_PASS='MiAppSeguro2026!' \
#   bash setup/bds/laesh/setup_hostinger.sh --drop
# ==============================================================================

set -euo pipefail

# ── Configuración Hostinger ───────────────────────────────────────────────────
H_DB_HOST="${H_DB_HOST:-127.0.0.1}"
H_DB_PORT="${H_DB_PORT:-3306}"
H_PHP_BIN="${H_PHP_BIN:-php8.3}"
H_WEB_DIR="${H_WEB_DIR:-/opt/laesh/www}"

# Credenciales: sin default — deben pasarse explícitamente para evitar deploys
# con contraseñas genéricas en producción.
if [[ -z "${H_ROOT_PASS:-}" ]]; then
    echo "[ERROR] H_ROOT_PASS no definida."
    echo "        Ejecutar: H_ROOT_PASS='...' H_APP_PASS='...' bash setup_hostinger.sh --drop"
    exit 1
fi
if [[ -z "${H_APP_PASS:-}" ]]; then
    echo "[ERROR] H_APP_PASS no definida."
    echo "        Ejecutar: H_ROOT_PASS='...' H_APP_PASS='...' bash setup_hostinger.sh --drop"
    exit 1
fi

DROP_DB=false
if [[ "${1:-}" == "--drop" ]]; then
    DROP_DB=true
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Comando MariaDB nativo (no docker exec).
# Se conecta via socket local (sin -h) porque root@127.0.0.1 (TCP) no está
# permitido en MariaDB 11.8 por defecto — solo root@localhost via unix_socket.
MCMD="mariadb -u root -p${H_ROOT_PASS}"

# ── Verificar que MariaDB está corriendo ─────────────────────────────────────
if ! systemctl is-active --quiet mariadb 2>/dev/null && ! systemctl is-active --quiet mysql 2>/dev/null; then
    echo "[ERROR] MariaDB no está activo (systemd)."
    echo "        sudo systemctl start mariadb"
    exit 1
fi

echo "=================================================================="
echo " LAESH Bloc Digital — Setup BD (Hostinger KVM 2 — Nativo)"
echo " Host: ${H_DB_HOST}:${H_DB_PORT} | DB: laesh_db"
echo " DROP mode: ${DROP_DB}"
echo "=================================================================="

# ── PASO 1: DROP + recrear BD (solo con --drop) ───────────────────────────────
if $DROP_DB; then
    echo ""
    echo "── Paso 1: DROP + recrear laesh_db ────────────────────────────────"
    echo "   ⚠  Destruyendo BD laesh_db en MariaDB nativo..."
    ${MCMD} -e "DROP DATABASE IF EXISTS laesh_db;" 2>/dev/null
    echo "  ✓ DROP completado"
fi

# ── PASO 2: SQL 00–09 ─────────────────────────────────────────────────────────
run_sql_file() {
    local script="$1"
    local desc="$2"
    echo "→ Ejecutando ${script} (${desc})..."
    ${MCMD} < "${DIR}/${script}" 2>/dev/null
    echo "  ✓ OK"
}

echo ""
echo "── Paso 2: Schema + Seed SQL (10 scripts) ─────────────────────────"
run_sql_file "00_database.sql"             "BD + usuario laesh_app (pass dev — se corrige en paso 3)"
run_sql_file "01_auth_schema.sql"          "Auth schema (tablas Delight-Auth)"
run_sql_file "02_core_schema.sql"          "Core: configuraciones, web_contenidos, estudios"
run_sql_file "03_transactional_schema.sql" "Transaccional: ordenes, notificaciones, historial"
run_sql_file "04_auth_extensions.sql"      "Auth Extensions: empleados, perfiles, RBAC"
run_sql_file "05_system_tables.sql"        "Sistema: sys_logs, fallback_log"
run_sql_file "06_indexes.sql"              "Índices de rendimiento"
run_sql_file "07_seed_catalogs.sql"        "Seed: catálogos, estudios, configuraciones, web_contenidos"
run_sql_file "08_stored_procedures.sql"    "Stored Procedures: CrearOrden, ProcesarPDF"
run_sql_file "09_views.sql"               "Vistas: vw_ordenes_completas, vw_pacientes_historial"

# ── PASO 3: Corregir contraseña laesh_app (dev→producción) ───────────────────
echo ""
echo "── Paso 3: Fijando contraseña laesh_app → producción ──────────────"
${MCMD} -e "ALTER USER 'laesh_app'@'%' IDENTIFIED BY '${H_APP_PASS}'; FLUSH PRIVILEGES;" 2>/dev/null
echo "  ✓ laesh_app password actualizada"

# ── PASO 3b: Least Privilege — revocar GRANT ALL y aplicar solo DML ──────────
# 00_database.sql crea laesh_app con GRANT ALL PRIVILEGES para que root pueda
# ejecutar los 10 scripts DDL + seed sin problemas. Una vez que el schema está
# estable, el usuario de la aplicación solo debe poder hacer DML (SELECT/INSERT/
# UPDATE/DELETE). Sin DROP, ALTER, CREATE, INDEX, GRANT, etc.
# Este paso es idempotente: REVOKE silencioso si ya no tiene el privilegio.
echo ""
echo "── Paso 3b: Least Privilege laesh_app (REVOKE ALL + GRANT DML-only) ──"
${MCMD} <<'SQL_LEASTPRIV' 2>/dev/null
REVOKE ALL PRIVILEGES ON laesh_db.* FROM 'laesh_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON laesh_db.* TO 'laesh_app'@'%';
FLUSH PRIVILEGES;
SQL_LEASTPRIV
echo "  ✓ laesh_app limitada a SELECT, INSERT, UPDATE, DELETE (producción)"

# ── PASO 4: Seed usuarios via php nativo ─────────────────────────────────────
echo ""
echo "── Paso 4: Sembrando usuarios (${H_PHP_BIN} nativo) ────────────────"

PHP_SCRIPT="${H_WEB_DIR}/laesh-swbldi/commons/seed_first_users.php"

if [ ! -f "${PHP_SCRIPT}" ]; then
    echo "[ERROR] Script PHP no encontrado: ${PHP_SCRIPT}"
    echo "        Verifica que el rsync de laesh-swbldi haya completado."
    exit 1
fi

# Ejecutar fuera de set -e para capturar errores y mostrarlos en lugar de salir silencioso
set +e
DB_HOST="${H_DB_HOST}" \
DB_PORT="${H_DB_PORT}" \
DB_USER="laesh_app" \
DB_PASS="${H_APP_PASS}" \
DB_NAME="laesh_db" \
${H_PHP_BIN} "${PHP_SCRIPT}"
_SEED_EXIT=$?
set -e

if [ $_SEED_EXIT -ne 0 ]; then
    echo ""
    echo "  [△] seed_first_users.php terminó con código ${_SEED_EXIT}."
    echo "      Puede ser normal si los usuarios ya existen (idempotente)."
    echo "      Para verificar: mariadb -u root laesh_db -e \"SELECT email FROM users LIMIT 5;\""
else
    echo "  ✓ Usuarios sembrados correctamente"
fi

echo ""
echo "=================================================================="
echo " ✅ Setup Hostinger completo"
echo ""
echo " BD:       laesh_db (MariaDB nativo — systemd)"
echo " App user: laesh_app / [configurada]"
echo " Acceso:   https://laesh.mx/laesh/"
echo ""
echo " Usuarios demo (CAMBIAR antes de entregar al cliente):"
echo "   ADMIN     9990000001  010120001!"
echo "   RECEPCIÓN 9990000002  010120002!"
echo "   MÉDICO    9990000003  010120003!"
echo ""
echo " Verificar deploy:"
echo "   BASE=https://laesh.mx bash ${DIR}/bash/03_test_deploy.sh"
echo "=================================================================="
