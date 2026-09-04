#!/usr/bin/env bash
# ==============================================================================
# LAESH Bloc Digital — issue_cert.sh
# Wrapper para emitir / renovar certificado Let's Encrypt con certbot
# Uso manual:
#   LAESH_DOMAIN=laesh.mx ./https/issue_cert.sh
#   LAESH_DOMAIN=laesh.mx ./https/issue_cert.sh --dry-run
#   LAESH_DOMAIN=laesh.mx ./https/issue_cert.sh --force-renew
# ==============================================================================
set -euo pipefail

DOMAIN="${LAESH_DOMAIN:?ERROR: export LAESH_DOMAIN=laesh.mx antes de ejecutar}"
EMAIL="${LAESH_CERT_EMAIL:-admin@${DOMAIN}}"
DRY_RUN=""
FORCE_RENEW=""

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --dry-run)      DRY_RUN="--dry-run" ;;
        --force-renew)  FORCE_RENEW="--force-renewal" ;;
    esac
done

ts() { date '+%Y-%m-%d %H:%M:%S'; }

echo "$(ts) [issue_cert] Dominio:  $DOMAIN"
echo "$(ts) [issue_cert] Email:    $EMAIL"
echo "$(ts) [issue_cert] Flags:    ${DRY_RUN:-nada} ${FORCE_RENEW:-nada}"

# ── Pre-check: DNS resuelve al VPS ───────────────────────────────────────────
RESOLVED_IP=$(dig +short "$DOMAIN" | tail -1)
VPS_IP="83.136.219.193"

if [[ "$RESOLVED_IP" != "$VPS_IP" ]]; then
    echo "$(ts) [issue_cert] ERROR: DNS de $DOMAIN resuelve a '$RESOLVED_IP', no a $VPS_IP"
    echo "  → Actualiza los registros A en tu registrador de dominio y espera propagación."
    exit 1
fi
echo "$(ts) [issue_cert] DNS OK: $DOMAIN → $RESOLVED_IP"

# ── Pre-check: puerto 80 accesible (para ACME challenge HTTP-01) ─────────────
if ! curl -sf --max-time 5 "http://${DOMAIN}/.well-known/acme-challenge/test" &>/dev/null; then
    # 404 es OK; error de conexión no lo es
    HTTP_CODE=$(curl -o /dev/null -sw '%{http_code}' --max-time 5 "http://${DOMAIN}/" 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "000" ]]; then
        echo "$(ts) [issue_cert] ERROR: no hay respuesta HTTP en ${DOMAIN}:80. ¿Nginx corriendo? ¿UFW permite 80?"
        exit 1
    fi
fi
echo "$(ts) [issue_cert] Puerto 80 accesible (HTTP code: $HTTP_CODE)"

# ── Emitir / renovar certificado ─────────────────────────────────────────────
echo "$(ts) [issue_cert] Ejecutando certbot..."
certbot certonly \
    --nginx \
    -d "$DOMAIN" \
    -d "www.${DOMAIN}" \
    --email "$EMAIL" \
    --agree-tos \
    --non-interactive \
    --rsa-key-size 4096 \
    $DRY_RUN \
    $FORCE_RENEW

if [[ -n "$DRY_RUN" ]]; then
    echo "$(ts) [issue_cert] DRY-RUN completado OK — no se emitió cert real."
    exit 0
fi

# ── Post-emisión: crear symlink en /opt/laesh/https/live ─────────────────────
LIVE_DIR="/etc/letsencrypt/live/${DOMAIN}"
SYMLINK_DIR="/opt/laesh/https/live"

if [[ -d "$LIVE_DIR" ]]; then
    ln -sfn "$LIVE_DIR" "$SYMLINK_DIR"
    echo "$(ts) [issue_cert] Symlink: $SYMLINK_DIR → $LIVE_DIR"
fi

# ── Activar config Modo B (dominio) ──────────────────────────────────────────
SITES_AVAIL="/etc/nginx/sites-available"
SITES_EN="/etc/nginx/sites-enabled"
SRC_CONF="/opt/laesh/configs/nginx-laesh-domain.conf"

cp "$SRC_CONF" "${SITES_AVAIL}/laesh"
ln -sfn "${SITES_AVAIL}/laesh" "${SITES_EN}/laesh"

nginx -t && systemctl reload nginx
echo "$(ts) [issue_cert] Nginx recargado con config de dominio."

# ── Hook de renovación automática ────────────────────────────────────────────
HOOK="/etc/letsencrypt/renewal-hooks/post/reload-nginx.sh"
cat > "$HOOK" << 'HOOKEOF'
#!/bin/bash
systemctl reload nginx && \
    echo "$(date) certbot post-renew: nginx reloaded OK" >> /opt/laesh/logs/cert-renewal.log
HOOKEOF
chmod +x "$HOOK"
echo "$(ts) [issue_cert] Hook post-renovación instalado: $HOOK"

# ── Verificar renovación automática ──────────────────────────────────────────
echo "$(ts) [issue_cert] Verificando certbot renew (dry-run)..."
certbot renew --dry-run
echo "$(ts) [issue_cert] Renovación automática verificada OK."

echo ""
echo "✅  Certificado TLS emitido para $DOMAIN"
echo "    Cert: ${LIVE_DIR}/fullchain.pem"
echo "    Key:  ${LIVE_DIR}/privkey.pem"
echo "    Renovación: certbot.timer activo (systemctl status certbot.timer)"
