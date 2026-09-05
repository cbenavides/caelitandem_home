#!/usr/bin/env bash
# ==============================================================================
# 05_import_cms_seed_kvm2.sh — Importar web_contenidos → KVM2 (sin --drop)
#
# Complemento de 04_export_cms_seed_local_oci.sh para el destino KVM2.
#
# Flujo completo CMS → KVM2:
#   1. Editar contenido en CMS local: https://192.168.1.71:8443/adrc/
#   2. Exportar:  bash setup/bds/laesh/bash/04_export_cms_seed_local_oci.sh
#   3. Revisar:   git diff setup/bds/laesh/07_seed_catalogs.sql
#   4. Importar:  bash setup/bds/laesh/bash/05_import_cms_seed_kvm2.sh
#      → aplica SOLO web_contenidos a KVM2 sin DROP, sin tocar datos operativos.
#
# Diferencia vs OCI:
#   OCI: rsync setup/ → setup_oci.sh --drop (recrea BD completa)
#   KVM2: este script extrae solo el bloque REPLACE INTO web_contenidos y
#         lo aplica via SSH sin DROP. Órdenes, pacientes e histórico se conservan.
#
# Variables:
#   KVM2_HOST       IP/hostname del servidor KVM2 (default: 83.136.219.193)
#   KVM2_USER       Usuario SSH (default: sysadmin)
#   KVM2_DB         Nombre de la BD (default: laesh_db)
#   KVM2_MARIADB_CNF Ruta al .cnf de credenciales en el servidor (default fijo)
#
# Uso:
#   bash setup/bds/laesh/bash/05_import_cms_seed_kvm2.sh
#   KVM2_HOST=staging.laesh.mx bash setup/bds/laesh/bash/05_import_cms_seed_kvm2.sh
# ==============================================================================

set -euo pipefail

KVM2_HOST="${KVM2_HOST:-83.136.219.193}"
KVM2_USER="${KVM2_USER:-sysadmin}"
KVM2_DB="${KVM2_DB:-laesh_db}"
KVM2_MARIADB_CNF="${KVM2_MARIADB_CNF:-/opt/laesh/configs/.mariadb-root.cnf}"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SEED_FILE="${DIR}/../07_seed_catalogs.sql"

echo "=================================================================="
echo " LAESH — Importar web_contenidos → KVM2 (sin DROP)"
echo " Destino: ${KVM2_USER}@${KVM2_HOST} → ${KVM2_DB}"
echo " Fuente:  $(basename ${SEED_FILE})"
echo "=================================================================="
echo ""

# ── Verificar que el seed existe ──────────────────────────────────────────────
if [ ! -f "$SEED_FILE" ]; then
    echo "[ERROR] No se encontró ${SEED_FILE}"
    echo "        Ejecutar primero: bash 04_export_cms_seed_local_oci.sh"
    exit 1
fi

# ── Extraer bloque REPLACE INTO web_contenidos ────────────────────────────────
# El bloque empieza con el marcador "-- WEB_CONTENIDOS" y termina con el
# primer ';' tras el REPLACE INTO (última línea del bloque generado por el export).
# La extracción usa awk: activa impresión desde el marcador hasta encontrar ';' solo.
TMP_SQL=$(mktemp /tmp/laesh_cms_import_XXXXXX.sql)
trap 'rm -f "${TMP_SQL}"' EXIT

awk '
    /-- WEB_CONTENIDOS — Contenido Editorial/ { inside=1 }
    inside { print }
    inside && /^[[:space:]]*;[[:space:]]*$/ { exit }
' "$SEED_FILE" > "$TMP_SQL"

if [ ! -s "$TMP_SQL" ]; then
    echo "[ERROR] No se encontró el bloque REPLACE INTO web_contenidos en $(basename ${SEED_FILE})"
    echo "        ¿Se ejecutó 04_export_cms_seed_local_oci.sh primero?"
    exit 1
fi

ROW_COUNT=$(grep -c "^    '" "$TMP_SQL" 2>/dev/null || echo "?")
BYTE_SIZE=$(wc -c < "$TMP_SQL")
echo "  Bloque extraído: ${ROW_COUNT} filas (~${BYTE_SIZE} bytes)"
echo ""

# ── Verificar conectividad SSH ────────────────────────────────────────────────
echo "  Verificando acceso SSH a ${KVM2_USER}@${KVM2_HOST}..."
if ! ssh -o ConnectTimeout=8 -o BatchMode=yes "${KVM2_USER}@${KVM2_HOST}" \
    "[ -f ${KVM2_MARIADB_CNF} ]" 2>/dev/null; then
    echo "[ERROR] No se pudo conectar a ${KVM2_USER}@${KVM2_HOST} o"
    echo "        ${KVM2_MARIADB_CNF} no existe en el servidor."
    echo "        Verificar: ssh ${KVM2_USER}@${KVM2_HOST} ls ${KVM2_MARIADB_CNF}"
    exit 1
fi
echo "  SSH OK · .mariadb-root.cnf encontrado en servidor"
echo ""

# ── Aplicar REPLACE INTO web_contenidos via SSH ───────────────────────────────
echo "  Aplicando web_contenidos en ${KVM2_HOST}:${KVM2_DB}..."
ssh "${KVM2_USER}@${KVM2_HOST}" \
    "mariadb --defaults-extra-file=${KVM2_MARIADB_CNF} ${KVM2_DB}" \
    < "$TMP_SQL"

echo ""
echo "=================================================================="
echo " ✅ Importación completada"
echo "    Filas web_contenidos aplicadas: ${ROW_COUNT}"
echo "    Servidor: ${KVM2_HOST} · BD: ${KVM2_DB}"
echo ""
echo " Verificar en producción:"
echo "   ssh ${KVM2_USER}@${KVM2_HOST} \\"
echo "     \"mariadb --defaults-extra-file=${KVM2_MARIADB_CNF} ${KVM2_DB} \\"
echo "       -e 'SELECT seccion, COUNT(*) FROM web_contenidos GROUP BY seccion;'\""
echo ""
echo " Probar en browser: https://laesh.mx/"
echo "=================================================================="
