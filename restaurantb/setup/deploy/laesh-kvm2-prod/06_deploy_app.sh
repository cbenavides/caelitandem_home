#!/usr/bin/env bash
# ==============================================================================
# LAESH KVM2 · Paso 6 — Deploy Webapp + BD
#
# Requiere:
#   LAESH_ROOT_PASS   — contraseña root MariaDB
#   LAESH_APP_PASS    — contraseña laesh_app (producción)
#   LAESH_SRC_DIR     — directorio staging con código rsync'd
#                       (default: /home/sysadmin/laesh-src)
#
# Uso:
#   LAESH_ROOT_PASS='...' LAESH_APP_PASS='...' sudo -E bash 06_deploy_app.sh
#   LAESH_ROOT_PASS='...' LAESH_APP_PASS='...' sudo -E bash 06_deploy_app.sh --drop
#   LAESH_ROOT_PASS='...' LAESH_APP_PASS='...' sudo -E bash 06_deploy_app.sh --skip-bd
#
# Con --drop:    destruye y recrea la BD (solo en primera instalación).
# Con --skip-bd: omite pasos 6 y 6b — solo código + assets, BD intacta.
# Sin flags:     BD se preserva (idempotente) usando INSERT IGNORE.
# ==============================================================================
set -euo pipefail
[ "$EUID" -ne 0 ] && { echo "[ERROR] Requiere sudo"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  △${NC} $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; exit 1; }
log()  { echo "  → $*"; }

# ── Validar credenciales ───────────────────────────────────────────────────────
[[ -z "${LAESH_ROOT_PASS:-}" ]] && err "LAESH_ROOT_PASS no definida. Ejecutar: LAESH_ROOT_PASS='...' LAESH_APP_PASS='...' sudo -E bash $0"
[[ -z "${LAESH_APP_PASS:-}"  ]] && err "LAESH_APP_PASS no definida."

LAESH_SRC_DIR="${LAESH_SRC_DIR:-/home/sysadmin/laesh-src}"
DROP_DB=false; SKIP_BD=false
for _arg in "$@"; do
    case "$_arg" in
        --drop)    DROP_DB=true  ;;
        --skip-bd) SKIP_BD=true  ;;
    esac
done

export H_ROOT_PASS="${LAESH_ROOT_PASS}"
export H_APP_PASS="${LAESH_APP_PASS}"
export H_PHP_BIN="php8.3"
export H_WEB_DIR="/opt/laesh/www"

# ── 1. Verificar fuente ───────────────────────────────────────────────────────
echo "── 1/7 Verificar fuente de código ───────────────────────────"
[ -d "${LAESH_SRC_DIR}" ] || err "LAESH_SRC_DIR no existe: ${LAESH_SRC_DIR}. Subir el repo primero con rsync/scp."
[ -d "${LAESH_SRC_DIR}/laesh-swbldi" ] || err "No se encontró laesh-swbldi en ${LAESH_SRC_DIR}"
ok "Fuente: ${LAESH_SRC_DIR}"

# ── 2. rsync webapp ───────────────────────────────────────────────────────────
echo ""
echo "── 2/7 rsync webapp → /opt/laesh/www/ ───────────────────────"
rsync -av --delete \
    "${LAESH_SRC_DIR}/laesh-swbldi/" \
    /opt/laesh/www/laesh-swbldi/ \
    --exclude='.git' --exclude='vendor/' --exclude='*.log'
ok "laesh-swbldi sincronizado"

# ── 3. rsync assets ───────────────────────────────────────────────────────────
echo ""
echo "── 3/7 rsync assets → /opt/laesh/assets/ ────────────────────"
if [ -d "${LAESH_SRC_DIR}/laesh-web-assets-uipv1a" ]; then
    rsync -av --delete \
        "${LAESH_SRC_DIR}/laesh-web-assets-uipv1a/" \
        /opt/laesh/assets/laesh-web-assets-uipv1a/ \
        --exclude='.git' --exclude='cms/'
    # IMPORTANTE: --exclude='cms/' protege las imágenes subidas por el CMS
    # (hero slides, galería calidad, etc.) de ser eliminadas en cada deploy.
    ok "laesh-web-assets-uipv1a sincronizado"
else
    warn "laesh-web-assets-uipv1a no encontrado en ${LAESH_SRC_DIR} — omitiendo"
fi

# ── 4. Permisos ───────────────────────────────────────────────────────────────
echo ""
echo "── 4/7 Permisos ──────────────────────────────────────────────"
chown -R www-data:www-data /opt/laesh/www/
chown -R www-data:www-data /opt/laesh/assets/
chown -R www-data:www-data /opt/laesh/uploads/
chown -R www-data:www-data /opt/laesh/logs/
chmod 0750 /opt/laesh/www/
chmod 0755 /opt/laesh/assets/

