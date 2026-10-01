#!/usr/bin/env bash
# ==============================================================================
# setup_oci.sh — Setup BD LAESH · VM OCI (ambiente de PRUEBAS)
#
# Corre DENTRO de la VM OCI (lo invoca deploy_oci_laesh.sh vía ssh).
# Mismo contrato que setup_hostinger.sh (KVM2 producción), adaptado a OCI:
#   • MariaDB en contenedor Docker `laesh_db` (contenedor/oci-vm/docker-compose.yml),
#     publicado en 127.0.0.1:6002 — el pool php8.1-fpm ya apunta ahí.
#   • Root password: se lee del propio contenedor ($MARIADB_ROOT_PASSWORD de su .env).
#   • PHP nativo php8.1 para el seed de usuarios.
#
# Pipeline:
#   Paso 1  → DROP + recrear BD                       (solo con --drop)
#   Paso 1b → mariadb-upgrade (idempotente)
#   Paso 2  → SQL 00–09 (schema + seed completo)      (solo con --drop)
#   Paso 2b → migrations/m*.sql pendientes            (solo SIN --drop)
#   Paso 3  → contraseña laesh_app = la del pool php8.1-fpm (idempotente)
#   Paso 4  → seed de usuarios (solo crea los que falten — PEN-LAESH-06)
#
# 2026-10-01: antes Paso 2 corría SIEMPRE, y 00_database.sql trae
# DROP DATABASE IF EXISTS → cada deploy "sin --drop" destruía la BD de OCI
# (mismo bug que ya se corrigió en setup_hostinger.sh). Ahora 00–09 solo
# corren con --drop, igual que en KVM2.
#
# Uso (en OCI):
#   bash setup/bds/laesh/setup_oci.sh           # BD viva: solo migraciones + seed faltante
#   bash setup/bds/laesh/setup_oci.sh --drop    # reconstruye la BD de pruebas desde 00–09
#
# Variables sobreescribibles:
#   OCI_DB_CONTAINER  contenedor MariaDB          (default: laesh_db)
#   OCI_DB_PORT       puerto publicado            (default: 6002)
#   OCI_APP_PASS      contraseña laesh_app        (default: la de env[LAESH_DB_PASS] del pool)
#   OCI_PHP_BIN       binario PHP                 (default: php8.1)
#   OCI_WEB_DIR       raíz www/ del stack         (default: /home/ubuntu/laesh-stack/www)
# ==============================================================================

set -euo pipefail

OCI_DB_CONTAINER="${OCI_DB_CONTAINER:-laesh_db}"
OCI_DB_PORT="${OCI_DB_PORT:-6002}"
OCI_PHP_BIN="${OCI_PHP_BIN:-php8.1}"
OCI_WEB_DIR="${OCI_WEB_DIR:-/home/ubuntu/laesh-stack/www}"
FPM_POOL="/etc/php/8.1/fpm/pool.d/www.conf"

DROP_DB=false
[[ "${1:-}" == "--drop" ]] && DROP_DB=true

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Contraseña de laesh_app: la misma que usa PHP-FPM (una sola fuente de verdad).
if [[ -z "${OCI_APP_PASS:-}" ]]; then
    OCI_APP_PASS="$(sed -n 's/^env\[LAESH_DB_PASS\][[:space:]]*=[[:space:]]*//p' "${FPM_POOL}" 2>/dev/null | tail -1)"
fi
[[ -n "${OCI_APP_PASS}" ]] || { echo "[ERROR] OCI_APP_PASS vacío y sin env[LAESH_DB_PASS] en ${FPM_POOL}"; exit 1; }

if ! docker ps --format '{{.Names}}' | grep -q "^${OCI_DB_CONTAINER}$"; then
    echo "[ERROR] Contenedor '${OCI_DB_CONTAINER}' no está corriendo."
    echo "        cd /home/ubuntu/laesh-stack && docker compose --env-file .env up -d"
    exit 1
fi

# Root vía la variable del propio contenedor — sin contraseñas en este script.
mdb() { docker exec -i "${OCI_DB_CONTAINER}" sh -c 'exec mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" "$@"' mariadb "$@"; }

run_sql_file() {
    echo "→ ${1} (${2})"
    mdb < "${DIR}/${1}"
    echo "  ✓ OK"
}

echo "=================================================================="
echo " LAESH — Setup BD (VM OCI · pruebas)"
echo " Contenedor: ${OCI_DB_CONTAINER} | DROP: ${DROP_DB}"
echo "=================================================================="

