#!/usr/bin/env bash
# ==============================================================================
#  deploy_oci_laesh.sh — Deploy completo LAESH → OCI VM
#
#  Cubre los 6 componentes del stack:
#    1. Infra Docker (nginx.conf + docker-compose) via contenedor/oci-vm/deploy.sh
#    2. Web assets JS/CSS (laesh-web-assets-uipv1a/)
#    3. Webapp PHP (laesh-swbldi/, excluyendo SSOT HTML y logs/)
#    4. Libs PHP compartidas (restaurant/commons/libs/ — Delight-Auth, Flight, Plates)
#    5. BD: re-aplica schema idempotente + seed usuarios (setup_oci.sh SIN --drop)
#    6. Nginx nativo OCI reload + permisos logs/ + suite de pruebas
#
#  Uso:
#    bash setup/deploy/deploy_oci_laesh.sh              # deploy completo
#    bash setup/deploy/deploy_oci_laesh.sh --skip-db    # omite paso BD (solo archivos)
#    bash setup/deploy/deploy_oci_laesh.sh --skip-test  # omite suite de pruebas
#    bash setup/deploy/deploy_oci_laesh.sh --test-only  # solo corre la suite de pruebas
#
#  Ejecutar desde el root del repo restaurantb/:
#    cd /home/carlos/GitHub/caelitandem_home/restaurantb
#    bash setup/deploy/deploy_oci_laesh.sh
#
#  Gaps corregidos (2026-08-25):
#    G1 — setup_oci.sh: ruta y entorno corregidos para ejecutar en OCI
#    G2 — env vars BD: verifica LAESH_DB_PASS en PHP-FPM pool antes de continuar
#    G3 — logs/: crea directorio + permisos escritura en OCI
#    G4 — --delete laesh-swbldi: protege logs/ de ser borrado
#    G5 — healthcheck laesh_db: espera contenedor healthy antes de correr setup_oci.sh
#    G6 — nginx nativo OCI: recarga después de subir archivos
#    G7 — php8.1: verifica binario disponible en OCI antes del paso BD
# ==============================================================================

set -euo pipefail

# ── Configuración ─────────────────────────────────────────────────────────────
OCI_HOST="ubuntu@oci-vm"
OCI_WWW="/home/ubuntu/laesh-stack/www"
OCI_STACK_DIR="/home/ubuntu/laesh-stack"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"          # restaurantb/
LOCAL_WWW="${REPO_ROOT}/www"

SKIP_DB=false
SKIP_TEST=false
TEST_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --skip-db)   SKIP_DB=true ;;
        --skip-test) SKIP_TEST=true ;;
        --test-only) TEST_ONLY=true ;;
        *) echo "[WARN] Argumento desconocido: $arg" ;;
    esac
done

# ── Colores ───────────────────────────────────────────────────────────────────
GREEN="\e[32m✅\e[0m"
RED="\e[31m❌\e[0m"
YELLOW="\e[33m⚠\e[0m"
BLUE="\e[34m──\e[0m"

step()  { echo -e "\n\e[1;34m$BLUE $1\e[0m"; }
ok()    { echo -e "  ${GREEN} $1"; }
warn()  { echo -e "  ${YELLOW}  $1"; }
fail()  { echo -e "  ${RED} $1"; exit 1; }

# ── Helpers ───────────────────────────────────────────────────────────────────

# Espera a que el contenedor laesh_db reporte status=healthy (G5)
wait_db_healthy() {
    local max_wait=120   # segundos máximo
    local interval=10
    local elapsed=0
    echo "  → Esperando laesh_db healthy (máx ${max_wait}s)..."
    while true; do
        STATUS=$(ssh "${OCI_HOST}" \
            "docker inspect --format='{{.State.Health.Status}}' laesh_db 2>/dev/null || echo 'missing'")
        case "$STATUS" in
            healthy) ok "laesh_db healthy"; return 0 ;;
            missing) fail "Contenedor laesh_db no encontrado en OCI" ;;
        esac
        if (( elapsed >= max_wait )); then
            fail "laesh_db no alcanzó healthy en ${max_wait}s (último status: ${STATUS})"
        fi
        echo "    [${elapsed}s] status=${STATUS} — reintentando en ${interval}s..."
        sleep $interval
        elapsed=$((elapsed + interval))
    done
}

