#!/usr/bin/env bash
# ==============================================================================
# LAESH KVM2 — Test / Verificación SMTP con swaks
# Uso:
#   sudo bash /opt/laesh/scripts/test_smtp.sh
#   sudo bash /opt/laesh/scripts/test_smtp.sh --to otro@destino.com
#
# Propósito:
#   Verifica que swaks esté instalado, que swaks.conf tenga credenciales reales
#   (sin placeholder __SMTP_PASS__), envía un correo de prueba y reporta el
#   resultado. Diseñado para correr manualmente post-deploy y como smoke-test.
#
# Salida:
#   Exit 0 — SMTP OK (correo enviado)
#   Exit 1 — falla de preflight (swaks no instalado, swaks.conf inválido)
#   Exit 2 — SMTP falla de conexión/autenticación
#   Exit 3 — SMTP falla de envío (timeout / respuesta inesperada)
#
# Log: /opt/laesh/logs/alerts-smtp.log
# ==============================================================================
set -euo pipefail

SWAKS_CONF="/opt/laesh/configs/swaks.conf"
LOG_FILE="/opt/laesh/logs/alerts-smtp.log"
HOSTNAME_SHORT="$(hostname -s 2>/dev/null || echo 'kvm2')"
DATE_NOW="$(date '+%Y-%m-%d %H:%M:%S')"
OVERRIDE_TO="${1:-}"  # allow --to arg

# ── Colores (stdout solamente) ─────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  △${NC} $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
log()  { echo "  → $*"; }

# ── Helper: log a archivo + stdout ────────────────────────────────────────────
log_file() {
    echo "[${DATE_NOW}] [SMTP-TEST] $*" >> "$LOG_FILE" 2>/dev/null || true
}

echo ""
echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
echo -e "${CYAN} LAESH KVM2 — Verificación SMTP (swaks)          ${NC}"
echo -e "${CYAN} Host: ${HOSTNAME_SHORT}  ·  ${DATE_NOW}         ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
echo ""

# ── 1. Preflight: swaks instalado ─────────────────────────────────────────────
echo "── 1/4 Verificar swaks instalado ─────────────────────────"
if ! command -v swaks &>/dev/null; then
    err "swaks no está instalado. Instalar con: sudo apt-get install -y swaks"
    log_file "FAIL — swaks no instalado en ${HOSTNAME_SHORT}"
    exit 1
fi
SWAKS_VER="$(swaks --version 2>&1 | head -1 || echo 'desconocida')"
ok "swaks encontrado: ${SWAKS_VER}"

# ── 2. Preflight: swaks.conf existe y no tiene placeholder ────────────────────
echo ""
echo "── 2/4 Verificar swaks.conf ───────────────────────────────"
if [ ! -f "$SWAKS_CONF" ]; then
    err "swaks.conf no encontrado en: ${SWAKS_CONF}"
    err "Ejecutar primero: bash 07_security_harden.sh (paso 4 — SMTP swaks.conf)"
    log_file "FAIL — ${SWAKS_CONF} no encontrado"
    exit 1
fi

if grep -qF '__SMTP_PASS__' "$SWAKS_CONF"; then
    err "swaks.conf aún tiene el placeholder __SMTP_PASS__ sin sustituir."
    err "Sustituir con: sed -i 's/__SMTP_PASS__/TU_APP_PASSWORD/' ${SWAKS_CONF}"
    err "Luego: chmod 600 ${SWAKS_CONF} && chown root:root ${SWAKS_CONF}"
    log_file "FAIL — ${SWAKS_CONF} tiene placeholder sin sustituir"
    exit 1
fi

PERMS="$(stat -c '%a' "$SWAKS_CONF" 2>/dev/null || echo '?')"
OWNER="$(stat -c '%U:%G' "$SWAKS_CONF" 2>/dev/null || echo '?')"
log "swaks.conf: permisos=${PERMS}, propietario=${OWNER}"

if [[ "$PERMS" != "600" ]]; then
    warn "swaks.conf debería ser 600 (actual: ${PERMS}). Corrigiendo..."
    chmod 600 "$SWAKS_CONF" && ok "Permisos corregidos a 600" || warn "No se pudo corregir permisos — continuar de todas formas"
else
    ok "swaks.conf existe (600 root:root) — credenciales configuradas"
fi

# ── 3. Extraer destinatario desde swaks.conf (o usar override) ───────────────
echo ""
echo "── 3/4 Preparar correo de prueba ─────────────────────────"

if [[ "$OVERRIDE_TO" == "--to" ]] || [[ "$OVERRIDE_TO" == "" ]]; then
    # Leer --to desde el config
    TO_ADDR="$(grep -oP '(?<=--to\s)\S+' "$SWAKS_CONF" | head -1 || echo '')"
    [[ -z "$TO_ADDR" ]] && TO_ADDR="$(grep -oP '(?<=--to )\S+' "$SWAKS_CONF" | head -1 || echo '')"
else
    # Soporte: test_smtp.sh --to otro@email.com
    TO_ADDR="${OVERRIDE_TO#--to}"
    TO_ADDR="${TO_ADDR#=}"
    TO_ADDR="${TO_ADDR// /}"
