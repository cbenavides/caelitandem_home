#!/usr/bin/env bash
# ==============================================================================
# pull_cms_kvm2.sh — Extraer contenido CMS y Assets desde KVM2 (Producción)
#
# Objetivo:
#   Descarga el contenido editorial del sitio web gestionado vía CMS en KVM2
#   y lo almacena localmente en setup/bds/laesh/cms/ sin alterar el SSOT existente.
#
# Componentes extraídos:
#   1. web_contenidos       (134 filas: hero, especialidades, calidad, etc.)
#   2. catalogo_promociones (7 filas: lunes a domingo con fondos webp)
#   3. configuraciones      (parámetros editoriales web/CMS: tel, horarios, etc.)
#   4. assets/cms/*.webp    (imágenes subidas por el CMS en KVM2 vía rsync)
#
# Uso:
#   bash pull_cms_kvm2.sh [--skip-images]
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../" && pwd)"

KVM2_SSH="${KVM2_SSH:-laesh-kvm2}"
KVM2_DB="${KVM2_DB:-laesh_db}"
KVM2_DB_USER="${KVM2_DB_USER:-laesh_app}"
KVM2_DB_PASS="${KVM2_DB_PASS:-laesh_2026_dev}"

KVM2_REMOTE_CMS_ASSETS="/opt/laesh/assets/laesh-web-assets-uipv1a/cms/"
LOCAL_CMS_ASSETS="${REPO_ROOT}/www/laesh-web-assets-uipv1a/cms/"

OUT_WEB_CONT="${SCRIPT_DIR}/kvm2_web_contenidos.sql"
OUT_PROMOS="${SCRIPT_DIR}/kvm2_catalogo_promociones.sql"
OUT_CONFIG="${SCRIPT_DIR}/kvm2_configuraciones_web.sql"
OUT_BUNDLE="${SCRIPT_DIR}/kvm2_cms_full_sync.sql"

SKIP_IMAGES=0
if [[ "${1:-}" == "--skip-images" ]]; then
    SKIP_IMAGES=1
fi

echo "=================================================================="
echo " LAESH — Pull CMS Contents from KVM2 (Producción → Local)"
echo " Servidor SSH : ${KVM2_SSH}"
echo " BD Remota    : ${KVM2_DB} (user: ${KVM2_DB_USER})"
echo " Directorio   : ${SCRIPT_DIR}"
echo "=================================================================="

# ── 1. Probar conectividad SSH ────────────────────────────────────────────────
echo -n "  Verificando conexión SSH a ${KVM2_SSH}... "
if ! ssh -o ConnectTimeout=8 -o BatchMode=yes "${KVM2_SSH}" "echo OK" >/dev/null 2>&1; then
    echo "ERROR"
    echo "  [ERROR] No se pudo conectar a ${KVM2_SSH}. Revisa ~/.ssh/config y claves SSH."
    exit 1
fi
echo "OK"

# ── 2. Extraer web_contenidos ─────────────────────────────────────────────────
echo "  [1/4] Descargando web_contenidos..."
ssh "${KVM2_SSH}" "mariadb-dump -h 127.0.0.1 -u '${KVM2_DB_USER}' -p'${KVM2_DB_PASS}' \
    --single-transaction --skip-lock-tables \
    --no-create-info --replace --complete-insert \
    --compact --skip-comments '${KVM2_DB}' web_contenidos" > "${OUT_WEB_CONT}"

COUNT_WEB_CONT=$(grep -c "REPLACE INTO" "${OUT_WEB_CONT}" || true)
SIZE_WEB_CONT=$(wc -c < "${OUT_WEB_CONT}")
echo "        -> Guardado en $(basename "${OUT_WEB_CONT}") (${SIZE_WEB_CONT} bytes)"

# ── 3. Extraer catalogo_promociones ───────────────────────────────────────────
echo "  [2/4] Descargando catalogo_promociones..."
ssh "${KVM2_SSH}" "mariadb-dump -h 127.0.0.1 -u '${KVM2_DB_USER}' -p'${KVM2_DB_PASS}' \
    --single-transaction --skip-lock-tables \
    --no-create-info --replace --complete-insert \
    --compact --skip-comments '${KVM2_DB}' catalogo_promociones" > "${OUT_PROMOS}"

