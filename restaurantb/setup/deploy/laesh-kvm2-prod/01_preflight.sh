#!/usr/bin/env bash
# ==============================================================================
# LAESH KVM2 · Paso 1 — Preflight
# Swap 4 GB, árbol /opt/laesh/, ulimit, sysctl.
# Idempotente: detecta estado existente antes de actuar.
# ==============================================================================
set -euo pipefail
[ "$EUID" -ne 0 ] && { echo "[ERROR] Requiere sudo"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  △${NC} $*"; }
log()  { echo "  → $*"; }

echo "── 1/5 Swap 4 GB ─────────────────────────────────────────────"
if swapon --show | grep -q "/swapfile"; then
    SWAP_SIZE=$(swapon --show --bytes | awk '/swapfile/{print $3}')
    warn "Swap ya activo ($(numfmt --to=iec $SWAP_SIZE)). Omitiendo creación."
else
    log "Creando /swapfile 4 GB..."
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi
    ok "Swap 4 GB activo"
fi

echo ""
echo "── 2/5 Parámetros del kernel ─────────────────────────────────"
cat > /etc/sysctl.d/99-laesh.conf << 'EOF'
# LAESH Prod — Hostinger KVM2
vm.swappiness = 10
net.core.somaxconn = 65535
net.ipv4.tcp_fin_timeout = 30
fs.file-max = 200000
EOF
sysctl -p /etc/sysctl.d/99-laesh.conf > /dev/null
ok "sysctl aplicado (swappiness=10, somaxconn=65535)"

echo ""
echo "── 3/5 ulimit (open files) ───────────────────────────────────"
if ! grep -q 'laesh-limits' /etc/security/limits.conf; then
    cat >> /etc/security/limits.conf << 'EOF'
# laesh-limits
*    soft nofile 65535
*    hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF
fi
# systemd override
mkdir -p /etc/systemd/system.conf.d/
cat > /etc/systemd/system.conf.d/99-laesh-limits.conf << 'EOF'
[Manager]
DefaultLimitNOFILE=65535
EOF
ok "ulimit configurado (65535)"

echo ""
echo "── 4/5 Árbol /opt/laesh/ ─────────────────────────────────────"
DIRS=(
    /opt/laesh/www
    /opt/laesh/assets
    /opt/laesh/uploads/pdfs
    /opt/laesh/uploads/cms
    /opt/laesh/laesh-db
    /opt/laesh/https
    /opt/laesh/scripts
    /opt/laesh/configs
    /opt/laesh/crones
    /opt/laesh/logs
    /opt/laesh/backups
    /opt/laesh/cache           # Cache L2 OPcache File Store (PrivateTmp-safe, fuera de /tmp)
    /opt/laesh/monitor         # Estado cooldown monitor_services.sh (<svc>.last_alert)
    /var/log/php8.3-fpm        # para compatibilidad con systemd
)
for d in "${DIRS[@]}"; do
    if [ -d "$d" ]; then
        warn "$d ya existe"
    else
        mkdir -p "$d"
        ok "$d creado"
    fi
done

# laesh-db: MariaDB la usará — prefijar permisos correctos
# (el chown a mysql:mysql se hace en 02 después de instalar mariadb)
chmod 0750 /opt/laesh/laesh-db

# uploads necesita escritura de www-data
chmod 0750 /opt/laesh/uploads/pdfs
chmod 0777 /opt/laesh/uploads/cms

echo ""
echo "── 5/5 Copiar configs fuente a /opt/laesh/configs/ ──────────"
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "${SETUP_DIR}/configs" ]; then
    cp -v "${SETUP_DIR}"/configs/*.cnf  /opt/laesh/configs/ 2>/dev/null || true
    cp -v "${SETUP_DIR}"/configs/*.ini  /opt/laesh/configs/ 2>/dev/null || true
    cp -v "${SETUP_DIR}"/configs/*.conf /opt/laesh/configs/ 2>/dev/null || true
    ok "Configs copiados a /opt/laesh/configs/"
else
    warn "No se encontró ${SETUP_DIR}/configs/ — ejecutar desde el directorio del pipeline"
fi

# Copiar logs/log-levels.conf (config inicial de niveles — no sobreescribir si ya existe)
LOG_LEVELS_DST="/opt/laesh/logs/log-levels.conf"
LOG_LEVELS_SRC="${SETUP_DIR}/logs/log-levels.conf"
if [ ! -f "$LOG_LEVELS_DST" ] && [ -f "$LOG_LEVELS_SRC" ]; then
    cp "$LOG_LEVELS_SRC" "$LOG_LEVELS_DST"
    ok "log-levels.conf inicial copiado a /opt/laesh/logs/"
elif [ -f "$LOG_LEVELS_DST" ]; then
    warn "log-levels.conf ya existe en destino — no sobreescrito (edición preservada)"
else
    warn "logs/log-levels.conf no encontrado en pipeline — se creará con defaults en paso 7"
fi

# Copiar crones, https, scripts
# rsync en lugar de cp -r para que sea idempotente: solo copia archivos nuevos
# o modificados sin borrar los que ya existen en el destino (no --delete).
for subdir in crones https scripts; do
    if [ -d "${SETUP_DIR}/${subdir}" ]; then
        rsync -a "${SETUP_DIR}/${subdir}/." "/opt/laesh/${subdir}/"
        ok "${subdir}/ sincronizado a /opt/laesh/${subdir}/"
    fi
done
chmod +x /opt/laesh/scripts/*.sh  2>/dev/null || true
chmod +x /opt/laesh/https/*.sh    2>/dev/null || true
chmod +x /opt/laesh/crones/*.sh   2>/dev/null || true

echo ""
ok "Preflight completo"
