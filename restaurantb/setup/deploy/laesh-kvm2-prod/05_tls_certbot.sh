#!/usr/bin/env bash
# ==============================================================================
# LAESH KVM2 · Paso 5 — TLS Dual-Mode (Idempotente / Post-Opcional)
#
# MODO A — Sin dominio (IP pura / pruebas pre-DNS):
#   sudo bash 05_tls_certbot.sh
#   → Genera cert self-signed, activa nginx-laesh-ip.conf
#
# MODO B — Con dominio (producción, DNS propagado):
#   LAESH_DOMAIN=laesh.mx LAESH_ADMIN_EMAIL=... sudo -E bash 05_tls_certbot.sh
#   → Emite cert Let's Encrypt, activa nginx-laesh-domain.conf
#
# Idempotente: puede correrse N veces sin daño.
# Puede correrse de forma independiente: sudo bash 05_tls_certbot.sh
# ==============================================================================
set -euo pipefail
[ "$EUID" -ne 0 ] && { echo "[ERROR] Requiere sudo"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  △${NC} $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; exit 1; }
log()  { echo "  → $*"; }

LAESH_DOMAIN="${LAESH_DOMAIN:-}"
LAESH_ADMIN_EMAIL="${LAESH_ADMIN_EMAIL:-cbena999@gmail.com}"
LAESH_IP="83.136.219.193"
HTTPS_DIR="/opt/laesh/https"
CFG_DIR="/opt/laesh/configs"
NGINX_SITE="/etc/nginx/sites-available/laesh"

mkdir -p "$HTTPS_DIR"

# ══════════════════════════════════════════════════════
# MODO A — IP / Self-signed
# ══════════════════════════════════════════════════════
if [[ -z "$LAESH_DOMAIN" ]]; then
    echo -e "${CYAN}── MODO A — IP / Self-Signed ──────────────────────────${NC}"

    CERT="${HTTPS_DIR}/self-signed.crt"
    KEY="${HTTPS_DIR}/self-signed.key"

    if [[ -f "$CERT" && -f "$KEY" ]]; then
        EXPIRY=$(openssl x509 -in "$CERT" -noout -enddate 2>/dev/null | cut -d= -f2 || echo "?")
        warn "Self-signed cert ya existe (expira: ${EXPIRY}). Omitiendo generación."
    else
        log "Generando cert self-signed para IP ${LAESH_IP}..."
        openssl req -x509 -newkey rsa:4096 -nodes -days 365 \
            -keyout "$KEY" -out "$CERT" \
            -subj "/C=MX/ST=MX/L=Hostinger/O=LAESH/CN=${LAESH_IP}" \
            -addext "subjectAltName=IP:${LAESH_IP}" 2>/dev/null
        chmod 600 "$KEY"
        ok "Self-signed cert generado (válido 365 días)"
    fi

    # Activar config Modo A
    if [[ -f "${CFG_DIR}/nginx-laesh-ip.conf" ]]; then
        cp "${CFG_DIR}/nginx-laesh-ip.conf" "$NGINX_SITE"
        ln -sf "$NGINX_SITE" /etc/nginx/sites-enabled/laesh
        nginx -t && systemctl reload nginx && ok "Nginx recargado → Modo A (IP)"
    else
        warn "nginx-laesh-ip.conf no encontrado en ${CFG_DIR} — Nginx sin cambio"
    fi

    echo ""
    ok "Modo A activo. Probar:"
    echo "     curl -sk https://${LAESH_IP}/laesh/ | head -5"
    echo "     BASE=https://${LAESH_IP} bash /home/sysadmin/laesh-src/setup/bds/laesh/bash/03_test_deploy.sh"
    exit 0
fi

# ══════════════════════════════════════════════════════
# MODO B — Dominio + Let's Encrypt
# ══════════════════════════════════════════════════════
echo -e "${CYAN}── MODO B — Dominio + Let's Encrypt (${LAESH_DOMAIN}) ─${NC}"

