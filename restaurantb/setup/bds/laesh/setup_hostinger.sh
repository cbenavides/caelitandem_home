#!/usr/bin/env bash
# ==============================================================================
# setup_hostinger.sh — Setup Orchestrator LAESH · Hostinger KVM 2
#
# Stack Hostinger: Nginx nativo + PHP 8.3-FPM nativo + MariaDB 11.8 nativo
# (sin Docker para ningún componente — diferencia clave vs OCI)
#
# Pipeline:
# DOS ESCENARIOS DE USO:
#
#   A) Setup desde cero  (servidor nuevo / --nuke):
#      setup_hostinger.sh --drop
#        Paso 1  → DROP + recrear BD
#        Paso 2  → SQL 00–09 (schema + seed completo)
#        Paso 2b → no-op (migrations/ sin m*.sql activos)
#        Paso 3  → laesh_app password producción
#        Paso 3b → Least Privilege DML-only
#        Paso 4  → Seed usuarios
#
#   B) Deploy incremental  (BD viva, sin reconstruir):
#      Crear migrations/mNNN_*.sql → deploy.sh bd
#        Paso 1  → omitido (sin --drop)
#        Paso 2  → omitido (sin --drop)
#        Paso 2b → aplica m*.sql pendientes (idempotentes)
#        Paso 3  → laesh_app password (idempotente)
#        Paso 3b → Least Privilege (idempotente)
#        Paso 4  → Seed usuarios (idempotente — skip si ya existen)
#
# Scripts base 00–09 = SSOT del schema completo (setup desde cero).
# migrations/m*.sql  = deltas incrementales a BD viva (fold al base tras validar).
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

# ── Credenciales ─────────────────────────────────────────────────────────────
# Prioridad para root: env var H_ROOT_PASS → /opt/laesh/configs/.mariadb-root.cnf
# Prioridad para app:  env var H_APP_PASS  → /opt/laesh/configs/.env → error
MARIADB_ROOT_CNF="/opt/laesh/configs/.mariadb-root.cnf"
LAESH_ENV_FILE="/opt/laesh/configs/.env"

# Root password — sed en vez de grep -P (evita bug PCRE2 variable-width lookbehind + set -e)
if [[ -z "${H_ROOT_PASS:-}" ]] && [[ -f "${MARIADB_ROOT_CNF}" ]]; then
    H_ROOT_PASS="$(sed -n 's/^[[:space:]]*password[[:space:]]*=[[:space:]]*//p' "${MARIADB_ROOT_CNF}" 2>/dev/null | head -1 | tr -d $'\r')" || true
    [[ -n "${H_ROOT_PASS:-}" ]] && echo "[INFO] H_ROOT_PASS leída desde ${MARIADB_ROOT_CNF}"
fi
if [[ -z "${H_ROOT_PASS:-}" ]]; then
    echo "[ERROR] H_ROOT_PASS no definida."
    echo "        Necesaria en: ${MARIADB_ROOT_CNF} (campo password=) o env var H_ROOT_PASS"
    exit 1
fi

# App password (laesh_app) — lookbehind fixed-width, funciona en PCRE2; || true protege set -e
if [[ -z "${H_APP_PASS:-}" ]] && [[ -f "${LAESH_ENV_FILE}" ]]; then
    H_APP_PASS="$(grep -Po '(?<=^LAESH_APP_PASS=)[^#]+' "${LAESH_ENV_FILE}" 2>/dev/null | head -1 | tr -d " '\"")" || true
    [[ -n "${H_APP_PASS:-}" ]] && echo "[INFO] H_APP_PASS leída desde ${LAESH_ENV_FILE}"
fi
if [[ -z "${H_APP_PASS:-}" ]]; then
    echo "[ERROR] H_APP_PASS no definida."
    echo "        Crear ${LAESH_ENV_FILE} con: LAESH_APP_PASS=tu-contraseña"
    echo "        O pasar: H_APP_PASS='...' bash setup_hostinger.sh --drop"
    exit 1
fi

# JWT secret — Paso 4 invoca seed_first_users.php, que requiere commons/config.php,
# y config.php lanza RuntimeException fail-loud si LAESH_JWT_SECRET falta en el
# entorno. Sin esto, Paso 4 fallaba en silencio (exit 255, sin ningún mensaje —
# mismo patrón ya documentado para cache_renew.php/cms_cleanup.php: display_errors=Off
# en CLI de producción oculta el fatal). Auditoría 2026-09-20.
if [[ -z "${H_JWT_SECRET:-}" ]] && [[ -f "${LAESH_ENV_FILE}" ]]; then
    H_JWT_SECRET="$(grep -Po '(?<=^LAESH_JWT_SECRET=)[^#]+' "${LAESH_ENV_FILE}" 2>/dev/null | head -1 | tr -d " '\"")" || true
    [[ -n "${H_JWT_SECRET:-}" ]] && echo "[INFO] H_JWT_SECRET leída desde ${LAESH_ENV_FILE}"