SIZE_PROMOS=$(wc -c < "${OUT_PROMOS}")
echo "        -> Guardado en $(basename "${OUT_PROMOS}") (${SIZE_PROMOS} bytes)"

# ── 4. Extraer configuraciones editoriales del sitio web ──────────────────────
echo "  [3/4] Descargando configuraciones editoriales del sitio web..."
ssh "${KVM2_SSH}" "mariadb -h 127.0.0.1 -u '${KVM2_DB_USER}' -p'${KVM2_DB_PASS}' '${KVM2_DB}' --skip-column-names --batch" << 'EOF' > "${OUT_CONFIG}"
SELECT CONCAT(
    'INSERT INTO `configuraciones` (`clave`, `valor`, `descripcion`) VALUES\n',
    GROUP_CONCAT(
        CONCAT('    (\'', clave, '\', \'', REPLACE(REPLACE(valor, '\\', '\\\\'), '\'', '\'\''), '\', NULL)')
        ORDER BY clave
        SEPARATOR ',\n'
    ),
    '\nON DUPLICATE KEY UPDATE `valor` = VALUES(`valor`);'
)
FROM configuraciones
WHERE clave IN (
  'telefono', 'email_contacto', 'whatsapp_numero', 'whatsapp_url', 'facebook_url',
  'direccion', 'direccion_calle', 'ciudad', 'estado', 'cp',
  'horario_semana', 'horario_domingo', 'hrs_open', 'hrs_close', 'dom_open', 'dom_close',
  'responsable_nombre', 'responsable_cedula_prof', 'responsable_cedula_esp',
  'nombre_laboratorio', 'nombre_corto', 'maps_url', 'geo_lat', 'geo_lng',
  'video_active', 'wa_texto_info', 'wa_texto_agendar'
);
EOF

SIZE_CONFIG=$(wc -c < "${OUT_CONFIG}")
echo "        -> Guardado en $(basename "${OUT_CONFIG}") (${SIZE_CONFIG} bytes)"

# ── 5. Crear Bundle Unificado ─────────────────────────────────────────────────
cat << 'HEADER' > "${OUT_BUNDLE}"
-- =============================================================================
-- kvm2_cms_full_sync.sql — Sincronización Completa de Contenido CMS desde KVM2
-- Generado automáticamente por pull_cms_kvm2.sh
-- Fecha: $(date '+%Y-%m-%d %H:%M:%S')
-- Contenido: web_contenidos + catalogo_promociones + configuraciones web
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

HEADER

echo "-- 1. WEB_CONTENIDOS (KVM2)" >> "${OUT_BUNDLE}"
cat "${OUT_WEB_CONT}" >> "${OUT_BUNDLE}"
echo -e "\n\n-- 2. CATALOGO_PROMOCIONES (KVM2)" >> "${OUT_BUNDLE}"
cat "${OUT_PROMOS}" >> "${OUT_BUNDLE}"
echo -e "\n\n-- 3. CONFIGURACIONES EDITORIALES WEB (KVM2)" >> "${OUT_BUNDLE}"
cat "${OUT_CONFIG}" >> "${OUT_BUNDLE}"
echo -e "\n\nSET FOREIGN_KEY_CHECKS = 1;" >> "${OUT_BUNDLE}"

SIZE_BUNDLE=$(wc -c < "${OUT_BUNDLE}")
echo "  [✓] Bundle unificado generado en $(basename "${OUT_BUNDLE}") (${SIZE_BUNDLE} bytes)"

# ── 6. Sincronización de Imágenes CMS vía rsync ───────────────────────────────
if [[ ${SKIP_IMAGES} -eq 0 ]]; then
    echo "  [4/4] Sincronizando imágenes físicas del CMS desde KVM2..."
    mkdir -p "${LOCAL_CMS_ASSETS}"
    rsync -avz --update "${KVM2_SSH}:${KVM2_REMOTE_CMS_ASSETS}" "${LOCAL_CMS_ASSETS}/"
    echo "        -> Imágenes sincronizadas en ${LOCAL_CMS_ASSETS}"
else
    echo "  [4/4] Sincronización de imágenes omitida (--skip-images)."
fi

echo ""
echo "=================================================================="
echo " ✅ Extracción completada con éxito."
echo " Para aplicar a tu base de datos local, ejecuta:"
echo "   bash ${SCRIPT_DIR}/import_cms_local.sh"
echo "=================================================================="
