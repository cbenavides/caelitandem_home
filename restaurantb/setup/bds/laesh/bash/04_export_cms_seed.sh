#!/usr/bin/env bash
# ==============================================================================
# 04_export_cms_seed.sh — Ciclo CMS → Seed → OCI
#
# Exporta web_contenidos desde la BD local (fuente de verdad) y
# regenera el bloque REPLACE INTO de 07_seed_catalogs.sql.
#
# Cuándo ejecutar:
#   Después de editar contenido en el CMS local (ADMRC → Gestión Web)
#   y antes de un rsync + DROP+recreate en OCI VM.
#
# Protocolo completo CMS → OCI:
#   1. Editar en CMS local: https://192.168.1.71:8443/laesh/adrc/
#   2. bash setup/bds/laesh/bash/04_export_cms_seed.sh
#   3. Revisar el diff de 07_seed_catalogs.sql (git diff)
#   4. rsync laesh-swbldi/ y setup/bds/laesh/ a OCI
#   5. En OCI: bash setup_oci.sh --drop
#
# Variables sobreescribibles:
#   DB_CONTAINER   Contenedor MariaDB local (default: restaurantb_db)
#   DB_USER        Usuario raíz local (default: root)
#   DB_PASS        Contraseña raíz local (default: comite_2026)
#   DB_NAME        BD local (default: laesh_db)
# ==============================================================================

set -euo pipefail

DB_CONTAINER="${DB_CONTAINER:-restaurantb_db}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-comite_2026}"
DB_NAME="${DB_NAME:-laesh_db}"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SEED_FILE="${DIR}/../07_seed_catalogs.sql"
TMP_EXPORT="${DIR}/../.tmp_web_contenidos_export.sql"

# ── Verificar contenedor local corriendo ─────────────────────────────────────
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    echo "[ERROR] Contenedor '${DB_CONTAINER}' no está corriendo."
    echo "        Ejecuta: docker compose up -d"
    exit 1
fi

echo "=================================================================="
echo " LAESH — Exportar web_contenidos → 07_seed_catalogs.sql"
echo " Fuente: ${DB_CONTAINER} → ${DB_NAME}.web_contenidos"
echo " Destino: $(basename ${SEED_FILE})"
echo "=================================================================="
echo ""

# ── Contar filas actuales ─────────────────────────────────────────────────────
ROW_COUNT=$(docker exec -i "${DB_CONTAINER}" \
    mariadb -u"${DB_USER}" -p"${DB_PASS}" -N -e \
    "SELECT COUNT(*) FROM ${DB_NAME}.web_contenidos;" 2>/dev/null)
echo "  Filas en web_contenidos local: ${ROW_COUNT}"

# ── Exportar web_contenidos como REPLACE INTO ─────────────────────────────────
echo "  Exportando..."

docker exec -i "${DB_CONTAINER}" \
    mariadb -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" \
    --skip-column-names --batch 2>/dev/null <<'EOF' > "${TMP_EXPORT}"
SELECT CONCAT(
    'REPLACE INTO `web_contenidos` (`seccion`, `subseccion`, `clave`, `valor`, `tipo`) VALUES\n',
    GROUP_CONCAT(
        CONCAT(
            "    ('", seccion, "', ",
            IF(subseccion IS NULL, 'NULL', CONCAT("'", REPLACE(subseccion, "'", "''"), "'")), ", '",
            REPLACE(clave,  "'", "''"), "', '",
            REPLACE(REPLACE(valor, '\\', '\\\\'), "'", "''"), "', '",
            tipo, "')"
        )
        ORDER BY seccion, subseccion, clave
        SEPARATOR ',\n'
    ),
    ';'
)
FROM web_contenidos;
EOF

if [ ! -s "${TMP_EXPORT}" ]; then
    echo "[ERROR] Export vacío — verificar conexión y datos en web_contenidos"
    rm -f "${TMP_EXPORT}"
    exit 1
fi

# ── Reemplazar sección web_contenidos en 07_seed_catalogs.sql ────────────────
# La sección empieza con el marcador y termina con el siguiente marcador de sección.

MARKER_START="-- ---------------------------------------------------------------------------"
SECTION_HEADER="-- WEB_CONTENIDOS — Contenido Editorial"

# Verificar que el marcador exista en el archivo
if ! grep -q "${SECTION_HEADER}" "${SEED_FILE}"; then
    echo "[ERROR] No se encontró el marcador '${SECTION_HEADER}' en $(basename ${SEED_FILE})"
    echo "        El archivo puede haber cambiado de estructura."
    rm -f "${TMP_EXPORT}"
    exit 1
fi

# Obtener número de línea donde empieza la sección web_contenidos
SECTION_LINE=$(grep -n "${SECTION_HEADER}" "${SEED_FILE}" | head -1 | cut -d: -f1)
# La sección del separador empieza 1 línea antes
START_LINE=$((SECTION_LINE - 1))
TOTAL_LINES=$(wc -l < "${SEED_FILE}")

echo "  Sección web_contenidos en ${SEED_FILE}:${START_LINE}–${TOTAL_LINES}"

# Preservar todo hasta el marcador (inclusive la línea START_LINE - 1)
BEFORE_SECTION=$(head -n $((START_LINE - 1)) "${SEED_FILE}")

# Construir nueva sección
NEW_SECTION="-- ---------------------------------------------------------------------------
-- WEB_CONTENIDOS — Contenido Editorial
-- SSOT: exportado de BD local (${DB_NAME}) — $(date '+%Y-%m-%d %H:%M')
-- Regenerar con: bash setup/bds/laesh/bash/04_export_cms_seed.sh
-- REPLACE INTO garantiza que el seed siempre sobreescriba ediciones CMS.
-- ---------------------------------------------------------------------------

$(cat "${TMP_EXPORT}")"

# Escribir archivo resultante
{
    echo "${BEFORE_SECTION}"
    echo ""
    echo "${NEW_SECTION}"
} > "${SEED_FILE}.tmp"

mv "${SEED_FILE}.tmp" "${SEED_FILE}"
rm -f "${TMP_EXPORT}"

FINAL_LINES=$(wc -l < "${SEED_FILE}")
echo ""
echo "=================================================================="
echo " ✅ Exportación completada"
echo "    Filas web_contenidos: ${ROW_COUNT}"
echo "    Archivo: $(basename ${SEED_FILE}) (${FINAL_LINES} líneas)"
echo ""
echo " Próximos pasos:"
echo "   1. git diff setup/bds/laesh/07_seed_catalogs.sql"
echo "   2. rsync setup/bds/laesh/ a OCI"
echo "   3. En OCI: bash setup_oci.sh --drop"
echo "   4. bash setup/bds/laesh/bash/03_test_deploy.sh"
echo "=================================================================="
