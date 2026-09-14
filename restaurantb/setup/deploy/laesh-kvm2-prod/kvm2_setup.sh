#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# kvm2_setup.sh — Setup completo en KVM2 (corre DENTRO del servidor)
#
# Lee credenciales desde /opt/laesh/configs/ — ningún password se pasa por CLI.
# Debe existir ANTES de ejecutar este script:
#   /opt/laesh/configs/.mariadb-root.cnf  → password root MariaDB
#   /opt/laesh/configs/.env               → LAESH_APP_PASS + LAESH_SMTP_PASS
#
# USO (en KVM2, como root o con sudo):
#   sudo bash ~/staging/setup/deploy/laesh-kvm2-prod/kvm2_setup.sh --nuke
#   sudo bash ~/staging/setup/deploy/laesh-kvm2-prod/kvm2_setup.sh --drop
#   sudo bash ~/staging/setup/deploy/laesh-kvm2-prod/kvm2_setup.sh --skip-bd
#   sudo bash ~/staging/setup/deploy/laesh-kvm2-prod/kvm2_setup.sh           # idempotente
#
# FLAGS:
#   --nuke     ⚠ DESTRUCTIVO: borra configs/scripts/crones/crons del sistema y BD,
#              luego reconstruye TODO desde staging. Implica --drop.
#              Preserva SOLO .mariadb-root.cnf y .env (credenciales necesarias para correr).
#   --drop     Destruye y recrea laesh_db sin tocar configs del sistema.
#   --skip-bd  Solo dirs + configs + PHP-FPM + crons + servicios; BD intacta.
#   (sin flag) Idempotente: configura lo que falta, preserva lo existente.
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail
[[ "$EUID" -ne 0 ]] && { echo "[ERROR] kvm2_setup.sh requiere sudo"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"

# ── Colores ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()     { echo -e "${GREEN}  ✓${NC} $*"; }
warn()   { echo -e "${YELLOW}  △${NC} $*"; }
err()    { echo -e "${RED}  ✗ ERROR:${NC} $*" >&2; exit 1; }
header() { echo -e "\n${CYAN}══ $* ══${NC}"; }
log()    { echo "  → $*"; }

# ── Cargar rutas canónicas ────────────────────────────────────────────────────
SERVER_MAP="${SCRIPT_DIR}/SERVER_MAP.env"
[[ -f "${SERVER_MAP}" ]] && source "${SERVER_MAP}" \
    || { warn "SERVER_MAP.env no encontrado — usando paths hardcoded como fallback"; }

# Paths con fallback explícito si SERVER_MAP no cargó
LAESH_ROOT="${KVM2_LAESH_ROOT:-/opt/laesh}"
WEBAPP_DIR="${KVM2_WEBAPP:-${LAESH_ROOT}/www/laesh-swbldi}"
ASSETS_DIR="${KVM2_ASSETS:-${LAESH_ROOT}/assets/laesh-web-assets-uipv1a}"
PHP_FPM_SERVICE="${KVM2_PHP_FPM_SERVICE:-php8.3-fpm}"
PHP_BIN="${KVM2_PHP_BIN:-php8.3}"
MARIADB_SERVICE="${KVM2_MARIADB_SERVICE:-mariadb}"
CONFIGS_DIR="${LAESH_ROOT}/configs"
MARIADB_ROOT_CNF="${CONFIGS_DIR}/.mariadb-root.cnf"
LAESH_ENV_FILE="${CONFIGS_DIR}/.env"

# ── Flags ─────────────────────────────────────────────────────────────────────
DROP_FLAG=""; SKIP_BD=false; NUKE=false
for _arg in "$@"; do
    case "$_arg" in
        --nuke)    NUKE=true; DROP_FLAG="--drop" ;;  # nuke implica drop
        --drop)    DROP_FLAG="--drop" ;;
        --skip-bd) SKIP_BD=true       ;;
    esac
done

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  LAESH KVM2 — Setup Completo"
echo "  Fecha:  $(date '+%Y-%m-%d %H:%M:%S')"
if $NUKE; then
echo "  Modo:   ⚠ NUKE — borrar todo + reconstruir desde staging + DROP BD"
else
echo "  Modo:   ${DROP_FLAG:-idempotente} $( $SKIP_BD && echo '--skip-bd' || echo '' )"
fi
echo "══════════════════════════════════════════════════════════════"

