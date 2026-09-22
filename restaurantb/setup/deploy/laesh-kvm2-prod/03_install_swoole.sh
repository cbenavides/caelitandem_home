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
# Auditoría 2026-09-21: además de la versión, verificar que se compiló CON
# zlib — un binario 6.2.2 sin zlib (caso real encontrado en producción, ver
# nota en la sección de dependencias abajo) pasaba esta verificación de
# idempotencia y el script nunca recompilaba, dejando push() de WebSocket
# permanentemente roto (SW_ERROR_WEBSOCKET_PACK_FAILED). `--ri` (no `-r`) no
# ejecuta código de usuario — no dispara el hang de JIT+enable_cli que motivó
# la nota de arriba, solo consulta metadata del módulo ya cargado.
HAS_ZLIB=""
if [ -f "$SWOOLE_SO" ]; then
    HAS_ZLIB=$(php8.3 --ri swoole 2>/dev/null | grep -c "^zlib " || true)
fi

if [ "$INSTALLED" = "$REQUIRED_VERSION" ] && [ "${HAS_ZLIB:-0}" -gt 0 ]; then
    warn "Swoole ${REQUIRED_VERSION} ya instalado con zlib. Omitiendo compilación."
    [ -f "/etc/php/8.3/fpm/conf.d/20-swoole.ini" ] \
        && ok "Extensión swoole configurada en PHP-FPM" \
        || err "20-swoole.ini no encontrado en fpm/conf.d/ — paso incompleto"
    exit 0
elif [ "$INSTALLED" = "$REQUIRED_VERSION" ]; then
    warn "Swoole ${REQUIRED_VERSION} instalado SIN zlib (push() de WS roto). Recompilando..."
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

# ── Dependencia zlib (requerida para permessage-deflate en frames WebSocket) ──
# Auditoría 2026-09-21: faltaba por completo — Swoole compila SIN soporte de
# zlib en silencio si la librería -dev no está presente al momento de `pecl
# install` (no hay warning ni error visible). Efecto real: TODO $server->push()
# de WebSocket fallaba con SW_ERROR_WEBSOCKET_PACK_FAILED (8505) — Swoole
# intenta negociar/empaquetar permessage-deflate porque el cliente (navegador o
# cualquier librería WS estándar) SIEMPRE anuncia esa extensión en el handshake
# por defecto, sin importar 'websocket_compression'=>false en la config del
# servidor (esa opción solo controla si el SERVIDOR la ofrece, no si el intento
# de negociación con lo que el cliente pidió causa el fallo de empaquetado).
# Diagnosticado con getClientInfo() confirmando websocket_status=3 (conexión
# válida) pero push() fallando de todas formas — confirmado con `php8.3 --ri
# swoole` mostrando brotli habilitado pero zlib ausente de la lista de features.
if ! dpkg -l | grep -q "^ii  zlib1g-dev"; then
    log "Instalando zlib1g-dev (dependencia de compilación Swoole — permessage-deflate WS)..."
    apt-get install -yq zlib1g-dev
    ok "zlib1g-dev instalado"
else
    ok "zlib1g-dev ya disponible"
fi

# ── Compilar Swoole 6.2.2 ─────────────────────────────────────────────────────
echo "── Compilando swoole-${REQUIRED_VERSION} (esto toma 10–20 min) ─"
log "PECL install swoole-${REQUIRED_VERSION} ..."
# Opciones: enable-openssl, enable-sockets, enable-http2 (para WS + HTTP bridge)
# -f (force): PECL rehúsa recompilar si detecta la MISMA versión ya registrada
# como instalada, sin importar con qué flags/dependencias se compiló esa vez —
# caso real 2026-09-21: reinstalar tras agregar zlib1g-dev fallaba con
# "already installed and is the same as the released version... install
# failed" hasta forzar con -f.
#
# ⚠️ Si este script se re-ejecuta DESPUÉS de que 04_configure_stack.sh ya corrió
# (recompilación en un servidor ya configurado, no instalación fresca): pecl
# fallará en silencio (exit 255) porque configs/php-99-laesh.ini deshabilita
# popen() vía disable_functions en CLI, y PECL lo requiere internamente
# (OS_Guess::_fromGlibCTest()). El orden canónico de 00_run_all.sh (paso 3
# antes que paso 4) evita esto en una instalación fresca. Para recompilar en
# un servidor ya configurado, ver el procedimiento manual con wrapper
# PHP_PEAR_PHP_BIN en README.md §"Gaps y cambios — Estabilización Swoole
# 2026-09-21" (G-SWOOLE-08).
printf "yes\nyes\nyes\nno\nno\n" | pecl install -f "swoole-${REQUIRED_VERSION}" 2>&1

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
