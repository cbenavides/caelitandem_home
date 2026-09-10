#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# deploy.sh — Despliegue canónico a KVM2 (laesh.mx producción)
#
# Todas las rutas se leen de SERVER_MAP.env (mismo directorio).
# NO hardcodear rutas aquí — editar SERVER_MAP.env.
#
# USO (desde raíz del repo restaurantb):
#   bash setup/deploy/laesh-kvm2-prod/deploy.sh webapp    # PHP app
#   bash setup/deploy/laesh-kvm2-prod/deploy.sh assets    # CSS/JS/img
#   bash setup/deploy/laesh-kvm2-prod/deploy.sh scripts   # setup/BD scripts
#   bash setup/deploy/laesh-kvm2-prod/deploy.sh all       # las 3
#
# Actualizado: 2026-09-09
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Cargar mapa de rutas canónico ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/SERVER_MAP.env"

# ── Verificar raíz del repo ───────────────────────────────────────────────────
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
if [[ ! -d "${REPO_ROOT}/www/laesh-swbldi" ]]; then
    echo "✗ ERROR: Ejecutar desde raíz del repo (no se encontró www/laesh-swbldi)"
    exit 1
fi

# ── Opciones rsync comunes ────────────────────────────────────────────────────
RSYNC_OPTS=(-avz --checksum --delete
    --exclude='.git/'
    --exclude='.env'
    --exclude='*.log'
    --exclude='node_modules/'
    --exclude='vendor/'
    --exclude='.DS_Store'
)

# ── Funciones ─────────────────────────────────────────────────────────────────
_header() { echo ""; echo "══ $1 ══"; }
_ok()     { echo "  ✓ $1"; }
_err()    { echo "  ✗ ERROR: $1" >&2; exit 1; }

deploy_webapp() {
    _header "WEBAPP PHP → ${KVM2_SSH}:${KVM2_WEBAPP}/"
    rsync "${RSYNC_OPTS[@]}" \
        --exclude='crons/*.log' \
        "${REPO_ROOT}/www/laesh-swbldi/" \
        "${KVM2_SSH}:${KVM2_WEBAPP}/"
    _ok "webapp desplegada"

    echo "  → Recargando PHP-FPM..."
    ssh "${KVM2_SSH}" "sudo systemctl reload ${KVM2_PHP_FPM_SERVICE}"
    _ok "${KVM2_PHP_FPM_SERVICE} recargado"
}

deploy_assets() {
    # Paso 1/2 — local → staging (revisar antes de publicar a producción)
    _header "ASSETS paso 1/2 — local → staging: ${KVM2_SSH}:${KVM2_ASSETS_STAGING}/"
    rsync "${RSYNC_OPTS[@]}" \
        --exclude='cms/' \
        "${REPO_ROOT}/www/laesh-web-assets-uipv1a/" \
        "${KVM2_SSH}:${KVM2_ASSETS_STAGING}/"
    _ok "assets en staging — revisar con: ssh ${KVM2_SSH} 'ls ${KVM2_ASSETS_STAGING}/'"
    echo "  → Para publicar a producción: bash deploy.sh assets-publish"
}

deploy_assets_publish() {
    # Paso 2/2 — staging → producción (ejecutar después de revisar staging)
    _header "ASSETS paso 2/2 — staging → producción: ${KVM2_SSH}:${KVM2_ASSETS}/"
    ssh "${KVM2_SSH}" "rsync -avz --checksum --delete \
        --exclude='cms/' \
        '${KVM2_ASSETS_STAGING}/' \
        '${KVM2_ASSETS}/'"
    _ok "assets publicados a producción (cms/ excluido — imágenes CMS intactas)"
}

deploy_scripts() {
    _header "SCRIPTS/SETUP → ${KVM2_SSH}:${KVM2_SETUP_DIR}/"
    rsync "${RSYNC_OPTS[@]}" \
        --exclude='bds/voz_cocina_dual/' \
        --exclude='deploy/pwa/' \
        --exclude='deploy/webapps/' \
        "${REPO_ROOT}/setup/" \
        "${KVM2_SSH}:${KVM2_SETUP_DIR}/"
    _ok "scripts/setup desplegados (excluidos: bds/voz_cocina_dual, deploy/pwa, deploy/webapps)"
}

# ── Main ──────────────────────────────────────────────────────────────────────
if [[ $# -eq 0 ]]; then
    echo "Uso: bash deploy.sh [webapp|assets|assets-publish|scripts|all]"
    echo ""
    echo "Flujos:"
    echo "  webapp          → rsync PHP   local → ${KVM2_SSH}:${KVM2_WEBAPP}/ + reload php-fpm"
    echo "  assets          → rsync CSS/JS local → staging ${KVM2_SSH}:${KVM2_ASSETS_STAGING}/ (paso 1/2)"
    echo "  assets-publish  → rsync staging → producción ${KVM2_SSH}:${KVM2_ASSETS}/ (paso 2/2)"
    echo "  scripts         → rsync setup/ local → ${KVM2_SSH}:${KVM2_SETUP_DIR}/"
    echo "  all             → webapp + assets (paso 1) + scripts  [assets-publish requiere paso explícito]"
    exit 0
fi

for ARG in "$@"; do
    case "${ARG}" in
        webapp)          deploy_webapp          ;;
        assets)          deploy_assets          ;;
        assets-publish)  deploy_assets_publish  ;;
        scripts)         deploy_scripts         ;;
        all)
            deploy_webapp
            deploy_assets    # solo staging — correr assets-publish por separado tras revisar
            deploy_scripts
            ;;
        *)
            echo "Argumento desconocido: ${ARG}"
            echo "Uso: bash deploy.sh [webapp|assets|assets-publish|scripts|all]"
            exit 1
            ;;
    esac
done

echo ""
echo "══ Deploy completado $(date '+%Y-%m-%d %H:%M:%S') ══"
