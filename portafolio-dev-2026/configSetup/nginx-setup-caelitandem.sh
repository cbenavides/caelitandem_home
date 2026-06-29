#!/usr/bin/env bash
# =============================================================================
# nginx-setup-caelitandem.sh
# Configura el vhost nginx para caelitandem.lat y www.caelitandem.lat
# apuntando a /home/ubuntu/caelitandem-www-servicios/
#
# Target:  ubuntu@oci-vm  (ejecutar vía SSH o directamente en el VM)
# Nginx:   1.18.0 (Ubuntu)
# Autor:   Generado por Antigravity — 2026-05-22
# =============================================================================

set -euo pipefail

# --- Colores para output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log()  { echo -e "${GREEN}[OK]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC}  $*" >&2; exit 1; }

# =============================================================================
# VARIABLES — ajustar si cambia el entorno
# =============================================================================
DOMAIN="caelitandem.lat"
WWW_DOMAIN="www.caelitandem.lat"
WEBROOT="/home/ubuntu/caelitandem-www-servicios"
VHOST_FILE="/etc/nginx/sites-available/${DOMAIN}"
VHOST_LINK="/etc/nginx/sites-enabled/${DOMAIN}"
HOME_DIR="/home/ubuntu"

# =============================================================================
# 1. Crear directorio raíz si no existe
# =============================================================================
echo ""
echo "=== [1/5] Directorio raíz del sitio ==="
if [ ! -d "${WEBROOT}" ]; then
    mkdir -p "${WEBROOT}"
    log "Directorio creado: ${WEBROOT}"
else
    warn "El directorio ya existe: ${WEBROOT}"
fi

# =============================================================================
# 2. Permisos: nginx (www-data) necesita poder atravesar /home/ubuntu
# =============================================================================
echo ""
echo "=== [2/5] Permisos de traversal para www-data ==="
HOME_PERMS=$(stat -c "%a" "${HOME_DIR}")
if [[ "${HOME_PERMS}" != *1 ]]; then
    chmod o+x "${HOME_DIR}"
    log "Permiso o+x aplicado en ${HOME_DIR} (era ${HOME_PERMS})"
else
    warn "El directorio ${HOME_DIR} ya tiene bit de ejecución para 'others' (${HOME_PERMS})"
fi

# =============================================================================
# 3. Crear el vhost nginx
# =============================================================================
echo ""
echo "=== [3/5] Virtual Host nginx ==="
if [ -f "${VHOST_FILE}" ]; then
    warn "El vhost ya existe en ${VHOST_FILE} — se sobreescribe."
fi

sudo tee "${VHOST_FILE}" > /dev/null << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} ${WWW_DOMAIN};

    root ${WEBROOT};
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Security headers
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip (text/html está habilitado por defecto en nginx — no se repite)
    gzip on;
    gzip_types text/css application/javascript image/svg+xml;
    gzip_min_length 256;

    # Cache de assets estáticos
    location ~* \.(css|js|png|jpg|jpeg|gif|svg|ico|woff2?)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    access_log /var/log/nginx/${DOMAIN}-access.log;
    error_log  /var/log/nginx/${DOMAIN}-error.log;
}
NGINXEOF

log "Vhost escrito en ${VHOST_FILE}"

# =============================================================================
# 4. Habilitar el site (symlink en sites-enabled)
# =============================================================================
echo ""
echo "=== [4/5] Habilitando el site ==="
if [ -L "${VHOST_LINK}" ]; then
    warn "El symlink ya existe: ${VHOST_LINK}"
else
    sudo ln -sf "${VHOST_FILE}" "${VHOST_LINK}"
    log "Symlink creado: ${VHOST_LINK} -> ${VHOST_FILE}"
fi

# =============================================================================
# 5. Validar config y recargar nginx
# =============================================================================
echo ""
echo "=== [5/5] Validación y recarga de nginx ==="
sudo nginx -t || err "La configuración de nginx tiene errores. Abortando."
sudo systemctl reload nginx
log "nginx recargado sin errores."

# =============================================================================
# 6. Crear index.html de placeholder si el directorio está vacío
# =============================================================================
echo ""
echo "=== [+] Página de placeholder ==="
if [ ! -f "${WEBROOT}/index.html" ]; then
    cat > "${WEBROOT}/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CaeliTandem — Próximamente</title>
</head>
<body>
  <h1>CaeliTandem</h1>
  <p>Sitio en construcción. Próximamente.</p>
</body>
</html>
HTMLEOF
    log "index.html placeholder creado en ${WEBROOT}"
else
    warn "index.html ya existe — no se sobreescribe."
fi

# =============================================================================
# 7. Verificación funcional
# =============================================================================
echo ""
echo "=== [✔] Verificación HTTP local ==="
HTTP_APEX=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ -H "Host: ${DOMAIN}")
HTTP_WWW=$( curl -s -o /dev/null -w "%{http_code}" http://localhost/ -H "Host: ${WWW_DOMAIN}")

[ "${HTTP_APEX}" = "200" ] && log "http://${DOMAIN}  → HTTP ${HTTP_APEX}" \
                           || warn "http://${DOMAIN}  → HTTP ${HTTP_APEX} (revisar)"

[ "${HTTP_WWW}"  = "200" ] && log "http://${WWW_DOMAIN} → HTTP ${HTTP_WWW}" \
                           || warn "http://${WWW_DOMAIN} → HTTP ${HTTP_WWW} (revisar)"

echo ""
echo "======================================="
echo " CONFIGURACIÓN COMPLETADA"
echo "======================================="
echo " Dominio:   http://${DOMAIN}"
echo "            http://${WWW_DOMAIN}"
echo " Webroot:   ${WEBROOT}"
echo " Vhost:     ${VHOST_FILE}"
echo "---------------------------------------"
echo " PENDIENTE (requiere DNS propagado):"
echo "   A  ${DOMAIN}     → <IP pública OCI>"
echo "   A  ${WWW_DOMAIN} → <IP pública OCI>"
echo ""
echo " OPCIONAL — HTTPS con Certbot:"
echo "   sudo certbot --nginx -d ${DOMAIN} -d ${WWW_DOMAIN}"
echo "======================================="
