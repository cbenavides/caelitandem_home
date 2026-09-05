#!/usr/bin/env bash
# ==============================================================================
# LAESH KVM2 · Paso 2 — Instalar Stack Base
# Nginx (Ubuntu 24.04 default) + MariaDB 11.8 + PHP 8.3 + Composer
# Mueve datadir MariaDB a /opt/laesh/laesh-db/ via symlink (AppArmor safe).
# Idempotente.
# ==============================================================================
set -euo pipefail
[ "$EUID" -ne 0 ] && { echo "[ERROR] Requiere sudo"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  △${NC} $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
log()  { echo "  → $*"; }

export DEBIAN_FRONTEND=noninteractive

# ── 1. Repositorio MariaDB 11.8 ───────────────────────────────────────────────
echo "── 1/6 Repositorio MariaDB 11.8 ──────────────────────────────"
if apt-cache show mariadb-server 2>/dev/null | grep -q "^Version: 1:11\.8"; then
    warn "MariaDB 11.8 ya en apt cache. Omitiendo repo setup."
else
    log "Agregando repo oficial MariaDB 11.8..."
    curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup \
        | bash -s -- --mariadb-server-version="mariadb-11.8" --skip-verify 2>&1 | tail -3
    ok "Repo MariaDB 11.8 agregado"
fi

# ── 2. Repositorio PHP 8.3 (Ondrej) ──────────────────────────────────────────
echo ""
echo "── 2/6 Repositorio PHP 8.3 (Ondrej) ─────────────────────────"
if dpkg -l | grep -q php8\.3-fpm; then
    warn "php8.3-fpm ya instalado"
else
    apt-get install -yq software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    apt-get update -yq
    ok "PPA Ondrej PHP agregado"
fi

# ── 3. Instalar paquetes ──────────────────────────────────────────────────────
echo ""
echo "── 3/6 Instalar Nginx, MariaDB 11.8, PHP 8.3, build tools ───"
PKGS=(
    nginx
    mariadb-server
    php8.3-fpm
    php8.3-mysql
    php8.3-curl
    php8.3-mbstring
    php8.3-xml
    php8.3-zip
    php8.3-intl
    php8.3-gd
    php8.3-opcache
    php8.3-fileinfo
    php8.3-dev
    gcc
    make
    autoconf
    libc-dev
    pkg-config
    libssl-dev
    libpcre2-dev
    libbrotli-dev    # requerido por Swoole 6.2.2 (--enable-brotli=yes)
    unzip
    certbot
    python3-certbot-nginx
    jq
    swaks            # cliente SMTP para alertas por correo (monitor_services.sh)
    inotify-tools    # inotifywait/inotifywatch — utils de diagnóstico inotify (systemd path unit usa kernel inotify nativo, no este paquete)
    curl             # usado en monitor_services.sh y cache_renew warm-up
)
MISSING=()
for pkg in "${PKGS[@]}"; do
    dpkg -l | grep -q "^ii  ${pkg}" || MISSING+=("$pkg")
done
if [ ${#MISSING[@]} -eq 0 ]; then
    warn "Todos los paquetes ya instalados"
else
    log "Instalando: ${MISSING[*]}"
    apt-get install -yq "${MISSING[@]}"
    ok "Paquetes instalados"
fi

# ── 4. Verificar versiones ────────────────────────────────────────────────────
echo ""
echo "── 4/6 Verificar versiones ───────────────────────────────────"
MARIADB_VER=$(mariadbd --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "?")
# -n: omitir ini/extensiones — evita hang si Swoole+JIT CLI ya está configurado (re-run post paso 7)
PHP_VER=$(php8.3 -n -r 'echo PHP_VERSION;' 2>/dev/null || echo "?")
NGINX_VER=$(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+' || echo "?")
echo "  MariaDB: ${MARIADB_VER}"
echo "  PHP:     ${PHP_VER}"
echo "  Nginx:   ${NGINX_VER}"
[[ "$MARIADB_VER" == 11.8.* ]] && ok "MariaDB 11.8 ✓" || err "MariaDB version inesperada: $MARIADB_VER"
[[ "$PHP_VER" == 8.3.* ]]      && ok "PHP 8.3 ✓"     || err "PHP version inesperada: $PHP_VER"

# ── 5. Mover datadir MariaDB → /opt/laesh/laesh-db/ (symlink) ────────────────
echo ""
echo "── 5/6 DataDir MariaDB → /opt/laesh/laesh-db/ ────────────────"

if [ -L /var/lib/mysql ] && [ "$(readlink /var/lib/mysql)" = "/opt/laesh/laesh-db" ]; then
    warn "/var/lib/mysql ya es symlink a /opt/laesh/laesh-db. Omitiendo."
else
    log "Deteniendo MariaDB para mover datadir..."
    systemctl stop mariadb

    # Asegurar que el destino existe y tiene permisos correctos
    mkdir -p /opt/laesh/laesh-db
    chown mysql:mysql /opt/laesh/laesh-db
    chmod 0750 /opt/laesh/laesh-db

    if [ -d /var/lib/mysql ] && [ ! -L /var/lib/mysql ]; then
        log "Copiando datadir actual a /opt/laesh/laesh-db/ ..."
        rsync -a /var/lib/mysql/ /opt/laesh/laesh-db/
        chown -R mysql:mysql /opt/laesh/laesh-db
        rm -rf /var/lib/mysql
        ok "Datos copiados"
    fi

    # Crear symlink
    ln -sfn /opt/laesh/laesh-db /var/lib/mysql
    # El symlink debe ser seguible por mysql user
    chown -h root:root /var/lib/mysql
    ok "Symlink /var/lib/mysql → /opt/laesh/laesh-db creado"

    log "Iniciando MariaDB..."
    systemctl start mariadb
    sleep 2
    systemctl is-active --quiet mariadb && ok "MariaDB activo en /opt/laesh/laesh-db" || { err "MariaDB no arrancó"; exit 1; }
fi

# ── 6. Composer ───────────────────────────────────────────────────────────────
echo ""
echo "── 6/6 Composer ──────────────────────────────────────────────"
if command -v composer &>/dev/null; then
    # -n: evita hang si Swoole+JIT CLI activo (re-run post paso 7)
    warn "Composer ya instalado: $(php8.3 -n /usr/local/bin/composer --version --no-ansi 2>/dev/null | head -1)"
else
    log "Instalando Composer (descarga via curl)..."
    # Usar curl (más fiable que php -r copy() que puede colgar esperando timeout PHP)
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
    EXPECTED_SIG="$(curl -sf https://composer.github.io/installer.sig)"
    ACTUAL_SIG="$(php8.3 -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"
    if [ "$EXPECTED_SIG" != "$ACTUAL_SIG" ]; then
        err "Firma Composer inválida — posible descarga corrupta"
        rm /tmp/composer-setup.php; exit 1
    fi
    php8.3 /tmp/composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
    rm /tmp/composer-setup.php
    ok "Composer instalado: $(composer --version --no-ansi 2>/dev/null | head -1)"
fi

echo ""
ok "Stack base instalado"
