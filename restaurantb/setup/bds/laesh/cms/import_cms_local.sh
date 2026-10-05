#!/usr/bin/env bash
# ==============================================================================
# import_cms_local.sh — Importar contenido CMS descargado de KVM2 a BD Local
#
# Objetivo:
#   Aplica el volcado de web_contenidos, catalogo_promociones y configuraciones
#   web a la base de datos MariaDB local usando las credenciales estándar de laesh.
#
# Credenciales soportadas (con defaults canónicos de laesh):
#   LAESH_DB_USER="${LAESH_DB_USER:-laesh_app}"
#   LAESH_DB_PASS="${LAESH_DB_PASS:-laesh_2026_dev}"
#   LAESH_DB_NAME="${LAESH_DB_NAME:-laesh_db}"
#   LAESH_DB_HOST="${LAESH_DB_HOST:-127.0.0.1}"
#   LAESH_DB_PORT="${LAESH_DB_PORT:-6002}"
#
# Detección automática:
#   - Si el contenedor docker 'restaurantb_db' está activo, ejecuta vía docker exec
#   - Si no, intenta conexión directa vía cliente mariadb/mysql local (puerto 6002 o 3306)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../" && pwd)"

LAESH_DB_USER="${LAESH_DB_USER:-laesh_app}"
LAESH_DB_PASS="${LAESH_DB_PASS:-laesh_2026_dev}"
LAESH_DB_NAME="${LAESH_DB_NAME:-laesh_db}"
LAESH_DB_HOST="${LAESH_DB_HOST:-127.0.0.1}"
LAESH_DB_PORT="${LAESH_DB_PORT:-6002}"

DOCKER_CONTAINER="restaurantb_db"
BUNDLE_FILE="${SCRIPT_DIR}/kvm2_cms_full_sync.sql"
CACHE_DIR="${REPO_ROOT}/www/laesh-swbldi/cache"

if [ ! -f "${BUNDLE_FILE}" ]; then
    echo "[ERROR] No se encontró el archivo ${BUNDLE_FILE}"
    echo "        Ejecuta primero: bash ${SCRIPT_DIR}/pull_cms_kvm2.sh"
    exit 1
fi

echo "=================================================================="
echo " LAESH — Importar Contenido CMS KVM2 → BD Local"
echo " Archivo fuente : $(basename "${BUNDLE_FILE}")"
echo " BD Destino     : ${LAESH_DB_NAME} (user: ${LAESH_DB_USER})"
echo "=================================================================="

# ── Determinar modo de ejecución (Docker vs Directo) ──────────────────────────
USE_DOCKER=0
if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -q "^${DOCKER_CONTAINER}$"; then
    USE_DOCKER=1
    echo "  [INFO] Detectado contenedor Docker '${DOCKER_CONTAINER}' activo."
    SQL_RUNNER="docker exec -i ${DOCKER_CONTAINER} mariadb -u${LAESH_DB_USER} -p${LAESH_DB_PASS} ${LAESH_DB_NAME}"
else
    echo "  [INFO] Ejecutando vía cliente MariaDB directo (${LAESH_DB_HOST}:${LAESH_DB_PORT})."
    SQL_RUNNER="mariadb -h ${LAESH_DB_HOST} -P ${LAESH_DB_PORT} -u${LAESH_DB_USER} -p${LAESH_DB_PASS} ${LAESH_DB_NAME}"
fi

# ── Conteo PREVIO ─────────────────────────────────────────────────────────────
echo ""
echo "  [1/3] Estado actual en BD Local ANTES de importar:"
${SQL_RUNNER} -e "
SELECT 'web_contenidos' AS tabla, COUNT(*) AS filas FROM web_contenidos
UNION ALL
SELECT 'catalogo_promociones', COUNT(*) FROM catalogo_promociones
UNION ALL
SELECT 'configuraciones', COUNT(*) FROM configuraciones;
"

# ── Ejecutar Importación ──────────────────────────────────────────────────────
echo ""
echo "  [2/3] Aplicando ${BUNDLE_FILE} en BD Local..."
${SQL_RUNNER} < "${BUNDLE_FILE}"

# ── Conteo POSTERIOR ──────────────────────────────────────────────────────────
echo ""
echo "  [3/3] Estado actual en BD Local DESPUÉS de importar:"
${SQL_RUNNER} -e "
SELECT 'web_contenidos' AS tabla, COUNT(*) AS filas FROM web_contenidos
UNION ALL
SELECT 'catalogo_promociones', COUNT(*) FROM catalogo_promociones
UNION ALL
SELECT 'configuraciones', COUNT(*) FROM configuraciones;
"

# ── Desglose por sección en web_contenidos ────────────────────────────────────
echo ""
echo "  Desglose de secciones en web_contenidos local:"
${SQL_RUNNER} -e "SELECT seccion, COUNT(*) AS filas FROM web_contenidos GROUP BY seccion ORDER BY seccion;"

# ── Limpieza de Caché L2 de la Webapp ─────────────────────────────────────────
if [ -d "${CACHE_DIR}" ]; then
    echo ""
    echo "  Limpiando archivos de caché L2 en ${CACHE_DIR}..."
    rm -f "${CACHE_DIR}"/*.cache.php "${CACHE_DIR}"/*.tmp 2>/dev/null || true
    echo "  [✓] Caché L2 local invalidada."
fi

echo ""
echo "=================================================================="
echo " ✅ Importación local finalizada exitosamente."
echo " Puedes verificar en el navegador:"
echo "   Sitio Web: https://192.168.1.71:8443/laesh/website/ (o http://localhost:6001/website/)"
echo "   CMS Admin: https://192.168.1.71:8443/laesh/adrc/gestion-web"
echo "=================================================================="
