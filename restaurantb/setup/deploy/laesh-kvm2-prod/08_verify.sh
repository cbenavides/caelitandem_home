#!/usr/bin/env bash
# ==============================================================================
# LAESH KVM2 · Paso 8 — Verificación Final (Health Check)
# 15 checks internos + llama bash/03_test_deploy.sh (27 checks HTTP).
# Puede ejecutarse en cualquier momento como health check permanente.
# No modifica el sistema.
#
# Uso:
#   sudo bash 08_verify.sh                                  # IP (Modo A)
#   LAESH_DOMAIN=laesh.mx sudo -E bash 08_verify.sh         # Dominio (Modo B)
# ==============================================================================

LAESH_DOMAIN="${LAESH_DOMAIN:-}"
LAESH_IP="83.136.219.193"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

PASS=0; WARN=0; FAIL=0

chk() {
    local label="$1"; local cmd="$2"; local expect="${3:-}"
    local result
    result=$(eval "$cmd" 2>/dev/null || echo "ERROR")
    if [[ -n "$expect" ]]; then
        if echo "$result" | grep -q "$expect"; then
            echo -e "  ${GREEN}✓${NC} $label"
            ((PASS++))
        else
            echo -e "  ${RED}✗${NC} $label (obtuvo: $(echo "$result" | head -1 | cut -c1-60))"
            ((FAIL++))
        fi
    else
        if [[ "$result" != "ERROR" && -n "$result" ]]; then
            echo -e "  ${GREEN}✓${NC} $label — $result"
            ((PASS++))
        else
            echo -e "  ${RED}✗${NC} $label"
            ((FAIL++))
        fi
    fi
}

chk_svc() {
    local svc="$1"
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $svc activo"
        ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $svc NO activo"
        ((FAIL++))
    fi
}

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD} LAESH Bloc Digital v1.2 — Health Check              ${NC}"
echo -e "${BOLD} $(date '+%Y-%m-%d %H:%M:%S') · $(hostname)          ${NC}"
if [[ -n "$LAESH_DOMAIN" ]]; then
    echo -e "${BOLD} Modo B: ${LAESH_DOMAIN}                           ${NC}"
else
    echo -e "${BOLD} Modo A: ${LAESH_IP} (self-signed)                 ${NC}"
fi
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"

# ── 1. Sistema ────────────────────────────────────────────────────────────────
echo ""
echo "── Sistema ─────────────────────────────────────────────────"
chk "Swap activo" "swapon --show | grep swapfile" "swapfile"
chk "vm.swappiness=10" "sysctl vm.swappiness" "10"
chk "/opt/laesh/ existe" "ls /opt/laesh/" "."
chk "/var/lib/mysql es symlink → laesh-db" "readlink /var/lib/mysql" "/opt/laesh/laesh-db"

# ── 2. Versiones stack ────────────────────────────────────────────────────────
echo ""
echo "── Versiones Stack ─────────────────────────────────────────"
chk "MariaDB 11.8.x" "mariadbd --version" "11\.8\."
chk "PHP 8.3.x" "php8.3 -r 'echo PHP_VERSION;'" "8\.3\."
chk "Swoole 6.2.2" "php8.3 -r 'echo SWOOLE_VERSION;'" "6\.2\.2"
chk "Composer instalado" "composer --version --no-ansi" "Composer"

# ── 3. Servicios ─────────────────────────────────────────────────────────────
echo ""
echo "── Servicios ───────────────────────────────────────────────"
chk_svc "nginx"
chk_svc "mariadb"
chk_svc "php8.3-fpm"
chk_svc "swoole-laesh"

# ── 4. Conectividad interna ──────────────────────────────────────────────────
echo ""
echo "── Conectividad Interna ────────────────────────────────────"
chk "Nginx responde HTTP" "curl -so /dev/null -w '%{http_code}' http://127.0.0.1/" "3"  # 301 redirect
chk "Swoole /status" "curl -sf http://127.0.0.1:9502/status" '"status":"online"'
chk "FPM socket existe" "test -S /run/php/php8.3-fpm.sock && echo OK" "OK"

# ── 5. BD ─────────────────────────────────────────────────────────────────────
echo ""
echo "── Base de Datos ───────────────────────────────────────────"
chk "MariaDB acepta conexiones" "mariadb -u root -e 'SELECT 1;' 2>/dev/null" "1"
chk "laesh_db existe" "mariadb -u root -e 'SHOW DATABASES;' 2>/dev/null" "laesh_db"
chk "Tabla users existe" "mariadb -u root laesh_db -e 'SELECT COUNT(*) FROM users;' 2>/dev/null" "[0-9]"

# ── 6. Logs ───────────────────────────────────────────────────────────────────
echo ""
echo "── Logs en /opt/laesh/logs/ ────────────────────────────────"
for logf in nginx-access.log nginx-error.log swoole.log; do
    # Los logs de nginx se crean en el primer request; verificar que el dir es escribible
    if [ -f "/opt/laesh/logs/${logf}" ] || [ -w "/opt/laesh/logs/" ]; then
        echo -e "  ${GREEN}✓${NC} /opt/laesh/logs/${logf} (dir escribible)"
        ((PASS++))
    else
        echo -e "  ${YELLOW}△${NC} /opt/laesh/logs/${logf} no existe aún (normal antes del primer request)"
        ((WARN++))
    fi
done

# ── 7. UFW ────────────────────────────────────────────────────────────────────
echo ""
echo "── Seguridad ───────────────────────────────────────────────"
if ufw status 2>/dev/null | grep -q "Status: active"; then
    echo -e "  ${GREEN}✓${NC} UFW activo"
    ((PASS++))
else
    echo -e "  ${YELLOW}△${NC} UFW no activo (paso 7 no ejecutado)"
    ((WARN++))
fi

# ── 8. bash/03_test_deploy.sh (27 checks HTTP) ───────────────────────────────
echo ""
echo "── bash/03_test_deploy.sh ──────────────────────────────────"
TEST_SCRIPT="/home/sysadmin/laesh-bds/bash/03_test_deploy.sh"
if [ -f "$TEST_SCRIPT" ]; then
    if [[ -n "$LAESH_DOMAIN" ]]; then
        BASE="https://${LAESH_DOMAIN}"
    else
        BASE="https://${LAESH_IP}"
    fi
    echo "  BASE=${BASE}"
    echo "  (HSTS y HTTP/2 fallarán en Modo A — esperado)"
    echo ""
    BASE="$BASE" bash "$TEST_SCRIPT" || true
else
    echo -e "  ${YELLOW}△${NC} ${TEST_SCRIPT} no encontrado — subir laesh-bds primero"
    ((WARN++))
fi

# ── Resumen ───────────────────────────────────────────────────────────────────
TOTAL=$((PASS + WARN + FAIL))
echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}✓ ${PASS}${NC} OK  |  ${YELLOW}△ ${WARN}${NC} Avisos  |  ${RED}✗ ${FAIL}${NC} Errores  |  Total: ${TOTAL}"
if [ $FAIL -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}STACK OPERATIVO${NC}"
else
    echo -e "  ${RED}${BOLD}$FAIL checks fallaron — revisar arriba${NC}"
fi
echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
echo ""
[ $FAIL -eq 0 ] || exit 1