fi
if [[ -z "${H_JWT_SECRET:-}" ]]; then
    echo "[ERROR] H_JWT_SECRET no definida."
    echo "        Necesaria en: ${LAESH_ENV_FILE} (campo LAESH_JWT_SECRET=) o env var H_JWT_SECRET"
    exit 1
fi

DROP_DB=false
if [[ "${1:-}" == "--drop" ]]; then
    DROP_DB=true
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Comando MariaDB: usa --defaults-extra-file (no expone password en ps) cuando el cnf existe.
if [[ -f "${MARIADB_ROOT_CNF}" ]]; then
    MCMD="mariadb --defaults-extra-file=${MARIADB_ROOT_CNF}"
else
    MCMD="mariadb -u root -p${H_ROOT_PASS}"
fi

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

# ── PASO 2: SQL 00–09 (SOLO con --drop) ───────────────────────────────────────
# INCIDENTE 2026-09-19: este bloque corría SIEMPRE, sin importar $DROP_DB —
# contradiciendo el propio contrato documentado arriba ("Escenario B: Paso 2 →
# omitido sin --drop"). 00_database.sql tiene un DROP DATABASE IF EXISTS
# incondicional (intencional para uso directo en Docker local/dev) — al correr
# Paso 2 sin --drop en KVM2 producción, ese DROP se ejecutó igual, destruyendo
# laesh_db completa (usuarios, órdenes, pacientes, notificaciones...) durante lo
# que se asumía era un re-apply idempotente y seguro. Restaurado desde el backup
# de la noche anterior + reaplicado el delta de schema faltante a mano. Fix: el
# bloque completo (incluyendo 00_database.sql) ahora solo corre con --drop —
# el modo idempotente real vive en Paso 2b (migrations/) tal como ya decía el
# docstring del Escenario B.
run_sql_file() {
    local script="$1"
    local desc="$2"
    echo "→ Ejecutando ${script} (${desc})..."
    ${MCMD} < "${DIR}/${script}" 2>/dev/null
    echo "  ✓ OK"
}

echo ""
if $DROP_DB; then
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
    run_sql_file "09_views.sql"               "Vistas: vw_ordenes_completas"
else
    echo "── Paso 2: omitido (sin --drop) — BD viva preservada intacta ───────"
    echo "  △ Cambios de schema post-instalación inicial van en migrations/mNNN_*.sql (Paso 2b)"
fi