# ════════════════════════════════════════════════════════════════
# FASE 0 — Limpieza total (solo con --nuke)
# ════════════════════════════════════════════════════════════════
if $NUKE; then
    header "0/7 Limpieza total (--nuke)"
    warn "Borrando configs, scripts y crones para reconstruir desde staging..."

    # Eliminar configs del sistema (preservar SOLO .mariadb-root.cnf y .env)
    if [[ -d "${CONFIGS_DIR}" ]]; then
        find "${CONFIGS_DIR}" -maxdepth 1 -type f \
            ! -name '.mariadb-root.cnf' \
            ! -name '.env' \
            -delete
        ok "Configs limpiados (preservados: .mariadb-root.cnf, .env)"
    fi

    # Eliminar scripts operacionales
    if [[ -d "${LAESH_ROOT}/scripts" ]]; then
        find "${LAESH_ROOT}/scripts" -maxdepth 1 -type f -delete
        ok "Scripts /opt/laesh/scripts/ limpiados"
    fi

    # Eliminar crones (staging)
    if [[ -d "${LAESH_ROOT}/crones" ]]; then
        find "${LAESH_ROOT}/crones" -maxdepth 1 -type f -delete
        ok "Crones /opt/laesh/crones/ limpiados"
    fi

    # Eliminar cron jobs del sistema
    rm -f /etc/cron.d/laesh-*
    ok "Cron jobs del sistema eliminados (/etc/cron.d/laesh-*)"

    # Eliminar pool PHP-FPM (se recrea en fase 5)
    rm -f /etc/php/8.3/fpm/pool.d/laesh.conf
    ok "PHP-FPM pool eliminado (se recrea en fase 5)"

    # Eliminar log-levels.conf (se recrea en fase 3)
    rm -f "${LAESH_ROOT}/logs/log-levels.conf"
    ok "log-levels.conf eliminado (se recrea en fase 3)"

    warn "Limpieza completa — continuando reconstrucción desde staging"
fi

# ════════════════════════════════════════════════════════════════
# FASE 1 — Leer credenciales
# ════════════════════════════════════════════════════════════════
header "1/7 Credenciales"

# Root MariaDB
[[ -f "${MARIADB_ROOT_CNF}" ]] || err \
    "${MARIADB_ROOT_CNF} no encontrado.\n\
    Debe existir con formato [client] / password=TuPass\n\
    Si es nueva instalación: correr pipeline 01-04 primero."
# Verificar conectividad
if ! mariadb --defaults-extra-file="${MARIADB_ROOT_CNF}" -e "SELECT 1;" &>/dev/null; then
    err "MariaDB no accesible con ${MARIADB_ROOT_CNF}. Verificar que MariaDB está corriendo y la contraseña es correcta."
fi
ok "MariaDB root — conectividad verificada (vía .mariadb-root.cnf)"
MCMD="mariadb --defaults-extra-file=${MARIADB_ROOT_CNF}"

# App password (laesh_app)
if [[ -f "${LAESH_ENV_FILE}" ]]; then
    # Leer sin `source` para evitar ejecutar código arbitrario
    LAESH_APP_PASS="$(grep -Po '(?<=^LAESH_APP_PASS=)[^#\r\n]+' "${LAESH_ENV_FILE}" 2>/dev/null | head -1 | tr -d " '\"")"
    LAESH_SMTP_PASS="$(grep -Po '(?<=^LAESH_SMTP_PASS=)[^#\r\n]+' "${LAESH_ENV_FILE}" 2>/dev/null | head -1 | tr -d " '\"")"
    ok "Credenciales leídas desde ${LAESH_ENV_FILE}"
fi
[[ -z "${LAESH_APP_PASS:-}" ]] && err \
    "LAESH_APP_PASS no encontrada en ${LAESH_ENV_FILE}.\n\
    Ejecutar full_install.sh desde local para escribirlo, o crear manualmente:\n\
    sudo bash -c 'echo LAESH_APP_PASS=TuPass > ${LAESH_ENV_FILE} && chmod 600 ${LAESH_ENV_FILE}'"

