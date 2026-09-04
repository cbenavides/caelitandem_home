#!/usr/bin/env bash
# ==============================================================================
# LAESH KVM2 · Paso 7 — Security Hardening
# UFW, OPcache, backup cron, logrotate, SSH (opcional con flag).
# Idempotente.
#
# Uso:
#   sudo bash 07_security_harden.sh             # con SSH hardening
#   sudo bash 07_security_harden.sh --skip-ssh  # sin SSH (primera vez sin llave pública)
# ==============================================================================
set -euo pipefail
[ "$EUID" -ne 0 ] && { echo "[ERROR] Requiere sudo"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  △${NC} $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; exit 1; }
log()  { echo "  → $*"; }

SKIP_SSH=false; [[ "${1:-}" == "--skip-ssh" ]] && SKIP_SSH=true
LAESH_ROOT_PASS="${LAESH_ROOT_PASS:-}"
LAESH_APP_PASS="${LAESH_APP_PASS:-}"
[[ -z "$LAESH_APP_PASS" ]] && warn "LAESH_APP_PASS no definida — cron cache_renew no tendrá contraseña BD (warm-up de BD fallará)"

# ── 1. UFW ────────────────────────────────────────────────────────────────────
echo "── 1/5 UFW Firewall ──────────────────────────────────────────"
apt-get install -yq ufw 2>/dev/null | grep -v '^$' || true
ufw --force reset > /dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp   comment 'HTTP'
ufw allow 443/tcp  comment 'HTTPS'
ufw deny 3306/tcp  comment 'MariaDB (no exponer)'
ufw deny 9502/tcp  comment 'Swoole bridge (solo loopback)'
ufw --force enable
ufw status numbered
ok "UFW activo — 22, 80, 443 permitidos; 3306, 9502 bloqueados"

# ── 2. OPcache + Cache L2 ─────────────────────────────────────────────────────
echo ""
echo "── 2/6 OPcache PHP 8.3 + Cache L2 ───────────────────────────"

# Copiar ini completo desde /opt/laesh/configs/ (instalado por 01_preflight.sh)
SRC_OPCACHE="/opt/laesh/configs/10-opcache-laesh.ini"
DST_FPM="/etc/php/8.3/fpm/conf.d/10-opcache-laesh.ini"
DST_CLI="/etc/php/8.3/cli/conf.d/10-opcache-laesh.ini"

if [ -f "$SRC_OPCACHE" ]; then
    cp "$SRC_OPCACHE" "$DST_FPM"
    cp "$SRC_OPCACHE" "$DST_CLI"   # requerido para cache_renew.php (CLI)
    ok "OPcache ini copiado a FPM y CLI"
else
    warn "10-opcache-laesh.ini no encontrado en /opt/laesh/configs/ — usando inline"
    cat > "$DST_FPM" << 'OPCACHE'
; OPcache — LAESH KVM2 producción (fallback inline)
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=4000
opcache.validate_timestamps=0
opcache.jit=tracing
opcache.jit_buffer_size=64M
OPCACHE
    cp "$DST_FPM" "$DST_CLI"
fi

systemctl reload php8.3-fpm
ok "OPcache configurado — bytecode RAM + JIT tracing + CLI para crons"

# Cache renew cron (Cache L2 warm-up diario 5 AM — §15.9.6 Tecnica_Infraestructura)
CACHE_CRON_SRC="/opt/laesh/crones/cache_renew.cron"
CACHE_CRON_DST="/etc/cron.d/laesh-cache-renew"
if [ -f "$CACHE_CRON_SRC" ]; then
    # Copiar y sustituir __LAESH_APP_PASS__ (igual que en php-fpm-laesh.conf)
    # El cron necesita LAESH_DB_PASS para que config.php conecte a MariaDB en CLI.
    sed "s/__LAESH_APP_PASS__/${LAESH_APP_PASS}/g" "$CACHE_CRON_SRC" > "$CACHE_CRON_DST"
    chmod 640 "$CACHE_CRON_DST"   # 640: root lee, www-data no necesita leer el archivo
    ok "Cron cache_renew instalado (@reboot + 5 AM diario, www-data)"
else
    # Fallback inline (sin LAESH_DB_PASS — warm-up fallará en BD pero no rompe FPM)
    cat > "$CACHE_CRON_DST" << 'CRON'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LAESH_CACHE_DIR=/opt/laesh/cache
LAESH_DB_HOST=127.0.0.1
LAESH_DB_PORT=3306
LAESH_DB_USER=laesh_app
LAESH_DB_NAME=laesh_db
APP_ENV=production
0 5 * * * www-data /usr/bin/php8.3 /opt/laesh/www/laesh-swbldi/crons/cache_renew.php >> /opt/laesh/logs/cache-renew.log 2>&1
@reboot www-data sleep 30 && /usr/bin/php8.3 /opt/laesh/www/laesh-swbldi/crons/cache_renew.php >> /opt/laesh/logs/cache-renew-boot.log 2>&1
CRON
    chmod 640 "$CACHE_CRON_DST"
    warn "cache_renew.cron fuente no encontrado — instalado fallback (sin LAESH_DB_PASS)"
