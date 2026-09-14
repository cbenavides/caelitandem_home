#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# full_install.sh — Instalación completa LAESH Bloc Digital en KVM2
#
# Orquestador LOCAL: sincroniza código, escribe secrets en KVM2 y lanza
# kvm2_setup.sh en el servidor para configurar BD, permisos, crons y servicios.
#
# PREREQUISITOS:
#   1. Alias SSH "laesh-kvm2" configurado en ~/.ssh/config
#   2. SECRETS.env en este mismo directorio (copiar de SECRETS.env.example)
#      con LAESH_APP_PASS real
#   3. Stack ya instalado en KVM2 (Nginx, PHP-FPM, MariaDB, Swoole)
#      Si es instalación fresca de SO: correr pipeline 01–05 primero
#
# USO (desde raíz del repo restaurantb/):
#   bash setup/deploy/laesh-kvm2-prod/full_install.sh --drop
#   bash setup/deploy/laesh-kvm2-prod/full_install.sh --skip-bd   # solo código
#
# FLAGS:
#   --drop     Destruye y recrea laesh_db (primera instalación o reset total)
#   --skip-bd  Solo sincroniza código y assets; no toca la BD
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# ── Colores ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()     { echo -e "${GREEN}  ✓${NC} $*"; }
warn()   { echo -e "${YELLOW}  △${NC} $*"; }
err()    { echo -e "${RED}  ✗ ERROR:${NC} $*" >&2; exit 1; }
header() { echo -e "\n${CYAN}══ $* ══${NC}"; }

# ── Cargar rutas canónicas ────────────────────────────────────────────────────
source "${SCRIPT_DIR}/SERVER_MAP.env"

# ── Cargar credenciales ───────────────────────────────────────────────────────
SECRETS_FILE="${SCRIPT_DIR}/SECRETS.env"
if [[ ! -f "${SECRETS_FILE}" ]]; then
    err "SECRETS.env no encontrado en ${SCRIPT_DIR}/\n\
        Crear desde la plantilla:\n\
          cp ${SCRIPT_DIR}/SECRETS.env.example ${SCRIPT_DIR}/SECRETS.env\n\
          chmod 600 ${SCRIPT_DIR}/SECRETS.env\n\
        Luego editar LAESH_APP_PASS con la contraseña real."
fi
# shellcheck source=SECRETS.env
source "${SECRETS_FILE}"

# Validar
[[ -z "${LAESH_APP_PASS:-}" ]] && err "LAESH_APP_PASS vacía en SECRETS.env — editar con contraseña real."
[[ "${LAESH_APP_PASS}" == "cambiarme-antes-de-deploy-2026!" ]] && \
    err "LAESH_APP_PASS tiene el valor por defecto de la plantilla — cambiar a contraseña real."

# ── Flags ─────────────────────────────────────────────────────────────────────
DROP_FLAG=""; SKIP_BD_FLAG=""
for _arg in "$@"; do
    case "$_arg" in
        --drop)    DROP_FLAG="--drop"    ;;
        --skip-bd) SKIP_BD_FLAG="--skip-bd" ;;
    esac
done

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  LAESH Bloc Digital — Instalación Completa KVM2"
echo "  Servidor: ${KVM2_SSH} ($(ssh "${KVM2_SSH}" hostname 2>/dev/null || echo '?'))"
echo "  Modo:     ${DROP_FLAG:-idempotente} ${SKIP_BD_FLAG}"
echo "  Hora:     $(date '+%Y-%m-%d %H:%M:%S')"
echo "══════════════════════════════════════════════════════════════"

# ── 1. Verificar raíz del repo ────────────────────────────────────────────────
header "1/6 Verificar repo local"
[[ -d "${REPO_ROOT}/www/laesh-swbldi" ]]          || err "www/laesh-swbldi no encontrado en ${REPO_ROOT}"
[[ -d "${REPO_ROOT}/www/laesh-web-assets-uipv1a" ]] || err "www/laesh-web-assets-uipv1a no encontrado en ${REPO_ROOT}"
[[ -f "${REPO_ROOT}/setup/bds/laesh/07_seed_catalogs.sql" ]] || err "07_seed_catalogs.sql no encontrado"
ok "Repo local verificado: ${REPO_ROOT}"

