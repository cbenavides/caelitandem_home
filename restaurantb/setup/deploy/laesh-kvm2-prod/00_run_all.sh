#!/usr/bin/env bash
# ==============================================================================
# LAESH Bloc Digital v1.2 — Orquestador del Pipeline de Instalación
# Hostinger KVM2 · Ubuntu 24.04 LTS · Stack Nativo
#
# Uso:
#   sudo bash 00_run_all.sh                        # completo, Modo A (IP/self-signed)
#   sudo LAESH_DOMAIN=laesh.mx bash 00_run_all.sh  # completo, Modo B (LE)
#   sudo bash 00_run_all.sh --from=4               # reanudar desde paso 4
#   sudo bash 00_run_all.sh --only=3               # solo paso 3
#   sudo bash 00_run_all.sh --skip=5               # saltar TLS (deploy sin dominio)
#
# Variables de entorno:
#   LAESH_DOMAIN        Dominio (vacío = Modo A IP/self-signed)
#   LAESH_ADMIN_EMAIL   Email para certbot (default: cbena999@gmail.com)
#   LAESH_ROOT_PASS     Contraseña root MariaDB (REQUERIDA en paso 6)
#   LAESH_APP_PASS      Contraseña laesh_app MariaDB (REQUERIDA en paso 6)
#   LAESH_SMTP_PASS     App-password Yahoo SMTP para alertas (REQUERIDA en paso 7)
# ==============================================================================
set -euo pipefail

# ── Configuración ──────────────────────────────────────────────────────────────
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/opt/laesh/logs"
LOG_FILE="${LOG_DIR}/install_$(date +%F_%H%M%S).log"
export LAESH_DOMAIN="${LAESH_DOMAIN:-}"
export LAESH_ADMIN_EMAIL="${LAESH_ADMIN_EMAIL:-cbena999@gmail.com}"
export LAESH_SMTP_PASS="${LAESH_SMTP_PASS:-}"

# ── Colores ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${CYAN}[$(date +%T)]${NC} $*" | tee -a "${LOG_FILE}" 2>/dev/null || echo -e "${CYAN}[$(date +%T)]${NC} $*"; }
ok()   { echo -e "${GREEN}[✓]${NC} $*" | tee -a "${LOG_FILE}" 2>/dev/null || echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[△]${NC} $*" | tee -a "${LOG_FILE}" 2>/dev/null || echo -e "${YELLOW}[△]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" | tee -a "${LOG_FILE}" 2>/dev/null || echo -e "${RED}[✗]${NC} $*"; }

# ── Root check ─────────────────────────────────────────────────────────────────
[ "$EUID" -ne 0 ] && { err "Ejecutar con sudo: sudo bash $0 $*"; exit 1; }

# ── Args ───────────────────────────────────────────────────────────────────────
FROM_STEP=1; ONLY_STEP=0; SKIP_STEP=0
for arg in "$@"; do
    case "$arg" in
        --from=*) FROM_STEP="${arg#--from=}" ;;
        --only=*) ONLY_STEP="${arg#--only=}" ;;
        --skip=*) SKIP_STEP="${arg#--skip=}" ;;
    esac
done

# ── Log dir mínimo (antes de paso 1) ──────────────────────────────────────────
mkdir -p "${LOG_DIR}" 2>/dev/null || true

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD} LAESH Bloc Digital v1.2 — Pipeline de Instalación   ${NC}"
echo -e "${BOLD} Hostinger KVM2 · $(date '+%Y-%m-%d %H:%M:%S')       ${NC}"
if [[ -n "$LAESH_DOMAIN" ]]; then
    echo -e "${BOLD} Modo: B — Dominio + Let's Encrypt (${LAESH_DOMAIN}) ${NC}"
else
    echo -e "${BOLD} Modo: A — IP + Self-Signed (sin dominio)           ${NC}"
fi
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo ""

# ── Ejecutar paso ──────────────────────────────────────────────────────────────
run_step() {
    local num="$1" name="$2" script="$3"
    [[ $ONLY_STEP -gt 0 && $ONLY_STEP -ne $num ]] && return 0
    [[ $num -lt $FROM_STEP ]] && { warn "Paso $num ($name) — OMITIDO (--from=$FROM_STEP)"; return 0; }
    [[ $SKIP_STEP -eq $num ]] && { warn "Paso $num ($name) — OMITIDO (--skip=$num)"; return 0; }

    echo ""
    log "━━ Paso $num: ${name}"
    local start_ts=$SECONDS
    if bash "${SETUP_DIR}/${script}" 2>&1 | tee -a "${LOG_FILE}"; then
        local elapsed=$(( SECONDS - start_ts ))
        ok "Paso $num OK — ${elapsed}s"
    else
        err "Paso $num FALLÓ — revisar log: ${LOG_FILE}"
        err "Para reanudar desde este paso: sudo bash 00_run_all.sh --from=$num"
        exit 1
    fi
}

# ── Pipeline ───────────────────────────────────────────────────────────────────
T0=$SECONDS

run_step 1 "Preflight (swap, dirs, ulimit)"     "01_preflight.sh"
run_step 2 "Instalar stack (Nginx/MariaDB/PHP)" "02_install_stack.sh"
run_step 3 "Instalar Swoole 6.2.2"              "03_install_swoole.sh"
run_step 4 "Configurar stack"                   "04_configure_stack.sh"
run_step 5 "TLS Certbot (Modo A/B)"             "05_tls_certbot.sh"
run_step 6 "Deploy webapp + BD"                 "06_deploy_app.sh"
run_step 7 "Security hardening"                 "07_security_harden.sh"
run_step 8 "Verificación final"                 "08_verify.sh"

ELAPSED=$(( SECONDS - T0 ))
echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
ok "Pipeline completo — ${ELAPSED}s total"
echo -e "  Log: ${LOG_FILE}"
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo ""
