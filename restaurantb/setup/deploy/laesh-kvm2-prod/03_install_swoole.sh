#!/usr/bin/env bash
# ==============================================================================
# LAESH KVM2 · Paso 3 — Instalar Swoole 6.2.2 (PECL)
# Idempotente: si Swoole 6.2.2 ya está instalado, no recompila.
# Tiempo estimado: 10–20 min (compilación C con 2 vCPU + swap).
# ==============================================================================
set -euo pipefail
[ "$EUID" -ne 0 ] && { echo "[ERROR] Requiere sudo"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
REQUIRED_VERSION="6.2.2"
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  △${NC} $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
log()  { echo "  → $*"; }

# ── Verificar si ya está instalada la versión correcta ────────────────────────
INSTALLED=$(php8.3 -r "echo defined('SWOOLE_VERSION') ? SWOOLE_VERSION : '';" 2>/dev/null || echo "")
if [ "$INSTALLED" = "$REQUIRED_VERSION" ]; then
    warn "Swoole ${REQUIRED_VERSION} ya instalado. Omitiendo compilación."
    php8.3 -m | grep -q swoole && ok "Extensión swoole activa en PHP 8.3" || err "swoole no aparece en php -m"
    exit 0
elif [ -n "$INSTALLED" ]; then
    warn "Swoole ${INSTALLED} instalado (se requiere ${REQUIRED_VERSION}). Recompilando..."
fi

# ── Instalar PECL si no existe ────────────────────────────────────────────────
if ! command -v pecl &>/dev/null; then
    log "Instalando php8.3-pear (pecl)..."
    apt-get install -yq php-pear
fi

# ── Compilar Swoole 6.2.2 ─────────────────────────────────────────────────────
echo "── Compilando swoole-${REQUIRED_VERSION} (esto toma 10–20 min) ─"
log "PECL install swoole-${REQUIRED_VERSION} ..."
# Opciones: enable-openssl, enable-sockets, enable-http2 (para WS + HTTP bridge)
printf "yes\nyes\nyes\nno\nno\n" | pecl install "swoole-${REQUIRED_VERSION}" 2>&1

# ── Habilitar extensión ────────────────────────────────────────────────────────
echo ""
echo "── Habilitando extensión swoole ──────────────────────────────"
for CONF_DIR in /etc/php/8.3/cli/conf.d /etc/php/8.3/fpm/conf.d; do
    CONF_FILE="${CONF_DIR}/20-swoole.ini"
    echo "extension=swoole.so" > "$CONF_FILE"
    ok "Creado: ${CONF_FILE}"
done

# ── Reiniciar PHP-FPM ─────────────────────────────────────────────────────────
systemctl restart php8.3-fpm
ok "php8.3-fpm reiniciado"

# ── Verificar ─────────────────────────────────────────────────────────────────
echo ""
echo "── Verificación ──────────────────────────────────────────────"
ACTUAL=$(php8.3 -r "echo SWOOLE_VERSION;" 2>/dev/null || echo "ERROR")
if [ "$ACTUAL" = "$REQUIRED_VERSION" ]; then
    ok "Swoole ${ACTUAL} instalado correctamente"
else
    err "Versión instalada: '${ACTUAL}' — esperada: '${REQUIRED_VERSION}'"
    exit 1
fi

php8.3 -m | grep -q swoole \
    && ok "swoole activo en php -m" \
    || { err "swoole NO aparece en php -m"; exit 1; }

echo ""
ok "Swoole ${REQUIRED_VERSION} listo"
