#!/usr/bin/env bash
# ==============================================================================
# LAESH — sync_to_hkvm2.sh
# Sincroniza TODO el proyecto local → Hostinger KVM2 via rsync+SSH (4 targets)
#
#   1. Pipeline de instalación  setup/deploy/laesh-kvm2-prod/ → ~/laesh-kvm2-prod/
#   2. Código fuente PHP         www/laesh-swbldi/             → ~/laesh-src/laesh-swbldi/
#   3. Assets estáticos          www/laesh-web-assets-uipv1a/  → ~/laesh-src/laesh-web-assets-uipv1a/
#   4. Scripts de BD             setup/bds/laesh/              → ~/laesh-src/setup/bds/laesh/
#
# Modos:
#   ./sync_to_hkvm2.sh               # incremental — solo diferencias (checksum), sin --delete
#   ./sync_to_hkvm2.sh --full        # incremental + elimina en remoto lo que ya no existe local
#   ./sync_to_hkvm2.sh --dry-run     # simula los 4 rsyncs sin transferir nada
#   ./sync_to_hkvm2.sh --full --dry-run
#
# Pre-requisito: SSH key instalada en el servidor.
#   Para copiar tu key: ssh-copy-id -p 22 sysadmin@83.136.219.193
# ==============================================================================
set -euo pipefail

# ── Configuración ─────────────────────────────────────────────────────────────
REMOTE_USER="sysadmin"
REMOTE_HOST="83.136.219.193"
REMOTE_PORT="22"
REMOTE="ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=accept-new"

# Rutas locales relativas al script (ajuste automático sin importar dónde está el repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"   # restaurantb/

# 4 pares origen → destino
declare -A SYNCS=(
    ["1-pipeline"]="${SCRIPT_DIR}/laesh-kvm2-prod/|/home/sysadmin/laesh-kvm2-prod/"
    ["2-app"]="${REPO_ROOT}/www/laesh-swbldi/|/home/sysadmin/laesh-src/laesh-swbldi/"
    ["3-assets"]="${REPO_ROOT}/www/laesh-web-assets-uipv1a/|/home/sysadmin/laesh-src/laesh-web-assets-uipv1a/"
    ["4-bd"]="${SCRIPT_DIR}/../bds/laesh/|/home/sysadmin/laesh-src/setup/bds/laesh/"
)
# Orden de ejecución (bash no garantiza orden en arrays asociativos)
SYNC_ORDER=("1-pipeline" "2-app" "3-assets" "4-bd")

# Labels legibles para el log
declare -A SYNC_LABELS=(
    ["1-pipeline"]="Pipeline de instalación"
    ["2-app"]="Código fuente PHP"
    ["3-assets"]="Assets estáticos (CSS/JS/img)"
    ["4-bd"]="Scripts de BD (SQL + setup_hostinger)"
)

# ── Parse flags ───────────────────────────────────────────────────────────────
FULL=false
DRY_RUN=""
for arg in "$@"; do
    case "$arg" in
        --full)    FULL=true ;;
        --dry-run) DRY_RUN="--dry-run" ;;
        --help|-h)
            echo "Uso: $0 [--full] [--dry-run]"
            echo "  (sin flags)  Incremental — transfiere solo archivos nuevos o modificados"
            echo "  --full       Incremental + elimina en remoto archivos no presentes local"
            echo "  --dry-run    Simula los 4 rsyncs — no transfiere nada"
            exit 0 ;;
    esac
done

# ── Opciones rsync base ────────────────────────────────────────────────────────
RSYNC_BASE=(
    -az                             # archive + compress (sin verbose — se reporta por sección)
    --checksum                      # comparar por checksum, no solo timestamp/size
    --human-readable
    --stats
    -e "${REMOTE}"
    --exclude='.git/'
    --exclude='*.swp'
    --exclude='*.bak'
    --exclude='.DS_Store'
    --exclude='vendor/'             # composer vendor — se instala en el servidor
)

$FULL && RSYNC_BASE+=( --delete )
[[ -n "$DRY_RUN" ]] && RSYNC_BASE+=( --dry-run )

MODE="INCREMENTAL"
$FULL && MODE="FULL (con --delete)"
[[ -n "$DRY_RUN" ]] && MODE="${MODE} + DRY-RUN"

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  LAESH — Sync completo local → Hostinger KVM2"
echo "  Modo:    ${MODE}"
echo "  Destino: ${REMOTE_USER}@${REMOTE_HOST}"
echo "══════════════════════════════════════════════════════════════"
echo ""

# ── Crear directorios remotos ─────────────────────────────────────────────────
REMOTE_DIRS="/home/sysadmin/laesh-kvm2-prod /home/sysadmin/laesh-src/laesh-swbldi /home/sysadmin/laesh-src/laesh-web-assets-uipv1a /home/sysadmin/laesh-src/setup/bds/laesh"
ssh -p "$REMOTE_PORT" -o StrictHostKeyChecking=accept-new \
    "${REMOTE_USER}@${REMOTE_HOST}" \
    "mkdir -p ${REMOTE_DIRS}" 2>/dev/null || true

# ── Ejecutar los 4 rsyncs ─────────────────────────────────────────────────────
ERRORS=0
T0=$SECONDS

for KEY in "${SYNC_ORDER[@]}"; do
    IFS='|' read -r LOCAL_PATH REMOTE_PATH <<< "${SYNCS[$KEY]}"
    LABEL="${SYNC_LABELS[$KEY]}"

    # Validar que el origen existe
    if [[ ! -d "$LOCAL_PATH" ]]; then
        echo "  ✗ [${KEY}] Origen no encontrado: ${LOCAL_PATH} — OMITIDO"
        (( ERRORS++ )) || true
        continue
    fi

    echo "── ${KEY}: ${LABEL}"
    echo "   ${LOCAL_PATH}"
    echo "   → ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}"

    if rsync "${RSYNC_BASE[@]}" \
        "${LOCAL_PATH}" \
        "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}" 2>&1 \
        | grep -E 'Number of files|transferred|speedup|error|ERROR' ; then
        echo "   ✓ OK"
    else
        echo "   ✗ FALLÓ (código $?)"
        (( ERRORS++ )) || true
    fi
    echo ""
done

# ── Resumen ───────────────────────────────────────────────────────────────────
ELAPSED=$(( SECONDS - T0 ))
echo "══════════════════════════════════════════════════════════════"
if [[ $ERRORS -eq 0 ]]; then
    if [[ -n "$DRY_RUN" ]]; then
        echo "  ✅  DRY-RUN — ningún archivo fue transferido."
        echo "      Ejecuta sin --dry-run para aplicar."
    else
        echo "  ✅  Sync completado en ${ELAPSED}s — 4/4 targets OK"
        echo ""
        echo "  Próximo paso en el servidor:"
        echo "    ssh ${REMOTE_USER}@${REMOTE_HOST}"
        echo "    cd ~/laesh-kvm2-prod"
        echo "    sudo bash 00_run_all.sh          # pipeline completo"
        echo "    sudo bash 06_deploy_app.sh        # solo re-deploy app (sin reinstalar stack)"
    fi
else
    echo "  ✗  Sync finalizado con ${ERRORS} error(es) en ${ELAPSED}s — revisar salida arriba"
    exit 1
fi
echo "══════════════════════════════════════════════════════════════"
echo ""
