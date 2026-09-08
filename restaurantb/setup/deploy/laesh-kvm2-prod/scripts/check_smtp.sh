#!/usr/bin/env bash
# ==============================================================================
# LAESH — check_smtp.sh
# Verificación diaria de conectividad SMTP (Yahoo/swaks).
# Instalado por 07_security_harden.sh como cron diario (root, 08:30 AM).
#
# Qué verifica:
#   1. swaks disponible en PATH
#   2. swaks.conf existe y tiene server + auth-password
#   3. Conexión TCP al servidor SMTP (puerto 587)
#   4. Autenticación SMTP exitosa (--quit-after AUTH)
#      → No envía ningún mensaje — solo verifica que el canal está operativo
#
# Resultado: /opt/laesh/logs/smtp-check.log
#   [OK]       → canal SMTP operativo, alertas pueden entregarse
#   [WARNING]  → swaks disponible pero auth parcial / respuesta inesperada
#   [CRITICAL] → no se pudo conectar o autenticar → alertas silenciosas
#
# Nota: swaks.conf tiene chmod 600 root:root; este script debe correr como root.
# ==============================================================================

LOG="/opt/laesh/logs/smtp-check.log"
SWAKS_CFG="/opt/laesh/configs/swaks.conf"
TS=$(date '+%Y-%m-%d %H:%M:%S')
HOST=$(hostname -s)

# ── 1. swaks instalado ────────────────────────────────────────────────────────
if ! command -v swaks &>/dev/null; then
    echo "[$TS] [CRITICAL] swaks no instalado — apt-get install -y swaks" >> "$LOG"
    exit 1
fi

# ── 2. swaks.conf existe y es legible ────────────────────────────────────────
if [[ ! -r "$SWAKS_CFG" ]]; then
    echo "[$TS] [CRITICAL] swaks.conf no encontrado o sin permisos: $SWAKS_CFG" >> "$LOG"
    exit 1
fi

# ── 3. Leer credenciales ─────────────────────────────────────────────────────
_SMTP_SERVER=$(grep '^server=' "$SWAKS_CFG" | cut -d= -f2-)
_SMTP_PORT=$(grep  '^port='   "$SWAKS_CFG" | cut -d= -f2-)
_SMTP_USER=$(grep  '^auth-user='      "$SWAKS_CFG" | cut -d= -f2-)
_SMTP_PASS=$(grep  '^auth-password='  "$SWAKS_CFG" | cut -d= -f2-)
_SMTP_FROM=$(grep  '^from='   "$SWAKS_CFG" | cut -d= -f2-)
_SMTP_TO=$(grep    '^to='     "$SWAKS_CFG" | cut -d= -f2-)

if [[ -z "$_SMTP_SERVER" || -z "$_SMTP_PASS" ]]; then
    echo "[$TS] [CRITICAL] swaks.conf incompleto — faltan server o auth-password" >> "$LOG"
    exit 1
fi

# ── 4. Test de conectividad + autenticación (sin enviar mensaje) ─────────────
# --quit-after AUTH: swaks se desconecta justo después de autenticarse.
# No se entrega ningún mensaje — solo verifica que el canal funciona.
OUTPUT=$(swaks \
    --server  "$_SMTP_SERVER" \
    --port    "${_SMTP_PORT:-587}" \
    --tls \
    --auth    LOGIN \
    --auth-user     "$_SMTP_USER" \
    --auth-password "$_SMTP_PASS" \
    --from    "$_SMTP_FROM" \
    --to      "$_SMTP_TO" \
    --quit-after AUTH \
    --timeout 15 \
    2>&1)

EXIT_CODE=$?

# ── 5. Interpretar resultado ──────────────────────────────────────────────────
# swaks devuelve 0 si llegó al punto de quit-after sin error de protocolo.
# Buscar indicadores clave en la salida para distinguir OK de fallo parcial.
if echo "$OUTPUT" | grep -q '235'; then
    # 235 = Authentication successful (RFC 4954)
    echo "[$TS] [OK] SMTP operativo — ${_SMTP_SERVER}:${_SMTP_PORT:-587} · auth OK (235) · usuario: ${_SMTP_USER}" >> "$LOG"
    exit 0
elif echo "$OUTPUT" | grep -qE '535|534|530|authentication failed|auth fail' -i; then
    echo "[$TS] [CRITICAL] SMTP auth FALLIDA — ${_SMTP_SERVER}:${_SMTP_PORT:-587} · usuario: ${_SMTP_USER}" >> "$LOG"
    echo "[$TS] [CRITICAL] Detalle: $(echo "$OUTPUT" | grep -iE '535|534|error|fail' | head -3 | tr '\n' ' ')" >> "$LOG"
    echo "[$TS] [CRITICAL] ⚠ Las alertas SMTP NO serán entregadas hasta corregir credenciales." >> "$LOG"
    exit 1
elif [[ $EXIT_CODE -ne 0 ]]; then
    echo "[$TS] [CRITICAL] SMTP sin conexión — ${_SMTP_SERVER}:${_SMTP_PORT:-587} (exit ${EXIT_CODE})" >> "$LOG"
    echo "[$TS] [CRITICAL] Detalle: $(echo "$OUTPUT" | tail -3 | tr '\n' ' ')" >> "$LOG"
    echo "[$TS] [CRITICAL] ⚠ Las alertas SMTP NO serán entregadas." >> "$LOG"
    exit 1
else
    # Exit 0 pero sin 235 — respuesta inesperada, verificar manualmente
    echo "[$TS] [WARNING] SMTP respuesta inesperada (exit 0, sin 235) — ${_SMTP_SERVER}:${_SMTP_PORT:-587}" >> "$LOG"
    echo "[$TS] [WARNING] Última línea: $(echo "$OUTPUT" | tail -1)" >> "$LOG"
    exit 0
fi
