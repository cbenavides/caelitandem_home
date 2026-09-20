#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# deploy.sh — Despliegue canónico a KVM2 (laesh.mx producción)
#
# Todas las rutas se leen de SERVER_MAP.env (mismo directorio).
# NO hardcodear rutas aquí — editar SERVER_MAP.env.
#
# USO (desde raíz del repo restaurantb):
#   bash setup/deploy/laesh-kvm2-prod/deploy.sh webapp    # PHP app
#   bash setup/deploy/laesh-kvm2-prod/deploy.sh assets    # CSS/JS/img
#   bash setup/deploy/laesh-kvm2-prod/deploy.sh scripts   # setup/BD scripts
#   bash setup/deploy/laesh-kvm2-prod/deploy.sh all       # las 3
#
# Actualizado: 2026-09-09
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Cargar mapa de rutas canónico ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/SERVER_MAP.env"

# ── Verificar raíz del repo ───────────────────────────────────────────────────
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
if [[ ! -d "${REPO_ROOT}/www/laesh-swbldi" ]]; then
    echo "✗ ERROR: Ejecutar desde raíz del repo (no se encontró www/laesh-swbldi)"
    exit 1
fi

# ── Opciones rsync comunes ────────────────────────────────────────────────────
# --no-group --no-owner : sysadmin no puede chgrp/chown en dirs root/www-data del servidor.
# --omit-dir-times      : sysadmin no puede utimes() en dirs que no son suyos.
#   Rsync transfiere contenido de archivos sin tocar metadatos de directorios.
RSYNC_OPTS=(-avz --checksum --delete
    --no-group --no-owner --no-perms --omit-dir-times
    --exclude='.git/'
    --exclude='.env'
    --exclude='*.log'
    --exclude='node_modules/'
    --exclude='vendor/'
    --exclude='.DS_Store'
)

# ── Funciones ─────────────────────────────────────────────────────────────────
_header() { echo ""; echo "══ $1 ══"; }
_ok()     { echo "  ✓ $1"; }
_err()    { echo "  ✗ ERROR: $1" >&2; exit 1; }

_check_pending_migrations() {
    # Hallazgo 2026-09-20 (auditoría de alineación bash↔SQL): setup_hostinger.sh
    # sin --drop omite el Paso 2 (00-09) por completo — un `deploy.sh webapp`
    # que despliegue PHP dependiente de un cambio de schema/SP sin que ese
    # cambio ya esté en KVM2 (vía --drop o vía migrations/) rompe en el primer
    # request real. No bloquea el deploy (puede haber migraciones pendientes
    # no relacionadas con este PHP) — solo advierte fuerte y pide confirmar.
    local pending
    pending=$(find "${REPO_ROOT}/setup/bds/laesh/migrations" -maxdepth 1 -name 'm*.sql' 2>/dev/null | sort)
    if [[ -n "${pending}" ]]; then
        echo ""
        echo "  ⚠️  ADVERTENCIA: hay migración(es) SQL pendiente(s) en tu copia local:"
        echo "${pending}" | sed 's/^/       /'
        echo "     Si el PHP que vas a desplegar depende de ese cambio de schema/SP"
        echo "     (ej. llamadas a un stored procedure con firma nueva), aplica"
        echo "     primero: bash $(basename "$0") bd"
        echo ""
        read -r -p "  ¿Continuar de todos modos con el deploy de webapp? [s/N] " _confirm
        [[ "${_confirm}" =~ ^[sS]$ ]] || { echo "  Cancelado."; exit 1; }
    fi
}

