#!/usr/bin/env bash
# ==============================================================================
#  deploy_oci_laesh.sh — Deploy LAESH → VM OCI (AMBIENTE DE PRUEBAS)
#
#  Producción vive en KVM2 (setup/deploy/laesh-kvm2-prod/deploy.sh). La VM OCI
#  (Ubuntu 22.04 ARM64, https://caelitandem.lat/laesh/) se reutiliza como ambiente
#  de pruebas con su stack ya existente — nginx + php8.1-fpm nativos y MariaDB en
#  Docker (contenedor/oci-vm/docker-compose.yml) — sin reinstalar nada.
#
#  Pasos:
#    1. Infra Docker (solo con --infra): contenedor/oci-vm/deploy.sh
#    2. Sincroniza pipeline OCI (bootstrap + snippet nginx) y scripts BD
#    3. Assets  laesh-web-assets-uipv1a/ (protege cms/ subidos en OCI)
#    4. Webapp  laesh-swbldi/ (libs vendorizadas incluidas; sin tests/, logs/, uploads/)
#    5. Bootstrap del host (idempotente): /opt/laesh/*, pool env, nginx PDFs
#    6. BD: setup_oci.sh  (sin --drop = solo migraciones; --drop = reconstruye)
#    7. Suite 03_test_deploy.sh contra https://caelitandem.lat
#
#  Uso (desde la raíz de restaurantb/):
#    bash setup/deploy/deploy_oci_laesh.sh              # código + migraciones
#    bash setup/deploy/deploy_oci_laesh.sh --drop       # + reconstruye la BD de pruebas
#    bash setup/deploy/deploy_oci_laesh.sh --infra      # + docker compose (contenedor/oci-vm/.env)
#    bash setup/deploy/deploy_oci_laesh.sh --skip-db    # solo archivos
#    bash setup/deploy/deploy_oci_laesh.sh --skip-test  # sin suite final
#    bash setup/deploy/deploy_oci_laesh.sh --test-only  # solo la suite
#
#  2026-10-01 — reactivado como ambiente de pruebas:
#    • Libs: ya no se copian de restaurant/commons/libs (ruta muerta); viajan
#      dentro de laesh-swbldi/libs/ como en KVM2.
#    • BD: setup_oci.sh ya no corre 00_database.sql (DROP DATABASE) sin --drop.
#    • contenedor/oci-vm/deploy.sh ya no borra www/ ni hace `docker compose pull`.
#    • Host: bootstrap_oci_laesh.sh cubre las rutas /opt/laesh/* que el código
#      asume, JWT secret en el pool y la ruta interna de PDFs en nginx.
# ==============================================================================

set -euo pipefail

OCI_HOST="ubuntu@oci-vm"
OCI_STACK_DIR="/home/ubuntu/laesh-stack"
OCI_WWW="${OCI_STACK_DIR}/www"
OCI_URL="https://caelitandem.lat"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOCAL_WWW="${REPO_ROOT}/www"
OCI_VM_DIR="${REPO_ROOT}/contenedor/oci-vm"

DROP=""; INFRA=false; SKIP_DB=false; SKIP_TEST=false; TEST_ONLY=false
for arg in "$@"; do
    case "$arg" in
        --drop)      DROP="--drop" ;;
        --infra)     INFRA=true ;;
        --skip-db)   SKIP_DB=true ;;
        --skip-test) SKIP_TEST=true ;;
        --test-only) TEST_ONLY=true ;;
        *) echo "[ERROR] Argumento desconocido: $arg"; exit 1 ;;
    esac
done

step() { echo -e "\n\e[1;34m── $1\e[0m"; }
ok()   { echo -e "  \e[32m✓\e[0m $1"; }
fail() { echo -e "  \e[31m✗\e[0m $1"; exit 1; }

run_tests() { BASE="${OCI_URL}" bash "${REPO_ROOT}/setup/bds/laesh/bash/verify/03_test_deploy.sh"; }

echo "══════════════════════════════════════════════════════════"
echo "  Deploy LAESH → VM OCI (pruebas)  $(date '+%Y-%m-%d %H:%M:%S')"
echo "══════════════════════════════════════════════════════════"