# ── PASO 1: DROP (solo --drop) ────────────────────────────────────────────────
if $DROP_DB; then
    echo ""
    echo "── Paso 1: DROP laesh_db ───────────────────────────────────────────"
    mdb -e "DROP DATABASE IF EXISTS laesh_db;"
    echo "  ✓ DROP completado"
fi

# ── PASO 1b: mariadb-upgrade (idempotente) ────────────────────────────────────
# Sin esto, tras un cambio de versión del contenedor, CREATE PROCEDURE falla
# con HY000-1558 (mysql.proc desactualizado).
echo ""
echo "── Paso 1b: mariadb-upgrade ───────────────────────────────────────"
if docker exec "${OCI_DB_CONTAINER}" sh -c 'mariadb-upgrade -uroot -p"$MARIADB_ROOT_PASSWORD" --silent' 2>/dev/null; then
    echo "  ✓ OK"
else
    echo "  ~ ya actualizado o no disponible — continuando"
fi

# ── PASO 2: schema + seed 00–09 (solo --drop) ─────────────────────────────────
echo ""
if $DROP_DB; then
    echo "── Paso 2: Schema + Seed SQL (10 scripts) ─────────────────────────"
    run_sql_file "00_database.sql"             "BD + usuario laesh_app"
    run_sql_file "01_auth_schema.sql"          "Auth schema (Delight-Auth)"
    run_sql_file "02_core_schema.sql"          "Core"
    run_sql_file "03_transactional_schema.sql" "Transaccional"
    run_sql_file "04_auth_extensions.sql"      "Auth Extensions + RBAC"
    run_sql_file "05_system_tables.sql"        "Sistema"
    run_sql_file "06_indexes.sql"              "Índices"
    run_sql_file "07_seed_catalogs.sql"        "Seed catálogos / CMS"
    run_sql_file "08_stored_procedures.sql"    "Stored Procedures"
    run_sql_file "09_views.sql"                "Vistas"
else
    echo "── Paso 2: omitido (sin --drop) — BD viva preservada ───────────────"
fi

# ── PASO 2b: migraciones (solo sin --drop) ────────────────────────────────────
echo ""
echo "── Paso 2b: Migraciones incrementales ─────────────────────────────"
if $DROP_DB; then
    echo "  (no-op con --drop: la BD se acaba de crear desde 00–09)"
else
    mapfile -t MIGRATION_FILES < <(find "${DIR}/migrations" -maxdepth 1 -name 'm*.sql' 2>/dev/null | sort)
    if [ ${#MIGRATION_FILES[@]} -eq 0 ]; then
        echo "  (sin migraciones pendientes)"
    else
        for mfile in "${MIGRATION_FILES[@]}"; do
            echo "→ $(basename "${mfile}")"
            mdb < "${mfile}"
            echo "  ✓ OK"
        done
    fi
fi

# ── PASO 3: contraseña laesh_app = la del pool PHP-FPM ───────────────────────
echo ""
echo "── Paso 3: laesh_app → contraseña del pool php8.1-fpm ─────────────"
mdb -e "ALTER USER 'laesh_app'@'%' IDENTIFIED BY '${OCI_APP_PASS}'; FLUSH PRIVILEGES;"
echo "  ✓ OK"

# ── PASO 4: seed de usuarios (solo los que falten) ───────────────────────────
echo ""
echo "── Paso 4: Seed usuarios (${OCI_PHP_BIN}) ──────────────────────────"
PHP_SCRIPT="${OCI_WEB_DIR}/laesh-swbldi/commons/seed_first_users.php"
[[ -f "${PHP_SCRIPT}" ]] || { echo "[ERROR] No existe ${PHP_SCRIPT} — sincronizar laesh-swbldi primero"; exit 1; }
LAESH_DB_HOST="127.0.0.1" \
LAESH_DB_PORT="${OCI_DB_PORT}" \
LAESH_DB_USER="laesh_app" \
LAESH_DB_PASS="${OCI_APP_PASS}" \
LAESH_DB_NAME="laesh_db" \
"${OCI_PHP_BIN}" "${PHP_SCRIPT}"

echo ""
echo "=================================================================="
echo " ✅ Setup BD OCI completo — https://caelitandem.lat/laesh/"
echo "    Usuarios demo: ver tabla impresa por seed_first_users.php"
echo "=================================================================="