# ==============================================================================
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  Deploy LAESH → OCI VM"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "══════════════════════════════════════════════════════════"

# ── Modo --test-only ──────────────────────────────────────────────────────────
if $TEST_ONLY; then
    step "Suite de pruebas (--test-only)"
    BASE=https://caelitandem.lat bash "${REPO_ROOT}/setup/bds/laesh/bash/03_test_deploy.sh"
    exit $?
fi

# ── Paso 1: Infra Docker (nginx.conf + docker-compose) ───────────────────────
step "1/7  Infra Docker (nginx.conf + docker-compose up)"
DEPLOY_SH="${REPO_ROOT}/contenedor/oci-vm/deploy.sh"
[[ -f "${DEPLOY_SH}" ]] || fail "No encontrado: contenedor/oci-vm/deploy.sh"
bash "${DEPLOY_SH}"
ok "Stack Docker desplegado"

# ── Paso 2: Crear directorios en OCI (evita error rsync "No such file") ───────
step "2/7  Preparando directorios en OCI"
ssh "${OCI_HOST}" "
    mkdir -p \
        ${OCI_WWW}/laesh-web-assets-uipv1a \
        ${OCI_WWW}/laesh-swbldi/logs \
        ${OCI_WWW}/restaurant/commons/libs
"
ok "Directorios creados / verificados"

# ── Paso 3: Web assets JS/CSS ─────────────────────────────────────────────────
step "3/7  Web assets (laesh-web-assets-uipv1a/)"
rsync -avz --delete \
    "${LOCAL_WWW}/laesh-web-assets-uipv1a/" \
    "${OCI_HOST}:${OCI_WWW}/laesh-web-assets-uipv1a/"
ok "Web assets sincronizados"

# ── Paso 4: Webapp PHP ────────────────────────────────────────────────────────
step "4/7  Webapp PHP (laesh-swbldi/)"
# Excluye: uipv0, uipv1, uipv2 (SSOT HTML — nunca van a producción)
# Protege: logs/ en OCI (G4 — --delete no borra app.log ni futuros uploads)
rsync -avz --delete \
    --exclude='website/uipv0/' \
    --exclude='website/uipv1/' \
    --exclude='website/uipv2/' \
    --filter='protect logs/' \
    "${LOCAL_WWW}/laesh-swbldi/" \
    "${OCI_HOST}:${OCI_WWW}/laesh-swbldi/"
ok "Webapp PHP sincronizada"

# ── Paso 5: Libs PHP compartidas (Delight-Auth, Flight, Plates) ──────────────
# autoload.php resuelve desde ../../restaurant/commons/libs — ruta relativa fija
step "5/7  Libs PHP compartidas (restaurant/commons/libs/)"
LIBS_LOCAL="${LOCAL_WWW}/restaurant/commons/libs"
[[ -d "${LIBS_LOCAL}" ]] || fail "No encontrado localmente: www/restaurant/commons/libs/"
rsync -avz --checksum \
    "${LIBS_LOCAL}/" \
    "${OCI_HOST}:${OCI_WWW}/restaurant/commons/libs/"
ok "Libs PHP compartidas sincronizadas"

# ── Paso 6: Permisos de logs/ + nginx nativo OCI reload ──────────────────────
step "6/7  Permisos logs/ + nginx nativo OCI reload"

# G3 — garantizar escritura en logs/app.log para el proceso PHP-FPM
ssh "${OCI_HOST}" "
    touch ${OCI_WWW}/laesh-swbldi/logs/app.log
    chmod 775 ${OCI_WWW}/laesh-swbldi/logs
    chmod 664 ${OCI_WWW}/laesh-swbldi/logs/app.log
    # www-data o ubuntu según el pool — ambos deben poder escribir
    chown -R ubuntu:www-data ${OCI_WWW}/laesh-swbldi/logs 2>/dev/null || \
    chown -R ubuntu:ubuntu   ${OCI_WWW}/laesh-swbldi/logs