# ════════════════════════════════════════════════════════════════
# FASE 2 — Estructura de directorios
# ════════════════════════════════════════════════════════════════
header "2/7 Estructura de directorios /opt/laesh/"

declare -A DIR_SPEC
# formato: DIR_SPEC["ruta"]="owner:grupo:modo"
DIR_SPEC["${LAESH_ROOT}/www"]="root:root:0755"
# laesh-swbldi/: sysadmin:sysadmin para que deploy.sh (rsync como sysadmin) funcione sin sudo.
# PHP-FPM (www-data) lee/ejecuta vía bits 'other' (0755 = rwxr-xr-x).
DIR_SPEC["${WEBAPP_DIR}"]="sysadmin:sysadmin:0755"
DIR_SPEC["${LAESH_ROOT}/assets"]="root:root:0755"
# assets raíz: sysadmin:sysadmin para que deploy.sh assets-publish funcione sin sudo.
# www-data lee via 'other' (0755). cms/ y fonts/ mantienen www-data para escritura CMS.
DIR_SPEC["${ASSETS_DIR}"]="sysadmin:sysadmin:0755"
DIR_SPEC["${ASSETS_DIR}/cms"]="www-data:www-data:0755"
DIR_SPEC["${ASSETS_DIR}/fonts"]="sysadmin:sysadmin:0755"
DIR_SPEC["${LAESH_ROOT}/uploads/pdfs"]="www-data:www-data:0750"
DIR_SPEC["${LAESH_ROOT}/uploads/cms"]="www-data:www-data:0755"
DIR_SPEC["${LAESH_ROOT}/cache"]="www-data:www-data:0750"
DIR_SPEC["${LAESH_ROOT}/logs"]="root:adm:0755"
DIR_SPEC["${LAESH_ROOT}/backups/db"]="root:root:0750"
DIR_SPEC["${LAESH_ROOT}/monitor"]="root:root:0755"
DIR_SPEC["${LAESH_ROOT}/scripts"]="root:root:0755"
DIR_SPEC["${LAESH_ROOT}/crones"]="root:root:0755"
DIR_SPEC["${CONFIGS_DIR}"]="root:root:0750"
# Fallback upload dir (PHP hardcoded path — resiliencia si BD no responde)
DIR_SPEC["${WEBAPP_DIR}/uploads/resultados"]="www-data:www-data:0750"

for dir_path in "${!DIR_SPEC[@]}"; do
    IFS=':' read -r _owner _group _mode <<< "${DIR_SPEC[$dir_path]}"
    mkdir -p "${dir_path}"
    chown "${_owner}:${_group}" "${dir_path}"
    chmod "${_mode}" "${dir_path}"
done
ok "Árbol /opt/laesh/ verificado/creado (${#DIR_SPEC[@]} directorios)"

# Crear logs iniciales con owner correcto (logrotate puede haberlos creado mal)
for _log in cms-cleanup.log cache-renew.log cache-renew-boot.log app.log; do
    _path="${LAESH_ROOT}/logs/${_log}"
    [[ ! -f "${_path}" ]] && touch "${_path}"
    case "${_log}" in
        # app.log: PHP-FPM (www-data) escribe; grupo adm puede leer vía sudo cat/tail
        app.log)                          chown www-data:adm "${_path}";       chmod 0640 "${_path}" ;;
        cms-cleanup.log|cache-renew*.log) chown www-data:www-data "${_path}"; chmod 0640 "${_path}" ;;
        *)                                 chown root:adm "${_path}";           chmod 0640 "${_path}" ;;
    esac
done
ok "Archivos de log inicializados con owner correcto"

# ════════════════════════════════════════════════════════════════
# FASE 3 — Copiar configs/crones/scripts desde staging
# ════════════════════════════════════════════════════════════════
header "3/7 Configs, crones y scripts desde staging"

STAGING_DEPLOY="${SCRIPT_DIR}"   # este script vive en staging/deploy/laesh-kvm2-prod/

