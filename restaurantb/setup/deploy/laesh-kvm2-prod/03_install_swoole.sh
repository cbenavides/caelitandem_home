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
# NOTA: no usar "php8.3 -r" para leer SWOOLE_VERSION — si el paso 7 ya corrió,
# opcache.jit=tracing + opcache.enable_cli=1 + extension=swoole.so cuelga el CLI.
# Alternativa segura: leer la versión desde el binario .so con `strings`.
SWOOLE_SO="/usr/lib/php/20230831/swoole.so"
INSTALLED=""
if [ -f "$SWOOLE_SO" ]; then
    INSTALLED=$(strings "$SWOOLE_SO" 2>/dev/null | grep -oE "${REQUIRED_VERSION//./\\.}" | head -1 || true)
    # Si la versión exacta no aparece como string, leer la más alta 6.x.x disponible
    [ -z "$INSTALLED" ] && INSTALLED=$(strings "$SWOOLE_SO" 2>/dev/null \
        | grep -oE '6\.[0-9]+\.[0-9]+' | sort -V | tail -1 || true)
fi
if [ "$INSTALLED" = "$REQUIRED_VERSION" ]; then
    warn "Swoole ${REQUIRED_VERSION} ya instalado. Omitiendo compilación."
    [ -f "/etc/php/8.3/fpm/conf.d/20-swoole.ini" ] \
        && ok "Extensión swoole configurada en PHP-FPM" \
        || err "20-swoole.ini no encontrado en fpm/conf.d/ — paso incompleto"
    exit 0
elif [ -n "$INSTALLED" ]; then
    warn "Swoole ${INSTALLED} instalado en .so (se requiere ${REQUIRED_VERSION}). Recompilando..."
fi

# ── Instalar PECL si no existe ────────────────────────────────────────────────
if ! command -v pecl &>/dev/null; then
    log "Instalando php8.3-pear (pecl)..."
    apt-get install -yq php-pear
fi

# ── Dependencia Brotli (requerida por Swoole --enable-brotli=yes) ─────────────
if ! dpkg -l | grep -q "^ii  libbrotli-dev"; then
    log "Instalando libbrotli-dev (dependencia de compilación Swoole)..."
    apt-get install -yq libbrotli-dev
    ok "libbrotli-dev instalado"
else
    ok "libbrotli-dev ya disponible"
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
# Usar strings en lugar de php8.3 -r para evitar hang (ver comentario idempotency).
echo ""
echo "── Verificación ──────────────────────────────────────────────"
ACTUAL=$(strings "$SWOOLE_SO" 2>/dev/null | grep -oE '6\.[0-9]+\.[0-9]+' | sort -V | tail -1 || echo "ERROR")
if [ "$ACTUAL" = "$REQUIRED_VERSION" ] || echo "$ACTUAL" | grep -qE "^${REQUIRED_VERSION%.*}\."; then
    ok "Swoole ${ACTUAL} instalado (binario verificado via strings)"
else
    err "Versión en .so: '${ACTUAL}' — esperada: '${REQUIRED_VERSION}'"
    exit 1
fi

# Verificar que el ini de extensión existe (sin invocar php -m que puede colgar)
[ -f "/etc/php/8.3/fpm/conf.d/20-swoole.ini" ] \
    && ok "20-swoole.ini presente en PHP-FPM conf.d/" \
    || { err "20-swoole.ini NO encontrado en /etc/php/8.3/fpm/conf.d/"; exit 1; }

echo ""
ok "Swoole ${REQUIRED_VERSION} listo"
