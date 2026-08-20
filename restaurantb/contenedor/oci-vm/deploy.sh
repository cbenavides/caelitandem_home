#!/usr/bin/env bash
# ============================================================
#  deploy.sh — Despliegue stack LAESH DB en OCI VM
#  Ejecutar desde la máquina local (no en OCI).
#
#  Requiere:
#    - SSH configurado: alias oci-vm en ~/.ssh/config
#    - .env creado en oci-vm/ con passwords reales
#    - rsync instalado localmente
#
#  Uso:
#    chmod +x deploy.sh
#    ./deploy.sh             # rsync + up (deploy completo)
#    ./deploy.sh --logs      # solo ver logs del contenedor DB
#    ./deploy.sh --status    # solo ver estado de contenedores
#    ./deploy.sh --down      # detener stack (NO borra volúmenes)
# ============================================================

set -euo pipefail

# ── Configuración ────────────────────────────────────────────
OCI_HOST="ubuntu@oci-vm"
OCI_DIR="/home/ubuntu/laesh-stack"          # directorio destino en OCI
LOCAL_CONTENEDOR="$(cd "$(dirname "$0")/.." && pwd)"   # contenedor/
LOCAL_SETUP_BD="$(cd "$(dirname "$0")/../../setup/bds/laesh" && pwd)"

# ── Parsear argumento ────────────────────────────────────────
ACTION="${1:-deploy}"

case "$ACTION" in
  --logs)
    echo "→ Logs laesh_db en OCI..."
    ssh "$OCI_HOST" "cd $OCI_DIR && docker compose logs -f laesh_db"
    exit 0
    ;;
  --status)
    echo "→ Estado stack LAESH en OCI..."
    ssh "$OCI_HOST" "cd $OCI_DIR && docker compose ps"
    exit 0
    ;;
  --down)
    echo "→ Deteniendo stack (los volúmenes de datos se conservan)..."
    ssh "$OCI_HOST" "cd $OCI_DIR && docker compose down"
    exit 0
    ;;
esac

# ── 1. Validar que .env existe localmente ───────────────────
if [[ ! -f "$(dirname "$0")/.env" ]]; then
    echo "ERROR: oci-vm/.env no encontrado."
    echo "Crear a partir de .env.example:"
    echo "  cp oci-vm/.env.example oci-vm/.env && nano oci-vm/.env"
    exit 1
fi

echo "════════════════════════════════════════"
echo " Deploy LAESH Stack → OCI VM"
echo "════════════════════════════════════════"

# ── 2. Crear directorio en OCI ──────────────────────────────
echo "→ Preparando directorios OCI: $OCI_DIR"
ssh "$OCI_HOST" "mkdir -p $OCI_DIR /home/ubuntu/logs/mariadb-oci"

# ── 3. rsync archivos oci-vm/ ────────────────────────────────
# --delete borra en destino lo que no existe en origen, pero protege
# setup/ y conf/ que se sincronizan por separado en pasos siguientes.
echo "→ Sincronizando oci-vm/ → OCI:$OCI_DIR/"
rsync -avz --delete \
    --exclude='.env' \
    --filter='protect setup/' \
    --filter='protect conf/mariadb-restaurantb.cnf' \
    "$(dirname "$0")/" \
    "$OCI_HOST:$OCI_DIR/"

# .env se copia por separado (excluido del rsync general para control)
echo "→ Copiando .env (secrets)..."
rsync -avz "$(dirname "$0")/.env" "$OCI_HOST:$OCI_DIR/.env"

# ── 4. rsync conf/ base (mariadb-restaurantb.cnf) ───────────
echo "→ Sincronizando conf/ base..."
rsync -avz \
    "$LOCAL_CONTENEDOR/conf/mariadb-restaurantb.cnf" \
    "$OCI_HOST:$OCI_DIR/conf/mariadb-restaurantb.cnf"

# ── 5. rsync scripts SQL de inicialización ──────────────────
echo "→ Sincronizando scripts SQL laesh/..."
ssh "$OCI_HOST" "mkdir -p $OCI_DIR/setup/bds/laesh"
rsync -avz --delete \
    "$LOCAL_SETUP_BD/" \
    "$OCI_HOST:$OCI_DIR/setup/bds/laesh/"

# ── 6. docker compose up ─────────────────────────────────────
echo "→ Levantando stack LAESH en OCI..."
ssh "$OCI_HOST" "
    cd $OCI_DIR
    docker compose --env-file .env pull --quiet
    docker compose --env-file .env up -d
    echo ''
    echo '→ Estado:'
    docker compose ps
"

echo ""
echo "════════════════════════════════════════"
echo " ✅ Deploy completado"
echo ""
echo " Acceso phpMyAdmin (via SSH tunnel):"
echo "   ssh -L 6080:127.0.0.1:6080 $OCI_HOST"
echo "   → http://localhost:6080"
echo ""
echo " Acceso MariaDB directo (via SSH tunnel):"
echo "   ssh -L 6002:127.0.0.1:6002 $OCI_HOST"
echo "   → mysql -h 127.0.0.1 -P 6002 -u laesh_app -p laesh_db"
echo ""
echo " Logs en tiempo real:"
echo "   ./deploy.sh --logs"
echo "════════════════════════════════════════"
