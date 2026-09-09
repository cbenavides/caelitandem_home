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
    _header "ASSETS → ${KVM2_SSH}:${KVM2_ASSETS}/"
    rsync "${RSYNC_OPTS[@]}" \
        --exclude='cms/' \
        "${REPO_ROOT}/www/laesh-web-assets-uipv1a/" \
        "${KVM2_SSH}:${KVM2_ASSETS}/"
    _ok "assets desplegados (cms/ excluido — manejado por el uploader)"
}

deploy_scripts() {
    _header "SCRIPTS/SETUP → ${KVM2_SSH}:${KVM2_LAESH_SRC}/setup/"
    rsync "${RSYNC_OPTS[@]}" \
        "${REPO_ROOT}/setup/" \
        "${KVM2_SSH}:${KVM2_LAESH_SRC}/setup/"
    _ok "scripts/setup desplegados"
}

# ── Main ──────────────────────────────────────────────────────────────────────
if [[ $# -eq 0 ]]; then
    echo "Uso: bash deploy.sh [webapp|assets|scripts|all]"
    echo ""
    echo "Rutas canónicas (ver SERVER_MAP.env):"
    echo "  webapp  → ${KVM2_SSH}:${KVM2_WEBAPP}/"
    echo "  assets  → ${KVM2_SSH}:${KVM2_ASSETS}/"
    echo "  scripts → ${KVM2_SSH}:${KVM2_LAESH_SRC}/setup/"
    exit 0
fi

for ARG in "$@"; do
    case "${ARG}" in
        webapp)  deploy_webapp  ;;
        assets)  deploy_assets  ;;
        scripts) deploy_scripts ;;
        all)
            deploy_webapp
            deploy_assets
            deploy_scripts
            ;;
        *)
            echo "Argumento desconocido: ${ARG}"
            echo "Uso: bash deploy.sh [webapp|assets|scripts|all]"
            exit 1
            ;;
    esac
done

echo ""
echo "══ Deploy completado $(date '+%Y-%m-%d %H:%M:%S') ══"
