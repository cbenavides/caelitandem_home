#!/usr/bin/env bash
# ==============================================================================
# LAESH — sync_to_hkvm2.sh
# Sincroniza el pipeline de setup local → Hostinger KVM2 via rsync+SSH
#
# Modos:
#   ./sync_to_hkvm2.sh               # incremental (solo diferencias)
#   ./sync_to_hkvm2.sh --full        # full + elimina en remoto lo que no existe local
#   ./sync_to_hkvm2.sh --dry-run     # simula sin transferir nada
#   ./sync_to_hkvm2.sh --full --dry-run
#
# Pre-requisito: SSH key instalada en el servidor, o sshpass instalado.
#   Para copiar tu key: ssh-copy-id -p 22 sysadmin@83.136.219.193
# ==============================================================================
set -euo pipefail

# ── Configuración ─────────────────────────────────────────────────────────────
REMOTE_USER="sysadmin"
REMOTE_HOST="83.136.219.193"
REMOTE_PORT="22"
REMOTE_DIR="/home/sysadmin/laesh-kvm2-prod"

# Directorio local del pipeline (relativo al script → ajuste automático)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="${SCRIPT_DIR}/laesh-kvm2-prod"

# ── Parse flags ───────────────────────────────────────────────────────────────
FULL=false
DRY_RUN=""
for arg in "$@"; do
    case "$arg" in
        --full)    FULL=true ;;
        --dry-run) DRY_RUN="--dry-run" ;;
        --help|-h)
            echo "Uso: $0 [--full] [--dry-run]"
            echo "  --full     Sync completo (elimina en remoto archivos no presentes local)"
            echo "  --dry-run  Simula — no transfiere nada"
            exit 0 ;;
    esac
done

# ── Validación ────────────────────────────────────────────────────────────────
[[ -d "$LOCAL_DIR" ]] || {
    echo "ERROR: No existe el directorio local: $LOCAL_DIR"
    exit 1
}

# ── Opciones rsync ────────────────────────────────────────────────────────────
RSYNC_OPTS=(
    -avz                           # archive + verbose + compress
    --checksum                     # comparar por checksum, no solo timestamp/size
    --human-readable               # tamaños legibles
    --progress                     # barra de progreso por archivo
    --stats                        # resumen al final
    -e "ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=accept-new"
    --exclude='.git/'
    --exclude='*.swp'
    --exclude='*.bak'
    --exclude='.DS_Store'
)

if $FULL; then
    RSYNC_OPTS+=( --delete )       # elimina en remoto lo que no existe local
    MODE="FULL (con --delete)"
else
    MODE="INCREMENTAL"
fi

[[ -n "$DRY_RUN" ]] && RSYNC_OPTS+=( --dry-run ) && MODE="$MODE + DRY-RUN"

# ── Info ──────────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  LAESH — Sync Pipeline → Hostinger KVM2"
echo "  Modo:    $MODE"
echo "  Origen:  $LOCAL_DIR/"
echo "  Destino: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
echo "══════════════════════════════════════════════════════"
echo ""

# ── Crear directorio remoto si no existe ─────────────────────────────────────
ssh -p "$REMOTE_PORT" \
    -o StrictHostKeyChecking=accept-new \
    "${REMOTE_USER}@${REMOTE_HOST}" \
    "mkdir -p ${REMOTE_DIR}" \
    2>/dev/null || true

# ── Ejecutar rsync ───────────────────────────────────────────────────────────
rsync "${RSYNC_OPTS[@]}" \
    "${LOCAL_DIR}/" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

EXIT_CODE=$?

echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
    if [[ -n "$DRY_RUN" ]]; then
        echo "✅  DRY-RUN completado — ningún archivo fue transferido."
        echo "    Ejecuta sin --dry-run para aplicar."
    else
        echo "✅  Sync completado → ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"
        echo ""
        echo "Próximo paso en el servidor:"
        echo "  ssh ${REMOTE_USER}@${REMOTE_HOST}"
        echo "  cd ~/laesh-kvm2-prod"
        echo "  sudo bash 00_run_all.sh        # pipeline completo"
        echo "  sudo bash 01_preflight.sh      # o paso a paso"
    fi
else
    echo "✗  rsync terminó con código $EXIT_CODE"
    exit $EXIT_CODE
fi