# Configs → /opt/laesh/configs/ (NO sobreescribir .mariadb-root.cnf ni .env)
if [[ -d "${STAGING_DEPLOY}/configs" ]]; then
    for _f in "${STAGING_DEPLOY}"/configs/*; do
        _base="$(basename "$_f")"
        # Proteger SIEMPRE las credenciales base (sin ellas el script no puede correr)
        if [[ "${_base}" == ".mariadb-root.cnf" ]] || [[ "${_base}" == ".env" ]]; then
            warn "  Saltando ${_base} (credenciales — nunca se sobreescribe)"
            continue
        fi
        # swaks.conf: en modo idempotente/--drop preservar si ya tiene credenciales reales.
        # En modo --nuke la Fase 0 ya lo eliminó, así que aquí siempre se copia el template
        # y la Fase 6 (07_security_harden.sh) inyecta LAESH_SMTP_PASS de .env.
        if ! $NUKE && [[ "${_base}" == "swaks.conf" ]] && [[ -f "${CONFIGS_DIR}/swaks.conf" ]]; then
            if ! grep -q "__SMTP_PASS__" "${CONFIGS_DIR}/swaks.conf" 2>/dev/null; then
                warn "  Saltando swaks.conf (ya configurado — preservado en modo idempotente)"
                continue
            fi
        fi
        cp -f "${_f}" "${CONFIGS_DIR}/${_base}"
    done
    ok "Configs copiados a ${CONFIGS_DIR}/"
fi

# Crones → /opt/laesh/crones/
if [[ -d "${STAGING_DEPLOY}/crones" ]]; then
    cp -f "${STAGING_DEPLOY}"/crones/* "${LAESH_ROOT}/crones/"
    ok "Crones copiados a ${LAESH_ROOT}/crones/"
fi

# Scripts → /opt/laesh/scripts/
STAGING_SCRIPTS="${STAGING_DEPLOY}/scripts"
if [[ -d "${STAGING_SCRIPTS}" ]]; then
    cp -f "${STAGING_SCRIPTS}"/* "${LAESH_ROOT}/scripts/"
    chmod +x "${LAESH_ROOT}"/scripts/*.sh 2>/dev/null || true
    ok "Scripts copiados a ${LAESH_ROOT}/scripts/"
fi

# log-levels.conf inicial (no sobreescribir si ya fue editado en producción)
LOG_LEVELS_CONF="${LAESH_ROOT}/logs/log-levels.conf"
LOG_LEVELS_SRC="${STAGING_DEPLOY}/logs/log-levels.conf"
if [[ ! -f "${LOG_LEVELS_CONF}" ]] && [[ -f "${LOG_LEVELS_SRC}" ]]; then
    cp "${LOG_LEVELS_SRC}" "${LOG_LEVELS_CONF}"
    chown root:www-data "${LOG_LEVELS_CONF}"
    chmod 664 "${LOG_LEVELS_CONF}"
    ok "log-levels.conf inicial copiado"
elif [[ -f "${LOG_LEVELS_CONF}" ]]; then
    ok "log-levels.conf — ya existe, preservado"
fi

# ════════════════════════════════════════════════════════════════
# FASE 4 — Base de datos
# ════════════════════════════════════════════════════════════════
header "4/7 Base de datos (setup_hostinger.sh ${DROP_FLAG})"

if $SKIP_BD; then
    warn "BD omitida (--skip-bd)"
else
    # Verificar que MariaDB está activo
    systemctl is-active --quiet "${MARIADB_SERVICE}" \
        || err "MariaDB (${MARIADB_SERVICE}) no está activo. Iniciar con: sudo systemctl start ${MARIADB_SERVICE}"

    BDS_SCRIPT="$(cd "${SCRIPT_DIR}/../.." && pwd)/bds/laesh/setup_hostinger.sh"
    [[ -f "${BDS_SCRIPT}" ]] \
        || err "setup_hostinger.sh no encontrado en ${BDS_SCRIPT}"

    # Pasar solo H_APP_PASS — root se lee automáticamente del .mariadb-root.cnf
    H_APP_PASS="${LAESH_APP_PASS}" \
    H_PHP_BIN="${PHP_BIN}" \
    H_WEB_DIR="${LAESH_ROOT}/www" \
    bash "${BDS_SCRIPT}" ${DROP_FLAG}
    ok "BD configurada"

    # Rutas de BD dependientes del entorno (KVM2 paths)
    log "Actualizando rutas de configuración en BD..."
    ${MCMD} laesh_db <<'SQL'
-- cms_upload_dir: directorio físico donde admrc/index.php guarda imágenes CMS
INSERT INTO configuraciones (clave, valor, descripcion)
  VALUES ('cms_upload_dir', '/opt/laesh/assets/laesh-web-assets-uipv1a/cms/', 'Directorio físico para uploads CMS imágenes')
  ON DUPLICATE KEY UPDATE valor = '/opt/laesh/assets/laesh-web-assets-uipv1a/cms/';

-- cms_upload_endpoint: ruta POST para subida de imágenes CMS
INSERT INTO configuraciones (clave, valor, descripcion)
  VALUES ('cms_upload_endpoint', '/laesh/adrc/cms/upload', 'Endpoint POST subida imágenes CMS')
  ON DUPLICATE KEY UPDATE valor = '/laesh/adrc/cms/upload'; -- fix: jwt cookie path=/laesh/ → endpoint debe incluir /laesh/

-- ruta_almacenamiento_pdf: donde rc/index.php guarda PDFs de resultados
INSERT INTO configuraciones (clave, valor, descripcion)
  VALUES ('ruta_almacenamiento_pdf', '/opt/laesh/uploads/pdfs/', 'Directorio físico para PDFs de resultados')
  ON DUPLICATE KEY UPDATE valor = '/opt/laesh/uploads/pdfs/';
SQL
    ok "Rutas de BD actualizadas para KVM2"
fi

# ════════════════════════════════════════════════════════════════
# FASE 5 — PHP-FPM pool (inyectar LAESH_APP_PASS)
# ════════════════════════════════════════════════════════════════
header "5/7 PHP-FPM pool"

POOL_SRC="${CONFIGS_DIR}/php-fpm-laesh.conf"
POOL_DST="/etc/php/8.3/fpm/pool.d/laesh.conf"

if [[ -f "${POOL_SRC}" ]]; then
    sed "s|__LAESH_APP_PASS__|${LAESH_APP_PASS}|g" "${POOL_SRC}" > "${POOL_DST}"
    # Deshabilitar pool www por defecto
    [[ -f /etc/php/8.3/fpm/pool.d/www.conf ]] && \
        mv /etc/php/8.3/fpm/pool.d/www.conf /etc/php/8.3/fpm/pool.d/www.conf.disabled 2>/dev/null || true
    # Verificar sintaxis y arrancar/recargar según estado actual
    if php-fpm8.3 -t 2>/dev/null; then
        if systemctl is-active --quiet "${PHP_FPM_SERVICE}"; then
            systemctl reload "${PHP_FPM_SERVICE}"
            ok "PHP-FPM pool recargado (LAESH_DB_PASS inyectada)"
        else
            systemctl start "${PHP_FPM_SERVICE}"
            ok "PHP-FPM pool iniciado (LAESH_DB_PASS inyectada)"
        fi
    else
        err "Error de sintaxis en PHP-FPM pool — verificar ${POOL_DST}"
    fi
else
    warn "php-fpm-laesh.conf no encontrado en ${CONFIGS_DIR}/ — PHP-FPM pool no actualizado"
fi

# ════════════════════════════════════════════════════════════════
# FASE 6 — Crons, logrotate, hardening (07_security_harden.sh)
# ════════════════════════════════════════════════════════════════
header "6/7 Crons, logrotate y hardening"

HARDEN_SCRIPT="${SCRIPT_DIR}/07_security_harden.sh"
if [[ -f "${HARDEN_SCRIPT}" ]]; then
    LAESH_APP_PASS="${LAESH_APP_PASS}" \
    LAESH_ROOT_PASS="" \
    LAESH_SMTP_PASS="${LAESH_SMTP_PASS:-}" \
    bash "${HARDEN_SCRIPT}" --skip-ssh
    ok "Hardening completado"
else
    warn "07_security_harden.sh no encontrado — instalar crons manualmente"
    # Fallback: instalar crons mínimos directamente
    CACHE_CRON_SRC="${LAESH_ROOT}/crones/cache_renew.cron"
    CMS_CRON_SRC="${LAESH_ROOT}/crones/cms-cleanup.cron"
    if [[ -f "${CACHE_CRON_SRC}" ]]; then
        sed "s/__LAESH_APP_PASS__/${LAESH_APP_PASS}/g" "${CACHE_CRON_SRC}" > /etc/cron.d/laesh-cache-renew
        chmod 640 /etc/cron.d/laesh-cache-renew
        ok "Cron cache_renew instalado (fallback)"
    fi
    if [[ -f "${CMS_CRON_SRC}" ]]; then
        sed "s/__LAESH_APP_PASS__/${LAESH_APP_PASS}/g" "${CMS_CRON_SRC}" > /etc/cron.d/laesh-cms-cleanup
        chmod 640 /etc/cron.d/laesh-cms-cleanup
        ok "Cron cms-cleanup instalado (fallback)"
    fi
fi

# ════════════════════════════════════════════════════════════════
# FASE 7 — Servicios y verificación
# ════════════════════════════════════════════════════════════════
header "7/7 Servicios y verificación"

# Swoole
systemctl daemon-reload
if systemctl is-enabled --quiet swoole-laesh 2>/dev/null; then
    systemctl restart swoole-laesh
    sleep 2
    systemctl is-active --quiet swoole-laesh \
        && ok "swoole-laesh activo" \
        || warn "swoole-laesh no activo — revisar: journalctl -u swoole-laesh -n 30"
else
    warn "swoole-laesh.service no está habilitado — verificar instalación del servicio"
fi

# Nginx
if nginx -t 2>/dev/null; then
    systemctl reload nginx
    ok "Nginx recargado"
else
    warn "nginx -t falló — sin recargar. Revisar config: nginx -t"
fi

# PHP-FPM ya recargado en fase 5
systemctl is-active --quiet "${PHP_FPM_SERVICE}" \
    && ok "${PHP_FPM_SERVICE} activo" \
    || warn "${PHP_FPM_SERVICE} no activo — revisar: systemctl status ${PHP_FPM_SERVICE}"

# Smoke test HTTP
sleep 1
HTTP_CODE="$(curl -sk https://127.0.0.1/ -w '%{http_code}' -o /dev/null --max-time 10 2>/dev/null || echo '000')"
if [[ "${HTTP_CODE}" =~ ^(200|301|302)$ ]]; then
    ok "HTTP ${HTTP_CODE} — sitio responde correctamente"
else
    warn "HTTP ${HTTP_CODE} — puede ser normal si Nginx está en Modo A (self-signed). Revisar servicios."
fi

# Verificar BD — resumen del seed
if ! $SKIP_BD; then
    echo ""
    log "Resumen de BD:"
    ${MCMD} laesh_db -e "
        SELECT 'Estudios' AS item, COUNT(*) AS total FROM catalogo_estudios
        UNION ALL
        SELECT 'Con descripcion_breve', COUNT(*) FROM catalogo_estudios WHERE descripcion_breve IS NOT NULL AND descripcion_breve != ''
        UNION ALL
        SELECT 'Usuarios', COUNT(*) FROM users
        UNION ALL
        SELECT 'ID-122 clave_interna', clave_interna FROM catalogo_estudios WHERE id = 122;
    " 2>/dev/null || warn "No se pudo consultar BD para resumen — verificar manualmente"
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  ✅ kvm2_setup.sh completado $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "  Usuarios demo:"
echo "    ADMIN      9990000001 / 04041980"
echo "    RECEPCIÓN  9990000002 / 04041981"
echo "    MÉDICO 1-5 9990000003-07 / 04041982-86"
echo ""
echo "  Verificación manual:"
echo "    curl -sk https://127.0.0.1/ -w '%{http_code}'"
echo "    systemctl status nginx ${PHP_FPM_SERVICE} swoole-laesh mariadb"
echo "══════════════════════════════════════════════════════════════"