# Verificar que DNS apunta a esta IP
log "Verificando DNS: ${LAESH_DOMAIN} → ${LAESH_IP} ..."
RESOLVED=$(dig +short "$LAESH_DOMAIN" 2>/dev/null | grep -v '\.$' | head -1 || echo "")
if [[ "$RESOLVED" != "$LAESH_IP" ]]; then
    warn "DNS no propagado: ${LAESH_DOMAIN} resuelve a '${RESOLVED:-<nada>}' (esperado: ${LAESH_IP})"
    warn "Ejecuta este script de nuevo cuando el DNS esté propagado."
    warn "Mientras tanto, Modo A sigue activo."
    exit 0  # salida limpia — no falla el pipeline
fi
ok "DNS OK: ${LAESH_DOMAIN} → ${LAESH_IP}"

# Asegurar que Nginx está en Modo A antes de certbot (necesita puerto 80)
cp "${CFG_DIR}/nginx-laesh-ip.conf" "$NGINX_SITE"
nginx -t && systemctl reload nginx
log "Nginx en Modo A temporalmente (certbot HTTP-01 challenge)"

# Crear directorio ACME challenge (nginx-laesh-domain.conf root=/opt/laesh/www)
mkdir -p /opt/laesh/www/.well-known/acme-challenge
chown -R www-data:www-data /opt/laesh/www/.well-known
ok "Directorio ACME challenge creado: /opt/laesh/www/.well-known/acme-challenge"

# Emitir o renovar cert
if certbot certificates 2>/dev/null | grep -q "Domains: ${LAESH_DOMAIN}"; then
    warn "Cert LE ya existe para ${LAESH_DOMAIN}. Ejecutando renovación si necesario..."
    certbot renew --quiet --nginx
    ok "Renovación verificada"
else
    log "Emitiendo nuevo cert Let's Encrypt..."
    certbot --nginx \
        -d "$LAESH_DOMAIN" \
        -d "www.${LAESH_DOMAIN}" \
        --non-interactive \
        --agree-tos \
        -m "$LAESH_ADMIN_EMAIL" \
        --redirect
    ok "Cert LE emitido"
fi

# Activar config Modo B
cp "${CFG_DIR}/nginx-laesh-domain.conf" "$NGINX_SITE"
ln -sf "$NGINX_SITE" /etc/nginx/sites-enabled/laesh
nginx -t && systemctl reload nginx && ok "Nginx recargado → Modo B (dominio + LE)"

# Symlink a certs LE para referencia en /opt/laesh/https/
ln -sfn "/etc/letsencrypt/live/${LAESH_DOMAIN}" "${HTTPS_DIR}/live"
ok "Symlink ${HTTPS_DIR}/live → /etc/letsencrypt/live/${LAESH_DOMAIN}"

# Asegurar timer de renovación automática
systemctl enable --now certbot.timer
ok "certbot.timer habilitado (renovación automática)"

# Hook post-renovación → reload nginx
HOOK_FILE="/etc/letsencrypt/renewal-hooks/post/reload-nginx.sh"
cat > "$HOOK_FILE" << 'EOF'
#!/bin/bash
systemctl reload nginx
echo "[certbot-hook] nginx recargado: $(date)" >> /opt/laesh/logs/certbot-renew.log
EOF
chmod +x "$HOOK_FILE"
ok "Hook post-renew configurado"

# Probar renovación en seco
log "Test renovación en seco..."
certbot renew --dry-run --quiet && ok "Dry-run renovación OK"

echo ""
ok "Modo B activo. Probar:"
echo "     curl -s https://${LAESH_DOMAIN}/laesh/ | head -5"
echo "     BASE=https://${LAESH_DOMAIN} bash /home/sysadmin/laesh-src/setup/bds/laesh/bash/03_test_deploy.sh"