if $TEST_ONLY; then step "Suite de pruebas (--test-only)"; run_tests; exit $?; fi

ssh -o ConnectTimeout=10 "${OCI_HOST}" true 2>/dev/null || fail "Sin SSH a ${OCI_HOST}"

# ── 1. Infra Docker (opcional) ────────────────────────────────────────────────
if $INFRA; then
    step "1/7  Infra Docker (contenedor/oci-vm/deploy.sh)"
    bash "${OCI_VM_DIR}/deploy.sh"
    ok "docker compose up"
else
    step "1/7  Infra Docker — omitida (usar --infra para docker compose)"
fi

# ── 2. Pipeline OCI + scripts BD ──────────────────────────────────────────────
step "2/7  Pipeline OCI y scripts BD"
ssh "${OCI_HOST}" "mkdir -p ${OCI_STACK_DIR}/conf ${OCI_STACK_DIR}/setup/bds/laesh ${OCI_WWW}"
rsync -az --checksum \
    "${OCI_VM_DIR}/bootstrap_oci_laesh.sh" \
    "${OCI_HOST}:${OCI_STACK_DIR}/"
rsync -az --checksum \
    "${OCI_VM_DIR}/conf/nginx-laesh-oci-extra.conf" \
    "${OCI_HOST}:${OCI_STACK_DIR}/conf/"
rsync -az --checksum --delete \
    --exclude='bash/docker-local/' \
    "${REPO_ROOT}/setup/bds/laesh/" \
    "${OCI_HOST}:${OCI_STACK_DIR}/setup/bds/laesh/"
ok "bootstrap, snippet nginx y setup/bds/laesh sincronizados"

# ── 3. Assets ─────────────────────────────────────────────────────────────────
step "3/7  Assets (laesh-web-assets-uipv1a/)"
# 'P cms/**': imágenes subidas desde el CMS de OCI no se borran con --delete.
rsync -az --checksum --delete \
    --filter='P cms/**' \
    "${LOCAL_WWW}/laesh-web-assets-uipv1a/" \
    "${OCI_HOST}:${OCI_WWW}/laesh-web-assets-uipv1a/"
ok "assets sincronizados"

# ── 4. Webapp PHP ─────────────────────────────────────────────────────────────
step "4/7  Webapp (laesh-swbldi/)"
# Mismas exclusiones que KVM2: tests/ no viaja (PEN-LAESH-05), logs/ y uploads/
# viven en /opt/laesh/ (bootstrap).
rsync -az --checksum --delete \
    --exclude='tests/' \
    --exclude='logs/' \
    --exclude='uploads/' \
    "${LOCAL_WWW}/laesh-swbldi/" \
    "${OCI_HOST}:${OCI_WWW}/laesh-swbldi/"
ok "webapp sincronizada"

# ── 5. Bootstrap del host ─────────────────────────────────────────────────────
step "5/7  Bootstrap host OCI (idempotente)"
ssh "${OCI_HOST}" "sudo bash ${OCI_STACK_DIR}/bootstrap_oci_laesh.sh"

# ── 6. BD ─────────────────────────────────────────────────────────────────────
if $SKIP_DB; then
    step "6/7  BD — omitida (--skip-db)"
else
    step "6/7  BD — setup_oci.sh ${DROP:-(sin --drop: solo migraciones)}"
    ssh "${OCI_HOST}" "sudo bash ${OCI_STACK_DIR}/setup/bds/laesh/setup_oci.sh ${DROP}"
    ok "BD lista"
fi

# ── 7. Suite ──────────────────────────────────────────────────────────────────
if $SKIP_TEST; then
    step "7/7  Suite — omitida (--skip-test)"
else
    step "7/7  Suite post-deploy (${OCI_URL})"
    run_tests || true
fi

echo ""
echo "══════════════════════════════════════════════════════════"
echo "  ✅ Deploy OCI completado — ${OCI_URL}/laesh/"
echo "  Sin WebSocket en OCI: notificaciones por polling (ver bootstrap)."
echo "══════════════════════════════════════════════════════════"
