#!/usr/bin/env bash
# ==============================================================================
# bootstrap_oci_laesh.sh — Prepara el host de la VM OCI para correr LAESH (pruebas)
#
# Corre DENTRO de la VM OCI con sudo (lo invoca deploy_oci_laesh.sh). Idempotente:
# cada paso verifica antes de cambiar, así que se puede correr en cada deploy.
#
# Brecha KVM2 → OCI que cubre (sin tocar el código de la app):
#   1. /opt/laesh/{logs,cache,uploads/pdfs}: el código usa esas rutas absolutas
#      (config.php log_path, rc/index.php uploads, LAESH_CACHE_DIR).
#   2. /opt/laesh/assets/laesh-web-assets-uipv1a → symlink a laesh-stack/www/…:
#      el CMS (admrc/index.php) escribe ahí las imágenes subidas.
#   3. Permisos de escritura de www-data en assets/js (catalog/config-compiled.js)
#      y assets/cms (uploads CMS).
#   4. Pool php8.1-fpm: env[LAESH_JWT_SECRET] (APP_ENV=production lo exige) y
#      env[LAESH_CACHE_DIR]. El secreto se genera aquí, una sola vez, y nunca
#      sale de la VM.
#   5. nginx: snippet con la ruta interna /laesh-uploads/pdfs/ (X-Accel-Redirect).
#      Se agrega con un include en el server{} 443 existente; si `nginx -t` falla
#      se restaura el respaldo.
#
# Lo que OCI NO replica de KVM2 (aceptado para un ambiente de pruebas):
#   • Swoole/WebSocket: el cliente cae a polling AJAX (notificaciones con retraso).
#   • Crons (retry notificaciones, cache renew, backups), Least Privilege de
#     laesh_app, logrotate, monitoreo y alertas SMTP.
#   • PHP 8.1 (KVM2: 8.3) — el código no usa sintaxis 8.2+ (verificado 2026-10-01).
#
# Uso (en OCI):  sudo bash /home/ubuntu/laesh-stack/bootstrap_oci_laesh.sh
# ==============================================================================

set -euo pipefail
[[ "$EUID" -eq 0 ]] || { echo "[ERROR] requiere sudo"; exit 1; }

STACK_DIR="/home/ubuntu/laesh-stack"
WWW="${STACK_DIR}/www"
ASSETS_SRC="${WWW}/laesh-web-assets-uipv1a"
FPM_POOL="/etc/php/8.1/fpm/pool.d/www.conf"
FPM_SVC="php8.1-fpm"
NGINX_SITE="/etc/nginx/sites-available/caelitandem.lat"
SNIPPET_SRC="${STACK_DIR}/conf/nginx-laesh-oci-extra.conf"
SNIPPET_DST="/etc/nginx/snippets/nginx-laesh-oci-extra.conf"
INCLUDE_LINE="    include ${SNIPPET_DST};"

ok()   { echo "  ✓ $1"; }
skip() { echo "  · $1"; }

echo "── Bootstrap host OCI para LAESH ──────────────────────────────────"

# 1. Directorios de runtime
install -d -m 775 -o root     -g www-data /opt/laesh/logs
install -d -m 775 -o www-data -g www-data /opt/laesh/cache /opt/laesh/uploads /opt/laesh/uploads/pdfs
touch /opt/laesh/logs/app.log
chown www-data:www-data /opt/laesh/logs/app.log
chmod 664 /opt/laesh/logs/app.log
ok "/opt/laesh/{logs,cache,uploads/pdfs}"

# 2. Symlink de assets (ruta que usa el CMS para escribir)
install -d -m 755 /opt/laesh/assets
if [[ -L /opt/laesh/assets/laesh-web-assets-uipv1a ]]; then
    skip "symlink assets ya existe"
else
    ln -s "${ASSETS_SRC}" /opt/laesh/assets/laesh-web-assets-uipv1a
    ok "symlink /opt/laesh/assets/laesh-web-assets-uipv1a → ${ASSETS_SRC}"
fi

# 3. Permisos de escritura para www-data (solo si el código ya se sincronizó)
if [[ -d "${ASSETS_SRC}" ]]; then
    install -d "${ASSETS_SRC}/cms"
    chgrp -R www-data "${ASSETS_SRC}/js" "${ASSETS_SRC}/cms"
    chmod 775 "${ASSETS_SRC}/js" "${ASSETS_SRC}/cms"
    chmod g+w "${ASSETS_SRC}"/js/*-compiled.js "${ASSETS_SRC}"/cms/* 2>/dev/null || true
    ok "www-data escribe en assets/js y assets/cms"
else
    skip "assets aún no sincronizados — permisos en el próximo deploy"
fi

# 4. Pool php8.1-fpm
POOL_CHANGED=false
if ! grep -q '^env\[LAESH_JWT_SECRET\]' "${FPM_POOL}"; then
    echo "env[LAESH_JWT_SECRET] = $(openssl rand -hex 32)" >> "${FPM_POOL}"
    POOL_CHANGED=true; ok "env[LAESH_JWT_SECRET] generado"
else
    skip "env[LAESH_JWT_SECRET] ya existe"
fi
if ! grep -q '^env\[LAESH_CACHE_DIR\]' "${FPM_POOL}"; then
    echo "env[LAESH_CACHE_DIR]  = /opt/laesh/cache" >> "${FPM_POOL}"
    POOL_CHANGED=true; ok "env[LAESH_CACHE_DIR] agregado"
else
    skip "env[LAESH_CACHE_DIR] ya existe"
fi
if $POOL_CHANGED; then
    php-fpm8.1 -t >/dev/null 2>&1 && systemctl reload "${FPM_SVC}" && ok "${FPM_SVC} recargado"
fi

# 5. nginx: snippet + include
install -m 644 "${SNIPPET_SRC}" "${SNIPPET_DST}"
if grep -qF "${SNIPPET_DST}" "${NGINX_SITE}"; then
    skip "include del snippet ya presente"
    nginx -t >/dev/null 2>&1 && systemctl reload nginx
else
    BAK="${NGINX_SITE}.bak-laesh-$(date +%Y%m%d%H%M%S)"
    cp -a "${NGINX_SITE}" "${BAK}"
    # Se inserta justo antes del bloque de assets LAESH (dentro del server{} 443).
    sed -i "/location \^~ \/laesh-web-assets-uipv1a/i\\${INCLUDE_LINE}\n" "${NGINX_SITE}"
    if nginx -t >/dev/null 2>&1; then
        systemctl reload nginx
        ok "nginx: include agregado (respaldo: ${BAK})"
    else
        cp -a "${BAK}" "${NGINX_SITE}"
        echo "  ✗ nginx -t falló — sitio restaurado desde ${BAK}"; exit 1
    fi
fi

echo "── Bootstrap OK ───────────────────────────────────────────────────"