"
ok "Permisos logs/ aplicados"

# G6 — recargar nginx nativo (no el Docker; el PHP es nativo en OCI)
ssh "${OCI_HOST}" "sudo nginx -t && sudo nginx -s reload" \
    && ok "Nginx nativo recargado" \
    || warn "nginx reload falló — revisar config en OCI (sudo nginx -t)"

# G2 — verificar que PHP-FPM ve LAESH_DB_PASS (env var de producción)
ssh "${OCI_HOST}" "
    PHP_BIN=\$(which php8.1 2>/dev/null || which php 2>/dev/null || echo '')
    [[ -z \"\$PHP_BIN\" ]] && { echo '[WARN] php no encontrado en PATH de OCI'; exit 0; }
    DB_PASS=\$(\$PHP_BIN -r \"echo getenv('LAESH_DB_PASS');\" 2>/dev/null || echo '')
    if [[ -z \"\$DB_PASS\" ]]; then
        echo '  [WARN] LAESH_DB_PASS no está en el entorno del proceso PHP.'
        echo '         config.php usará el fallback: laesh_2026_dev (contraseña dev).'
        echo '         Agregar env[LAESH_DB_PASS] al pool PHP-FPM si la BD usa otra contraseña.'
    else
        echo '  ✅ LAESH_DB_PASS detectado en entorno PHP'
    fi
" || true  # no fatal — solo informativo

# ── Paso 7: BD — schema idempotente + seed (SIN --drop) ──────────────────────
if $SKIP_DB; then
    echo -e "\n  [SKIP] BD omitida por --skip-db"
else
    step "7/7  BD — setup_oci.sh (idempotente, sin DROP)"

    # G7 — verificar php8.1 disponible antes de continuar
    ssh "${OCI_HOST}" "which php8.1 > /dev/null 2>&1" \
        || fail "php8.1 no encontrado en OCI. Instalar: sudo apt install php8.1-cli"

    # G5 — esperar laesh_db healthy antes de correr setup_oci.sh
    wait_db_healthy

    # G1 — setup_oci.sh se ejecuta desde OCI_STACK_DIR donde viven los archivos SQL
    #       (deploy.sh ya copió setup/bds/laesh/ a $OCI_STACK_DIR/setup/bds/laesh/)
    # G2 — OCI_APP_PASS se pasa explícito; setup_oci.sh lo usa en ALTER USER y en
    #       seed_first_users.php (vía LAESH_DB_PASS). El CLI no hereda las env vars
    #       del pool PHP-FPM, por lo que sin esto seed falla con contraseña incorrecta.
    ssh "${OCI_HOST}" "
        set -euo pipefail
        cd ${OCI_STACK_DIR}
        [[ -f setup/bds/laesh/setup_oci.sh ]] \
            || { echo 'ERROR: setup_oci.sh no encontrado — correr deploy.sh primero'; exit 1; }
        OCI_WEB_DIR=${OCI_WWW} \
        OCI_APP_PASS=laesh_oci_app_2026 \
        bash setup/bds/laesh/setup_oci.sh
    "
    ok "BD schema + seed aplicados"
fi

# ── Paso 8: Suite de pruebas ──────────────────────────────────────────────────
if $SKIP_TEST; then
    echo -e "\n  [SKIP] Suite de pruebas omitida por --skip-test"
else
    step "8/7  Suite de pruebas post-deploy"
    BASE=https://caelitandem.lat bash "${REPO_ROOT}/setup/bds/laesh/bash/03_test_deploy.sh"
fi

echo ""
echo "══════════════════════════════════════════════════════════"
echo "  ✅ Deploy completado — $(date '+%H:%M:%S')"
echo "  URL: https://caelitandem.lat/laesh/"
echo "══════════════════════════════════════════════════════════"
echo ""