deploy_webapp() {
    _check_pending_migrations
    _header "WEBAPP PHP → ${KVM2_SSH}:${KVM2_WEBAPP}/"
    rsync "${RSYNC_OPTS[@]}" \
        --exclude='crons/*.log' \
        --exclude='uploads/'    \
        --exclude='docs-dev/'   \
        "${REPO_ROOT}/www/laesh-swbldi/" \
        "${KVM2_SSH}:${KVM2_WEBAPP}/"
    _ok "webapp desplegada"

    # cms-trash/ lo crea cms_cleanup.php en su primera ejecución real (www-data → ownership correcto)
    echo "  → Recargando PHP-FPM..."
    ssh "${KVM2_SSH}" "sudo systemctl reload ${KVM2_PHP_FPM_SERVICE}"
    _ok "${KVM2_PHP_FPM_SERVICE} recargado"

    # Hallazgo 2026-09-18: swoole-laesh es un proceso de larga duración (no por-request
    # como PHP-FPM) — cambios en commons/swoole_server.php (o cualquier clase que
    # importe, ej. notifier.php, JwtManager.php, Cache.php) no toman efecto hasta que
    # el proceso vuelve a leer el código desde disco.
    # VERIFICADO EMPÍRICAMENTE (2026-09-18): 'systemctl reload' (SIGHUP) NO recarga
    # código — solo reabre file descriptors de log (por eso logrotate-laesh.conf lo usa
    # para swoole.log, un propósito distinto). Confirmado con marcador de prueba: tras
    # 'reload' el marcador no aparecía en /status; tras 'restart' sí. Tocar solo 'reload'
    # aquí dejaría el proceso corriendo código viejo de forma silenciosa — se usa
    # 'restart' a propósito, aunque cierra las conexiones WS activas (mitigado por el
    # reintento automático + fallback a polling ya existente en ws-client.js).
    # Hallazgo 2026-09-18: 'sudo systemctl restart ... 2>/dev/null || true' silenciaba
    # un fallo REAL de sudo (faltaba entrada en /etc/sudoers.d/laesh-deploy — ver README
    # §Sudoers) — el curl /status posterior solo confirmaba que el proceso VIEJO seguía
    # vivo, reportando éxito falso mientras el código nuevo nunca se aplicaba. Ahora se
    # verifica el exit code real del restart, y se aborta (no silenciar) si falla.
    echo "  → Reiniciando swoole-laesh (código nuevo requiere restart, no reload)..."
    if ! ssh "${KVM2_SSH}" "sudo systemctl restart swoole-laesh"; then
        _err "systemctl restart swoole-laesh falló — verificar /etc/sudoers.d/laesh-deploy (ver README §Sudoers). swoole-laesh puede estar corriendo código VIEJO."
    fi
    sleep 3
    ssh "${KVM2_SSH}" "curl -sf --max-time 5 http://127.0.0.1:9502/status > /dev/null" \
        && _ok "swoole-laesh reiniciado y respondiendo" \
        || _err "swoole-laesh reiniciado pero /status no respondió — verificar manualmente (journalctl -u swoole-laesh)"
}

deploy_assets() {
    # Paso 1/2 — local → staging (revisar antes de publicar a producción)
    _header "ASSETS paso 1/2 — local → staging: ${KVM2_SSH}:${KVM2_ASSETS_STAGING}/"
    chmod 777 "${REPO_ROOT}/www/laesh-web-assets-uipv1a/js/"
    rsync "${RSYNC_OPTS[@]}" \
        --exclude='cms/' \
        "${REPO_ROOT}/www/laesh-web-assets-uipv1a/" \
        "${KVM2_SSH}:${KVM2_ASSETS_STAGING}/"
    _ok "assets en staging — revisar con: ssh ${KVM2_SSH} 'ls ${KVM2_ASSETS_STAGING}/'"
    echo "  → Para publicar a producción: bash deploy.sh assets-publish"
}

deploy_assets_publish() {
    # Paso 2/2 — staging → producción (ejecutar después de revisar staging)
    # --exclude='cms/'       protege imágenes subidas por el CMS (www-data, no en repo)
    # --exclude='cms-trash/' protege papelera de cms_cleanup.php (www-data, rsync no puede leer)
    # --no-group --no-owner --omit-dir-times: sysadmin no es dueño de /opt/laesh/assets/
    _header "ASSETS paso 2/2 — staging → producción: ${KVM2_SSH}:${KVM2_ASSETS}/"
    ssh "${KVM2_SSH}" "rsync -avz --checksum --delete \
        --no-group --no-owner --no-perms --omit-dir-times \
        --exclude='cms/' \
        --exclude='cms-trash/' \
        '${KVM2_ASSETS_STAGING}/' \
        '${KVM2_ASSETS}/'"
    ssh "${KVM2_SSH}" "sudo chmod 0775 ${KVM2_ASSETS}/js/ 2>/dev/null || true; sudo chown www-data:www-data ${KVM2_ASSETS}/js/catalog-compiled.js ${KVM2_ASSETS}/js/catalog-data.js 2>/dev/null || true; sudo chmod 0664 ${KVM2_ASSETS}/js/catalog-compiled.js ${KVM2_ASSETS}/js/catalog-data.js 2>/dev/null || true"
    _ok "assets publicados a producción (cms/ y cms-trash/ excluidos — imágenes CMS intactas)"
}