# ── 2. Escribir secrets en KVM2 ──────────────────────────────────────────────
header "2/6 Escribir /opt/laesh/configs/.env en KVM2"
# Crear /opt/laesh/configs/ si no existe (primera instalación)
ssh "${KVM2_SSH}" "sudo mkdir -p /opt/laesh/configs"
# Escribir .env con 600 root:root
ssh "${KVM2_SSH}" "sudo bash -c 'cat > /opt/laesh/configs/.env'" <<ENV
# LAESH production secrets — escrito por full_install.sh $(date '+%Y-%m-%d %H:%M:%S')
# 600 root:root — NO editar manualmente; re-correr full_install.sh
LAESH_APP_PASS=${LAESH_APP_PASS}
LAESH_SMTP_PASS=${LAESH_SMTP_PASS:-}
ENV
ssh "${KVM2_SSH}" "sudo chmod 600 /opt/laesh/configs/.env && sudo chown root:root /opt/laesh/configs/.env"
ok "/opt/laesh/configs/.env escrito (600 root:root)"

# ── 3. Sincronizar código ─────────────────────────────────────────────────────
header "3/6 Sincronizar código → KVM2"
cd "${REPO_ROOT}"
bash "${SCRIPT_DIR}/deploy.sh" webapp
bash "${SCRIPT_DIR}/deploy.sh" scripts
ok "webapp y scripts sincronizados"

# ── 4. Sincronizar assets (staging → prod) ────────────────────────────────────
header "4/6 Sincronizar assets → KVM2 (staging + publish)"
bash "${SCRIPT_DIR}/deploy.sh" assets
bash "${SCRIPT_DIR}/deploy.sh" assets-publish
ok "assets sincronizados a producción"

# ── 5. Ejecutar kvm2_setup.sh en servidor ────────────────────────────────────
header "5/6 Ejecutar kvm2_setup.sh en KVM2"
KVM2_SETUP_SCRIPT="${KVM2_SETUP_DIR}/deploy/laesh-kvm2-prod/kvm2_setup.sh"
# Verificar que el script llegó a KVM2 via deploy.sh scripts
ssh "${KVM2_SSH}" "test -f ${KVM2_SETUP_SCRIPT}" \
    || err "kvm2_setup.sh no encontrado en KVM2 (${KVM2_SETUP_SCRIPT}). Verificar deploy scripts."

ssh "${KVM2_SSH}" "sudo bash ${KVM2_SETUP_SCRIPT} ${DROP_FLAG} ${SKIP_BD_FLAG}"

# ── 6. Verificación rápida ────────────────────────────────────────────────────
header "6/6 Verificación rápida"
HTTP_CODE=$(ssh "${KVM2_SSH}" "curl -sk https://127.0.0.1/ -w '%{http_code}' -o /dev/null --max-time 10" 2>/dev/null || echo "000")
if [[ "${HTTP_CODE}" =~ ^(200|301|302)$ ]]; then
    ok "HTTP ${HTTP_CODE} — sitio responde"
else
    warn "HTTP ${HTTP_CODE} — revisar servicios: sudo systemctl status nginx php8.3-fpm swoole-laesh"
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  ✅ full_install.sh completado $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "  Usuarios demo:"
echo "    ADMIN      9990000001 / 04041980"
echo "    RECEPCIÓN  9990000002 / 04041981"
echo "    MÉDICO 1-5 9990000003-07 / 04041982-86"
echo ""
echo "  Siguiente: subir imágenes CMS en https://laesh.mx/adrc/"
echo "══════════════════════════════════════════════════════════════"