fi

if [[ -z "$TO_ADDR" ]]; then
    warn "No se pudo leer --to de swaks.conf. Usando default: cbena999@gmail.com"
    TO_ADDR="cbena999@gmail.com"
fi

SUBJECT="[LAESH KVM2] TEST SMTP — ${HOSTNAME_SHORT} $(date '+%Y-%m-%d %H:%M')"
BODY="Correo de prueba generado por test_smtp.sh
----------------------------------------------------
Host:       ${HOSTNAME_SHORT}
Fecha:      ${DATE_NOW}
Config:     ${SWAKS_CONF}
Destino:    ${TO_ADDR}
----------------------------------------------------
Si recibes este correo, la configuración SMTP de LAESH KVM2
funciona correctamente. No requiere acción.

Stack: Nginx + PHP-FPM 8.3 + MariaDB 11.8 + Swoole
SMTP:  Yahoo SMTP · puerto 587 · STARTTLS · auth LOGIN
----------------------------------------------------"

log "Destinatario:   ${TO_ADDR}"
log "Asunto:         ${SUBJECT}"
ok "Correo de prueba preparado"

# ── 4. Enviar correo con swaks y reportar resultado ───────────────────────────
echo ""
echo "── 4/4 Enviar correo de prueba vía swaks ─────────────────"

# Ejecutar swaks; capturar salida completa y exit code
SWAKS_OUT_FILE="$(mktemp /tmp/swaks_test_XXXXXX.txt)"
SWAKS_EXIT=0

swaks \
    --config "$SWAKS_CONF" \
    --to "$TO_ADDR" \
    --h-Subject "$SUBJECT" \
    --body "$BODY" \
    > "$SWAKS_OUT_FILE" 2>&1 || SWAKS_EXIT=$?

SWAKS_OUTPUT="$(cat "$SWAKS_OUT_FILE")"
rm -f "$SWAKS_OUT_FILE"

echo ""
echo "── Salida de swaks ────────────────────────────────────────"
echo "$SWAKS_OUTPUT"
echo "────────────────────────────────────────────────────────────"

if [[ $SWAKS_EXIT -eq 0 ]]; then
    # Verificar que swaks reporta aceptación del servidor (SMTP 250)
    if echo "$SWAKS_OUTPUT" | grep -q '250 '; then
        ok "SMTP OK — servidor aceptó el mensaje (250). Correo enviado a: ${TO_ADDR}"
        log_file "OK — correo de prueba enviado a ${TO_ADDR} desde ${HOSTNAME_SHORT}"
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
        echo -e "${GREEN} ✓ SMTP VERIFICADO — swaks funcionando correctamente${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
        exit 0
    else
        warn "swaks exit 0 pero no se encontró '250' en la respuesta — verificar salida arriba"
        log_file "WARN — swaks exit 0 pero sin 250 (${HOSTNAME_SHORT}) — revisar salida"
        echo ""
        echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW} △ SMTP INCIERTO — exit 0 pero sin confirmación 250${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
        exit 3
    fi
elif [[ $SWAKS_EXIT -eq 28 ]] || echo "$SWAKS_OUTPUT" | grep -qi 'connect\|timeout\|refused'; then
    err "SMTP: falla de conexión o timeout (exit ${SWAKS_EXIT})"
    err "Verificar: servidor SMTP, puerto 587, red, UFW allow outgoing"
    log_file "FAIL — conexión SMTP falló (exit ${SWAKS_EXIT}) desde ${HOSTNAME_SHORT}"
    echo ""
    echo -e "${RED}══════════════════════════════════════════════════${NC}"
    echo -e "${RED} ✗ SMTP FALLA — error de conexión (exit ${SWAKS_EXIT})  ${NC}"
    echo -e "${RED}══════════════════════════════════════════════════${NC}"
    exit 2
elif echo "$SWAKS_OUTPUT" | grep -qi '535\|auth\|password\|credential'; then
    err "SMTP: error de autenticación (exit ${SWAKS_EXIT})"
    err "Verificar: --auth-user y --auth-password en ${SWAKS_CONF}"
    err "Yahoo: asegurarse de usar app-password (no contraseña de cuenta)"
    log_file "FAIL — autenticación SMTP falló (exit ${SWAKS_EXIT}) desde ${HOSTNAME_SHORT}"
    echo ""
    echo -e "${RED}══════════════════════════════════════════════════${NC}"
    echo -e "${RED} ✗ SMTP FALLA — error de autenticación (exit ${SWAKS_EXIT})${NC}"
    echo -e "${RED}══════════════════════════════════════════════════${NC}"
    exit 2
else
    err "SMTP: envío fallido (exit ${SWAKS_EXIT}) — ver salida arriba"
    log_file "FAIL — swaks exit ${SWAKS_EXIT} desde ${HOSTNAME_SHORT}"
    echo ""
    echo -e "${RED}══════════════════════════════════════════════════${NC}"
    echo -e "${RED} ✗ SMTP FALLA — exit ${SWAKS_EXIT}                         ${NC}"
    echo -e "${RED}══════════════════════════════════════════════════${NC}"
    exit 3
fi