deploy_bd() {
    # Deploy incremental de BD — para cambios a BD viva sin --drop.
    # Flujo:
    #   1. Sincroniza setup/bds/laesh/ completo a KVM2 staging (incluye migrations/)
    #   2. Corre setup_hostinger.sh SIN --drop en KVM2:
    #      - Paso 2b aplica los m*.sql activos en migrations/
    #      - Pasos 3, 3b, 4 son idempotentes (no-op si ya están aplicados)
    # Prerrequisito: /opt/laesh/configs/.env y .mariadb-root.cnf en KVM2
    _header "BD INCREMENTAL → ${KVM2_SSH} (setup_hostinger.sh sin --drop)"
    # Paso 1: sincronizar scripts de BD al staging
    rsync "${RSYNC_OPTS[@]}" \
        --exclude='bds/voz_cocina_dual/' \
        "${REPO_ROOT}/setup/bds/" \
        "${KVM2_SSH}:${KVM2_SETUP_DIR}/bds/"
    _ok "scripts BD sincronizados a staging"
    # Paso 2: correr setup_hostinger.sh en KVM2 (lee creds desde .env + .mariadb-root.cnf)
    # Hallazgo 2026-09-20 (auditoría): setup_hostinger.sh necesita leer
    # /opt/laesh/configs/.mariadb-root.cnf (600 root:root) — sin sudo, sysadmin
    # no puede abrirlo y el script aborta con "H_ROOT_PASS no definida", pese a
    # que esta función se documenta como el camino BD incremental estándar.
    # Requiere la entrada NOPASSWD de setup_hostinger.sh en
    # /etc/sudoers.d/laesh-deploy (ver README §Sudoers) — si falta, sudo pedirá
    # contraseña en una sesión SSH no interactiva y este paso fallará con
    # "sudo: a password is required"; el mensaje ya apunta a la causa exacta.
    echo "  → Ejecutando setup_hostinger.sh en KVM2 (sin --drop)..."
    ssh "${KVM2_SSH}" "sudo bash ${KVM2_SETUP_DIR}/bds/laesh/setup_hostinger.sh"
    _ok "BD incremental aplicada — revisar output arriba"
    echo ""
    echo "  ⚠  Tras validar cada migración: fold al script base 00–09 + eliminar m*.sql"
}

deploy_scripts() {
    _header "SCRIPTS/SETUP → ${KVM2_SSH}:${KVM2_SETUP_DIR}/"
    rsync "${RSYNC_OPTS[@]}" \
        --exclude='bds/voz_cocina_dual/' \
        --exclude='deploy/pwa/' \
        --exclude='deploy/webapps/' \
        --exclude='deploy/deploy_oci_laesh.sh' \
        --exclude='deploy/sync_to_hkvm2.sh'   \
        "${REPO_ROOT}/setup/" \
        "${KVM2_SSH}:${KVM2_SETUP_DIR}/"
    _ok "scripts/setup desplegados (excluidos: bds/voz_cocina_dual, deploy/pwa, deploy/webapps, deploy_oci_laesh.sh, sync_to_hkvm2.sh)"
}

# ── Main ──────────────────────────────────────────────────────────────────────
if [[ $# -eq 0 ]]; then
    echo "Uso: bash deploy.sh [webapp|assets|assets-publish|bd|scripts|all]"
    echo ""
    echo "── Setup desde cero (servidor nuevo / --nuke) ──"
    echo "  webapp          → rsync PHP   local → ${KVM2_SSH}:${KVM2_WEBAPP}/ + reload php-fpm"
    echo "  assets          → rsync CSS/JS local → staging ${KVM2_SSH}:${KVM2_ASSETS_STAGING}/ (paso 1/2)"
    echo "  assets-publish  → rsync staging → producción ${KVM2_SSH}:${KVM2_ASSETS}/ (paso 2/2)"
    echo "  scripts         → rsync setup/ local → ${KVM2_SSH}:${KVM2_SETUP_DIR}/"
    echo "  all             → webapp + assets (paso 1) + scripts  [assets-publish requiere paso explícito]"
    echo ""
    echo "── Deploy incremental (BD viva, sin --drop) ────"
    echo "  bd              → sync bds/ + corre setup_hostinger.sh sin --drop en KVM2"
    echo "                    aplica migrations/m*.sql activos (idempotentes)"
    echo "                    Prerreq: crear mNNN_*.sql en setup/bds/laesh/migrations/"
    exit 0
fi

for ARG in "$@"; do
    case "${ARG}" in
        webapp)          deploy_webapp          ;;
        assets)          deploy_assets          ;;
        assets-publish)  deploy_assets_publish  ;;
        bd)              deploy_bd              ;;
        scripts)         deploy_scripts         ;;
        all)
            deploy_webapp
            deploy_assets    # solo staging — correr assets-publish por separado tras revisar
            deploy_scripts
            ;;
        *)
            echo "Argumento desconocido: ${ARG}"
            echo "Uso: bash deploy.sh [webapp|assets|assets-publish|bd|scripts|all]"
            exit 1
            ;;
    esac
done

echo ""
echo "══ Deploy completado $(date '+%Y-%m-%d %H:%M:%S') ══"