# ── Directorio CMS imágenes (POST /cms/upload — admrc/index.php) ─────────────
# PHP usa finfo para validar MIME real (solo WebP, máx 135 KB).
# El path se configura en BD tabla 'configuraciones' (clave: cms_upload_dir).
# www-data necesita write: crear directorio antes de que PHP lo intente crear.
CMS_IMG_DIR="/opt/laesh/assets/laesh-web-assets-uipv1a/cms"
mkdir -p "$CMS_IMG_DIR"
chown www-data:www-data "$CMS_IMG_DIR"
chmod 0755 "$CMS_IMG_DIR"   # www-data escribe; Nginx lee; no 0777 en prod
ok "Directorio CMS imágenes: $CMS_IMG_DIR (0755 www-data)"

# ── Directorio PDFs resultados (POST /orden/subir-pdf — rc/index.php) ────────
PDF_DIR="/opt/laesh/uploads/pdfs"
mkdir -p "$PDF_DIR"
chown www-data:www-data "$PDF_DIR"
chmod 0750 "$PDF_DIR"   # www-data escribe; Nginx sirve via PHP (internal location)
ok "Directorio PDFs: $PDF_DIR (0750 www-data)"

# ── Directorio fallback PDF (rc/index.php hardcoded path) ────────────────────
# rc/index.php línea ~330: fallback = __DIR__ . '/../uploads/resultados/'
# Resuelve a: /opt/laesh/www/laesh-swbldi/uploads/resultados/
# Se activa solo si la lectura de BD falla (BD valor=/opt/laesh/uploads/pdfs/).
# Crear para resiliencia: si BD no responde, los PDFs aún tienen destino válido.
PDF_FALLBACK_DIR="/opt/laesh/www/laesh-swbldi/uploads/resultados"
mkdir -p "$PDF_FALLBACK_DIR"
chown www-data:www-data "$PDF_FALLBACK_DIR"
chmod 0750 "$PDF_FALLBACK_DIR"
ok "Directorio PDFs (fallback PHP): $PDF_FALLBACK_DIR (0750 www-data)"

# ── Directorio Caché L2 — OPcache File Store ─────────────────────────────────
# Cache.php escribe aquí archivos .php que OPcache compila a bytecode.
# CRÍTICO: usar /opt/laesh/cache/ (NO /tmp) porque php8.3-fpm.service tiene
# PrivateTmp=true en Ubuntu 24.04 → su /tmp es un namespace aislado.
# El cron cache_renew.php y PHP-FPM deben ver el MISMO directorio físico.
# Ambos usan env var LAESH_CACHE_DIR=/opt/laesh/cache:
#   - FPM: inyectado en php-fpm-laesh.conf (env[LAESH_CACHE_DIR])
#   - Cron: inyectado en /etc/cron.d/laesh-cache-renew (var global del archivo)
CACHE_DIR="/opt/laesh/cache"
mkdir -p "$CACHE_DIR"
chown www-data:www-data "$CACHE_DIR"
chmod 0750 "$CACHE_DIR"   # solo www-data (FPM + cron corren como www-data)
ok "Directorio Caché L2: $CACHE_DIR (0750 www-data)"

# Logs: nginx y php-fpm corren como www-data; Swoole como www-data también
ok "Permisos aplicados"

# ── 5. Composer install ───────────────────────────────────────────────────────
echo ""
echo "── 5/7 Composer install (laesh-swbldi) ──────────────────────"
cd /opt/laesh/www/laesh-swbldi
if [ -f "composer.json" ]; then
    sudo -u www-data composer install \
        --no-dev \
        --optimize-autoloader \
        --no-interaction \
        2>&1 | tail -10
    ok "Composer dependencies instaladas"
else
    warn "composer.json no encontrado en /opt/laesh/www/laesh-swbldi — omitiendo"
fi
cd - > /dev/null

# ── 6. Setup BD (setup_hostinger.sh) ─────────────────────────────────────────
echo ""
echo "── 6/7 Inicializar BD con setup_hostinger.sh ────────────────"
if $SKIP_BD; then
    warn "Paso 6 omitido (--skip-bd): BD no modificada."
else
    BDS_DIR="${LAESH_SRC_DIR}/setup/bds/laesh"   # ruta canónica (rsync de setup/bds/laesh/)
    if [ ! -d "${BDS_DIR}" ]; then
        # Fallback: estructura plana (transfer directo, sin la carpeta setup/)
        BDS_DIR="${LAESH_SRC_DIR}/bds"
    fi
    [ -f "${BDS_DIR}/setup_hostinger.sh" ] || err "setup_hostinger.sh no encontrado en ${BDS_DIR}"

    DROP_FLAG=""
    $DROP_DB && DROP_FLAG="--drop"
    H_ROOT_PASS="${LAESH_ROOT_PASS}" \
    H_APP_PASS="${LAESH_APP_PASS}" \
    H_PHP_BIN="php8.3" \
    H_WEB_DIR="/opt/laesh/www" \
    bash "${BDS_DIR}/setup_hostinger.sh" ${DROP_FLAG}
    ok "BD inicializada"