# ── PASO 2b: Migraciones incrementales (migrations/m*.sql en orden) ──────────
# Con --drop: no-op (BD recién creada desde 00-09, sin deltas pendientes).
# Sin --drop: aplica los m*.sql que existan — deploy incremental a BD viva.
# Cada m*.sql debe ser idempotente. Tras validar: fold al script base y eliminar.
echo ""
echo "── Paso 2b: Migraciones incrementales ─────────────────────────────"
MIGRATIONS_DIR="${DIR}/migrations"
if [ -d "${MIGRATIONS_DIR}" ]; then
    mapfile -t MIGRATION_FILES < <(find "${MIGRATIONS_DIR}" -maxdepth 1 -name 'm*.sql' | sort)
    if [ ${#MIGRATION_FILES[@]} -eq 0 ]; then
        echo "  (sin migraciones pendientes)"
    else
        for mfile in "${MIGRATION_FILES[@]}"; do
            mname="$(basename "${mfile}")"
            echo "→ Aplicando migración ${mname}..."
            ${MCMD} < "${mfile}"
            echo "  ✓ ${mname} OK"
        done
    fi
else
    echo "  (directorio migrations/ no encontrado — omitiendo)"
fi

# ── PASO 3: Corregir contraseña laesh_app (dev→producción) ───────────────────
echo ""
echo "── Paso 3: Fijando contraseña laesh_app → producción ──────────────"
${MCMD} -e "ALTER USER 'laesh_app'@'%' IDENTIFIED BY '${H_APP_PASS}'; FLUSH PRIVILEGES;" 2>/dev/null
echo "  ✓ laesh_app password actualizada"

# ── PASO 3b: Least Privilege — revocar GRANT ALL y aplicar solo DML+EXECUTE ──
# 00_database.sql crea laesh_app con GRANT ALL PRIVILEGES para que root pueda
# ejecutar los 10 scripts DDL + seed sin problemas. Una vez que el schema está
# estable, el usuario de la aplicación solo debe poder hacer DML (SELECT/INSERT/
# UPDATE/DELETE) + EXECUTE sobre los stored procedures. Sin DROP, ALTER, CREATE,
# INDEX, GRANT, etc.
# Este paso es idempotente: REVOKE silencioso si ya no tiene el privilegio.
#
# INCIDENTE 2026-09-19: el REVOKE ALL + GRANT DML-only original NO incluía
# EXECUTE sobre CrearOrdenLaboratorio (08_stored_procedures.sql) — cualquier
# ejecución de este Paso 3b (siempre corre, con o sin --drop) dejaba la
# creación de órdenes rota con error 1370 "execute command denied", sin que
# ningún log de la app lo hiciera evidente hasta que un usuario real intentó
# guardar una orden. Detectado en producción vía app.log.
#
# INCIDENTE 2026-09-20: ProcesarCargaResultadoPDF fue eliminado como código
# muerto (H5, auditoría de esta fecha — ver 08_stored_procedures.sql). El
# GRANT EXECUTE sobre ese procedimiento (ya inexistente) hacía fallar todo
# el heredoc silenciosamente (2>/dev/null oculta el error de MariaDB, y sin
# --force el cliente mysql aborta en el primer statement fallido) — set -e
# del script mataba el setup completo justo después de imprimir el
# encabezado "Paso 3b", sin ningún mensaje de error visible.
echo ""
echo "── Paso 3b: Least Privilege laesh_app (REVOKE ALL + GRANT DML + EXECUTE) ──"
# Auditoría 2026-09-21: GRANT EXECUTE sobre CambiarEstadoOrden NUNCA existió aquí
# — solo CrearOrdenLaboratorio tenía el grant. Cualquier cambio de estado real
# (Recibir Paciente, Cancelar, Entregar/Cerrar, subir PDF de resultados — los 4
# pasan por este SP) fallaba con error 1370 "execute command denied" en
# producción. Detectado con la suite de pruebas de interacciones WS RC↔Médico
# (el mismo patrón de bug ya documentado en pending.md — quinta regresión del
# incidente DROP del 2026-09-19 — pero nunca se había agregado el grant base
# aquí, ni siquiera antes de esa regresión).
${MCMD} <<'SQL_LEASTPRIV' 2>/dev/null
REVOKE ALL PRIVILEGES ON laesh_db.* FROM 'laesh_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON laesh_db.* TO 'laesh_app'@'%';
GRANT EXECUTE ON PROCEDURE laesh_db.CrearOrdenLaboratorio TO 'laesh_app'@'%';
GRANT EXECUTE ON PROCEDURE laesh_db.CambiarEstadoOrden TO 'laesh_app'@'%';
FLUSH PRIVILEGES;
SQL_LEASTPRIV
echo "  ✓ laesh_app limitada a SELECT, INSERT, UPDATE, DELETE + EXECUTE sobre stored procedures (producción)"

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
# Pasar env vars con el prefijo LAESH_ que lee config.php (BUG fix: antes pasaba DB_*, no LAESH_DB_*)
LAESH_DB_HOST="${H_DB_HOST}" \
LAESH_DB_PORT="${H_DB_PORT}" \
LAESH_DB_USER="laesh_app" \
LAESH_DB_PASS="${H_APP_PASS}" \
LAESH_DB_NAME="laesh_db" \
LAESH_JWT_SECRET="${H_JWT_SECRET}" \
APP_ENV="production" \
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
echo "   ADMIN     9990000001  04041980"
echo "   RECEPCIÓN 9990000002  04041981"
echo "   MÉDICO 1  9990000003  04041982"
echo "   MÉDICO 2  9990000004  04041983"
echo "   MÉDICO 3  9990000005  04041984"
echo "   MÉDICO 4  9990000006  04041985"
echo "   MÉDICO 5  9990000007  04041986"
echo ""
echo " Verificar deploy:"
echo "   BASE=https://laesh.mx bash ${DIR}/bash/verify/03_test_deploy.sh"
echo ""
echo " Verificar trazabilidad E2E (G2–G5):"
echo "   H_ROOT_PASS='${H_ROOT_PASS}' bash ${DIR}/bash/kvm2/06_verify_traceability.sh"
echo "=================================================================="
