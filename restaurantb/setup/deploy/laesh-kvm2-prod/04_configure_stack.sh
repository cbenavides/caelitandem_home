#!/usr/bin/env bash
# ==============================================================================
# LAESH KVM2 · Paso 4 — Configurar Stack (MariaDB, PHP-FPM, Nginx, Swoole)
# Lee configs de /opt/laesh/configs/ → copia a rutas del sistema.
# Instala swoole-laesh.service (systemd) y logrotate.
# Activa Modo A (IP/self-signed) — 05_tls_certbot.sh cambia a Modo B si aplica.
# Idempotente: sobrescribe siempre (estado deseado).
# ==============================================================================
set -euo pipefail
[ "$EUID" -ne 0 ] && { echo "[ERROR] Requiere sudo"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  △${NC} $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; exit 1; }
log()  { echo "  → $*"; }

CFG="/opt/laesh/configs"
CRONES="/opt/laesh/crones"

[ -d "$CFG" ] || err "No existe ${CFG} — ejecutar paso 1 primero"

# ── 1. MariaDB ─────────────────────────────────────────────────────────────────
echo "── 1/7 MariaDB config ────────────────────────────────────────"
cp "${CFG}/mariadb-99-laesh.cnf" /etc/mysql/mariadb.conf.d/99-laesh.cnf
ok "Aplicado: /etc/mysql/mariadb.conf.d/99-laesh.cnf"
systemctl restart mariadb
sleep 2
systemctl is-active --quiet mariadb && ok "MariaDB activo" || err "MariaDB no arrancó tras config"

# ── 2. PHP 8.3 ini ────────────────────────────────────────────────────────────
echo ""
echo "── 2/7 PHP 8.3 ini ───────────────────────────────────────────"
cp "${CFG}/php-99-laesh.ini" /etc/php/8.3/fpm/conf.d/99-laesh.ini
cp "${CFG}/php-99-laesh.ini" /etc/php/8.3/cli/conf.d/99-laesh.ini
ok "Aplicado: /etc/php/8.3/fpm/conf.d/99-laesh.ini"

# ── 3. PHP-FPM pool ──────────────────────────────────────────────────────────
echo ""
echo "── 3/7 PHP-FPM pool laesh ────────────────────────────────────"
# Inyectar LAESH_APP_PASS si está definida
if [[ -n "${LAESH_APP_PASS:-}" ]]; then
    sed "s|__LAESH_APP_PASS__|${LAESH_APP_PASS}|g" \
        "${CFG}/php-fpm-laesh.conf" > /etc/php/8.3/fpm/pool.d/laesh.conf
else
    cp "${CFG}/php-fpm-laesh.conf" /etc/php/8.3/fpm/pool.d/laesh.conf
    warn "LAESH_APP_PASS no definida — env[LAESH_DB_PASS] queda como placeholder en el pool"
fi
# Deshabilitar pool www default
[ -f /etc/php/8.3/fpm/pool.d/www.conf ] && mv /etc/php/8.3/fpm/pool.d/www.conf /etc/php/8.3/fpm/pool.d/www.conf.disabled
ok "Pool laesh configurado; pool www deshabilitado"

# Test sintaxis FPM
php-fpm8.3 -t && ok "PHP-FPM sintaxis OK" || err "Error de sintaxis en PHP-FPM config"

# ── 4. Nginx base ─────────────────────────────────────────────────────────────
echo ""
echo "── 4/7 Nginx base config ─────────────────────────────────────"
cp "${CFG}/nginx-base.conf" /etc/nginx/nginx.conf
ok "Aplicado: /etc/nginx/nginx.conf"

# Activar Modo A (IP/self-signed) — 05_tls_certbot.sh cambia esto si procede
cp "${CFG}/nginx-laesh-ip.conf" /etc/nginx/sites-available/laesh
ln -sf /etc/nginx/sites-available/laesh /etc/nginx/sites-enabled/laesh
# Deshabilitar default site
rm -f /etc/nginx/sites-enabled/default
ok "Site laesh activado (Modo A IP)"

# Test sintaxis Nginx
nginx -t && ok "Nginx sintaxis OK" || err "Error de sintaxis en Nginx config"

# ── 5. systemd Swoole ─────────────────────────────────────────────────────────
echo ""
echo "── 5/7 systemd swoole-laesh.service ─────────────────────────"
cp "${CRONES}/swoole-laesh.service" /etc/systemd/system/swoole-laesh.service
systemctl daemon-reload
systemctl enable swoole-laesh
ok "swoole-laesh.service instalado y habilitado"

# ── 6. Logrotate ──────────────────────────────────────────────────────────────
echo ""
echo "── 6/7 Logrotate ─────────────────────────────────────────────"
cp "${CRONES}/logrotate-laesh.conf" /etc/logrotate.d/laesh
chmod 644 /etc/logrotate.d/laesh
ok "Logrotate configurado → /etc/logrotate.d/laesh"

# Crear .mariadb-root.cnf para el postrotate de logrotate (FLUSH SLOW LOGS)
# El postrotate de MariaDB necesita conectarse sin contraseña interactiva.
# Este archivo solo lo lee root (0600); contiene la contraseña root de MariaDB.
if [[ -n "${LAESH_ROOT_PASS:-}" ]]; then
    mkdir -p /opt/laesh/configs
    cat > /opt/laesh/configs/.mariadb-root.cnf << ROOTCNF
[client]
user=root
password=${LAESH_ROOT_PASS}
host=127.0.0.1
ROOTCNF
    chmod 600 /opt/laesh/configs/.mariadb-root.cnf
    chown root:root /opt/laesh/configs/.mariadb-root.cnf
    ok ".mariadb-root.cnf creado (600 root:root) — logrotate FLUSH LOGS habilitado"
else
    warn "LAESH_ROOT_PASS no definida — .mariadb-root.cnf NO creado."
    warn "  Logrotate postrotate de MariaDB hará FLUSH LOGS sin autenticación."
    warn "  Crear manualmente: /opt/laesh/configs/.mariadb-root.cnf (ver README)"
fi

# ── 7. Reiniciar servicios ────────────────────────────────────────────────────
echo ""
echo "── 7/7 Reiniciar servicios ───────────────────────────────────"
systemctl restart php8.3-fpm && ok "php8.3-fpm reiniciado"
systemctl restart nginx      && ok "nginx reiniciado"

# Arrancar Swoole si el código ya está (puede no estar aún en paso 4)
if [ -f /opt/laesh/www/laesh-swbldi/commons/swoole_server.php ]; then
    systemctl restart swoole-laesh && ok "swoole-laesh iniciado"
else
    warn "Código webapp aún no desplegado — swoole-laesh se arrancará en paso 6"
fi

echo ""
ok "Stack configurado"