fi

# ── 6b. Corregir rutas de BD dependientes del entorno ─────────────────────────
# El seed SQL usa rutas Docker (/var/www/html/...) que no existen en KVM2.
# Se actualizan aquí a las rutas reales de producción Hostinger.
# Omitido si --skip-bd (usa ON DUPLICATE KEY UPDATE, pero para consistencia no tocamos BD).
if $SKIP_BD; then
    warn "Paso 6b omitido (--skip-bd): rutas de BD no modificadas."
else
    echo "    → Actualizando rutas de configuración en BD..."
    # Usar .mariadb-root.cnf (creado en paso 4 si LAESH_ROOT_PASS estaba definida)
    # Fallback: -p directo con LAESH_ROOT_PASS si el archivo no existe aún.
    _MARIADB_OPTS=""
    if [ -f /opt/laesh/configs/.mariadb-root.cnf ]; then
        _MARIADB_OPTS="--defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf"
    elif [[ -n "${LAESH_ROOT_PASS:-}" ]]; then
        _MARIADB_OPTS="-u root -p${LAESH_ROOT_PASS}"
    fi
    mariadb ${_MARIADB_OPTS} laesh_db <<'SQL'
-- Directorio físico donde admrc/index.php guarda imágenes CMS (POST /cms/upload)
-- Antes (Docker): /var/www/html/laesh-web-assets-uipv1a/img/cms/
-- Ahora (KVM2):   /opt/laesh/assets/laesh-web-assets-uipv1a/cms/
INSERT INTO configuraciones (clave, valor, descripcion)
  VALUES ('cms_upload_dir', '/opt/laesh/assets/laesh-web-assets-uipv1a/cms/', 'Directorio físico para uploads CMS imágenes')
  ON DUPLICATE KEY UPDATE valor = '/opt/laesh/assets/laesh-web-assets-uipv1a/cms/';

-- Endpoint público para el upload de imágenes CMS (desde gestion_web.php meta tag)
INSERT INTO configuraciones (clave, valor, descripcion)
  VALUES ('cms_upload_endpoint', '/adrc/cms/upload', 'Endpoint POST subida imágenes CMS')
  ON DUPLICATE KEY UPDATE valor = '/adrc/cms/upload';
  -- URL raíz: la app se sirve en / desde 2026-09-05 (sin prefijo /laesh/)

-- Directorio físico donde rc/index.php guarda PDFs de resultados
-- Antes (Docker): /var/www/html/laesh-bloc-assets/pdf/
-- Ahora (KVM2):   /opt/laesh/uploads/pdfs/
INSERT INTO configuraciones (clave, valor, descripcion)
  VALUES ('ruta_almacenamiento_pdf', '/opt/laesh/uploads/pdfs/', 'Directorio físico para PDFs de resultados')
  ON DUPLICATE KEY UPDATE valor = '/opt/laesh/uploads/pdfs/';
SQL
    ok "Rutas de BD actualizadas para entorno KVM2"
fi

# ── 7. Swoole service ─────────────────────────────────────────────────────────
echo ""
echo "── 7/7 Arrancar swoole-laesh.service ────────────────────────"
systemctl daemon-reload
systemctl restart swoole-laesh
sleep 2
systemctl is-active --quiet swoole-laesh \
    && ok "swoole-laesh activo" \
    || { warn "swoole-laesh no activo — verificar log: journalctl -u swoole-laesh -n 50"; }

# Verificación rápida del bridge HTTP
sleep 1
STATUS=$(curl -sf http://127.0.0.1:9502/status 2>/dev/null || echo "")
if echo "$STATUS" | grep -q '"status":"online"'; then
    CLIENTS=$(echo "$STATUS" | python3 -c "import sys,json; print(json.load(sys.stdin)['clients_connected'])" 2>/dev/null || echo "?")
    ok "Swoole HTTP bridge OK — clients_connected: ${CLIENTS}"
else
    warn "Swoole /status no responde aún (normal si el proceso arranca lento)"
fi

echo ""
ok "Deploy completo"
echo ""
echo "  Usuarios demo (CAMBIAR antes de entregar al cliente):"
echo "    ADMIN     9990000001  04041980"
echo "    RECEPCIÓN 9990000002  04041981"
echo "    MÉDICO 1  9990000003  04041982"
echo "    MÉDICO 2  9990000004  04041983"
echo "    MÉDICO 3  9990000005  04041984"
echo "    MÉDICO 4  9990000006  04041985"
echo "    MÉDICO 5  9990000007  04041986"