fi

# ── 3. Backup cron (mysqldump horario) ────────────────────────────────────────
echo ""
echo "── 3/6 Backup BD cron ────────────────────────────────────────"
BACKUP_SCRIPT="/opt/laesh/scripts/backup_db.sh"
if [ -f "$BACKUP_SCRIPT" ]; then
    chmod +x "$BACKUP_SCRIPT"
    CRON_LINE="0 * * * * root bash ${BACKUP_SCRIPT} >> /opt/laesh/logs/backup.log 2>&1"
    if ! grep -qF "$BACKUP_SCRIPT" /etc/cron.d/laesh-backup 2>/dev/null; then
        echo "$CRON_LINE" > /etc/cron.d/laesh-backup
        chmod 644 /etc/cron.d/laesh-backup
        ok "Cron backup horario instalado"
    else
        warn "Cron backup ya existía"
    fi
else
    warn "backup_db.sh no encontrado en /opt/laesh/scripts/ — instalar scripts primero"
fi

# ── 4. Check expiry cert cron (semanal) ───────────────────────────────────────
echo ""
echo "── 4/6 Cron check cert expiry ───────────────────────────────"
CHECK_SCRIPT="/opt/laesh/crones/check_cert_expiry.sh"
if [ -f "$CHECK_SCRIPT" ]; then
    chmod +x "$CHECK_SCRIPT"
    CRON_CERT="0 8 * * 1 root bash ${CHECK_SCRIPT} >> /opt/laesh/logs/cert-check.log 2>&1"
    if ! grep -qF "$CHECK_SCRIPT" /etc/cron.d/laesh-cert-check 2>/dev/null; then
        echo "$CRON_CERT" > /etc/cron.d/laesh-cert-check
        chmod 644 /etc/cron.d/laesh-cert-check
        ok "Cron check cert semanal (lunes 08:00)"
    else
        warn "Cron cert check ya existía"
    fi
else
    warn "check_cert_expiry.sh no encontrado en /opt/laesh/crones/"
fi

# ── 5. SSH hardening (opcional) ───────────────────────────────────────────────
echo ""
echo "── 5/6 MariaDB — Verificar Least Privilege laesh_app ────────"
# El usuario laesh_app debe tener solo DML (SELECT, INSERT, UPDATE, DELETE).
# setup_hostinger.sh ya lo crea así. Este paso solo verifica y alerta si hay GRANT extra.
if command -v mariadb &>/dev/null; then
    GRANTS=$(mariadb -u root -e "SHOW GRANTS FOR 'laesh_app'@'localhost';" 2>/dev/null || echo "")
    if echo "$GRANTS" | grep -Eqi 'ALL PRIVILEGES|DROP|ALTER|CREATE|INDEX|LOCK'; then
        warn "⚠ laesh_app tiene permisos EXCESIVOS. Revisar SHOW GRANTS FOR 'laesh_app'@'localhost';"
        warn "  Solo debe tener: SELECT, INSERT, UPDATE, DELETE ON laesh_db.*"
    else
        ok "laesh_app — Least Privilege verificado (solo DML)"
    fi
else
    warn "MariaDB no disponible — verificar manualmente: SHOW GRANTS FOR 'laesh_app'@'localhost';"
fi

echo ""
echo "── 6/6 SSH Hardening ─────────────────────────────────────────"
if $SKIP_SSH; then
    warn "SSH hardening omitido (--skip-ssh). Ejecutar sin el flag cuando haya llave pública en authorized_keys."
else
    # Verificar que existe llave pública antes de deshabilitar password
    AUTH_KEYS_COUNT=$(grep -c 'ssh-' /root/.ssh/authorized_keys 2>/dev/null || \
                      grep -c 'ssh-' /home/sysadmin/.ssh/authorized_keys 2>/dev/null || echo 0)
    if [ "$AUTH_KEYS_COUNT" -eq 0 ]; then
        warn "⚠ No se encontró llave pública en authorized_keys."
        warn "  SSH hardening OMITIDO para evitar bloqueo de acceso."
        warn "  Agrega tu llave pública y re-ejecuta: sudo bash 07_security_harden.sh"
    else
        SSHD="/etc/ssh/sshd_config"
        cp "$SSHD" "${SSHD}.bak-$(date +%F)"
        sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/'          "$SSHD"
        sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' "$SSHD"
        sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/'   "$SSHD"
        sed -i 's/^#\?MaxAuthTries .*/MaxAuthTries 3/'                  "$SSHD"
        sshd -t && systemctl reload sshd
        ok "SSH: root login off, password off, pubkey only, MaxAuthTries=3"
    fi
fi

echo ""
ok "Security hardening completo"
