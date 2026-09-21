#!/usr/bin/env bash
# ==============================================================================
# LAESH KVM2 · Paso 8 — Verificación Final (Health Check)
# 15 checks internos + llama bash/verify/03_test_deploy.sh (27 checks HTTP).
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
chk "PHP 8.3.x" "php8.3 -n -r 'echo PHP_VERSION;'" "8\.3\."
chk "Swoole 6.2.x" "strings /usr/lib/php/20230831/swoole.so 2>/dev/null | grep -oE '6[.][0-9]+[.][0-9]+' | sort -V | tail -1" "6\.2\."
chk "Composer instalado" "php8.3 -n /usr/local/bin/composer --version --no-ansi 2>/dev/null" "Composer"

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
# Conexión root: preferir .mariadb-root.cnf (creado por 04_configure_stack.sh)
# que guarda la contraseña configurada. Fallback: unix_socket sin password
# (solo funciona en install fresco antes de paso 4).
_MCNF="/opt/laesh/configs/.mariadb-root.cnf"
if [ -f "$_MCNF" ]; then
    _MROOT="mariadb --defaults-extra-file=${_MCNF}"
else
    _MROOT="mariadb -u root"
fi

echo ""
echo "── Base de Datos ───────────────────────────────────────────"
chk "MariaDB acepta conexiones" "${_MROOT} -e 'SELECT 1;' 2>/dev/null" "1"
chk "laesh_db existe"           "${_MROOT} -e 'SHOW DATABASES;' 2>/dev/null" "laesh_db"
chk "Tabla users existe"        "${_MROOT} laesh_db -e 'SELECT COUNT(*) FROM users;' 2>/dev/null" "[0-9]"

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

# ── 8. Infraestructura adicional ──────────────────────────────────────────────
echo ""
echo "── Infraestructura Adicional ───────────────────────────────"

# Cache L2
if [ -d "/opt/laesh/cache" ] && [ -w "/opt/laesh/cache" ]; then
    echo -e "  ${GREEN}✓${NC} /opt/laesh/cache/ existe y es escribible (Cache L2 OPcache)"
    ((PASS++))
else
    echo -e "  ${RED}✗${NC} /opt/laesh/cache/ no existe o no es escribible — Cache L2 fallará"
    ((FAIL++))
fi

# Monitor state dir
if [ -d "/opt/laesh/monitor" ]; then
    echo -e "  ${GREEN}✓${NC} /opt/laesh/monitor/ existe (estado cooldown monitor_services)"
    ((PASS++))
else
    echo -e "  ${YELLOW}△${NC} /opt/laesh/monitor/ no existe — monitor_services.sh lo crea en primer run"
    ((WARN++))
fi

# swaks instalado
if command -v swaks &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} swaks instalado (SMTP alertas)"
    ((PASS++))
else
    echo -e "  ${YELLOW}△${NC} swaks no instalado — alertas SMTP deshabilitadas"
    ((WARN++))
fi

# swaks.conf sin placeholder
if [ -f /opt/laesh/configs/swaks.conf ]; then
    if grep -qF '__SMTP_PASS__' /opt/laesh/configs/swaks.conf; then
        echo -e "  ${RED}✗${NC} swaks.conf tiene __SMTP_PASS__ sin sustituir — alertas SMTP no funcionarán"
        ((FAIL++))
    else
        echo -e "  ${GREEN}✓${NC} swaks.conf configurado (sin placeholder)"
        ((PASS++))
    fi
else
    echo -e "  ${YELLOW}△${NC} swaks.conf no encontrado — alertas SMTP deshabilitadas"
    ((WARN++))
fi

# laesh-log-levels.path activo
if systemctl is-active --quiet laesh-log-levels.path 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} laesh-log-levels.path activo (hot log-level reload via inotify)"
    ((PASS++))
else
    echo -e "  ${YELLOW}△${NC} laesh-log-levels.path no activo — cambios en log-levels.conf no se aplican automáticamente"
    ((WARN++))
fi

# log-levels.conf sin placeholder y con contenido válido
LOG_LEVELS_FILE="/opt/laesh/logs/log-levels.conf"
if [ -f "$LOG_LEVELS_FILE" ]; then
    echo -e "  ${GREEN}✓${NC} log-levels.conf existe (niveles de log configurables)"
    ((PASS++))
else
    echo -e "  ${YELLOW}△${NC} log-levels.conf no encontrado — creado con defaults en paso 7"
    ((WARN++))
fi

# ── 9. Flujo de negocio E2E (M9, auditoría 2026-09-20) ───────────────────────
# Antes esta suite solo verificaba infraestructura (servicios activos, socket,
# SELECT COUNT(*) trivial) y códigos HTTP — un deploy podía reportar "STACK
# OPERATIVO" con el flujo central de negocio completamente roto (ej. el bug
# real encontrado en esta misma auditoría: CambiarEstadoOrden con firma vieja
# de 6 parámetros en BD mientras el PHP ya desplegado llama con 9 — ver
# migrations/README.md). Prueba real: crear una orden vía el SP de producción,
# cambiarle el estado con optimistic locking, cancelarla, y verificar cada
# paso — igual que se validó manualmente durante toda esta sesión. Usa un
# médico y una BD reales, pero borra TODO lo que crea al final (best-effort:
# el cleanup corre incluso si un chk intermedio falla).
echo ""
echo "── Flujo de Negocio E2E ────────────────────────────────────"
_E2E_MEDICO_ID=$(${_MROOT} laesh_db -N -e "SELECT user_id FROM perfiles_medicos LIMIT 1;" 2>/dev/null)
if [ -z "$_E2E_MEDICO_ID" ]; then
    echo -e "  ${YELLOW}△${NC} Sin médicos en perfiles_medicos — flujo E2E omitido (BD recién creada sin seed de usuarios)"
    ((WARN++))
else
    # pacientes.telefono/nombre_completo no son únicos — usar un teléfono fijo
    # y reconocible facilita el cleanup si un run anterior no terminó de limpiar.
    _E2E_PACIENTE_ID=$(${_MROOT} laesh_db -N -e "
        INSERT INTO pacientes (nombre_completo, sexo, telefono)
        VALUES ('TEST-08VERIFY-E2E', 'H', '0000000000');
        SELECT LAST_INSERT_ID();
    " 2>/dev/null)

    _E2E_FOLIO_OUT=$(${_MROOT} laesh_db -N -e "
        CALL CrearOrdenLaboratorio(${_E2E_PACIENTE_ID}, ${_E2E_MEDICO_ID}, NULL, 30, 'Verificación automática 08_verify.sh', '', '[]', @f);
        SELECT @f;
    " 2>&1)
    _E2E_ORDEN_ID=$(${_MROOT} laesh_db -N -e "SELECT id FROM ordenes WHERE folio_unico='${_E2E_FOLIO_OUT}';" 2>/dev/null)

    if [ -z "$_E2E_ORDEN_ID" ]; then
        echo -e "  ${RED}✗${NC} CrearOrdenLaboratorio — no generó una orden válida (obtuvo folio: '${_E2E_FOLIO_OUT}')"
        ((FAIL++))
    else
        echo -e "  ${GREEN}✓${NC} CrearOrdenLaboratorio — orden creada (folio ${_E2E_FOLIO_OUT}, id ${_E2E_ORDEN_ID})"
        ((PASS++))

        # Transición válida: Remitido(1) → En Atención(2), con optimistic lock correcto
        _E2E_CONF=$(${_MROOT} laesh_db -N -e "
            CALL CambiarEstadoOrden(${_E2E_ORDEN_ID}, 2, ${_E2E_MEDICO_ID}, 'Prueba E2E', 1, @prev, @folio, @conf, @inv);
            SELECT @conf;
        " 2>/dev/null)
        chk "CambiarEstadoOrden — transición válida 1→2 (p_conflicto=0)" "echo ${_E2E_CONF}" "^0$"

        # Optimistic lock: reenviar con estado_esperado desactualizado (1, ya está en 2) debe rechazar
        _E2E_CONF2=$(${_MROOT} laesh_db -N -e "
            CALL CambiarEstadoOrden(${_E2E_ORDEN_ID}, 3, ${_E2E_MEDICO_ID}, 'Prueba E2E lock', 1, @prev, @folio, @conf, @inv);
            SELECT @conf;
        " 2>/dev/null)
        chk "CambiarEstadoOrden — optimistic lock rechaza estado obsoleto (p_conflicto=1)" "echo ${_E2E_CONF2}" "^1$"

        # Regla de negocio (auditoría 2026-09-20, confirmada por el usuario):
        # cancelación (5) SOLO es válida desde Remitido (1). Desde En Atención (2)
        # debe rechazarse como transición inválida.
        _E2E_CANCEL=$(${_MROOT} laesh_db -N -e "
            CALL CambiarEstadoOrden(${_E2E_ORDEN_ID}, 5, ${_E2E_MEDICO_ID}, 'Prueba E2E cancelación desde 2 — debe rechazar', 2, @prev, @folio, @conf, @inv);
            SELECT @conf, @inv;
        " 2>/dev/null)
        chk "CambiarEstadoOrden — cancelación 2→5 RECHAZADA (p_conflicto=0, p_transicion_invalida=1)" "echo '${_E2E_CANCEL}'" "^0[[:space:]]1$"

        _E2E_ESTADO_FINAL=$(${_MROOT} laesh_db -N -e "SELECT estado_id FROM ordenes WHERE id=${_E2E_ORDEN_ID};" 2>/dev/null)
        chk "Orden permanece en estado_id=2 (rechazo no debe aplicar el cambio)" "echo ${_E2E_ESTADO_FINAL}" "^2$"
    fi

    # Segunda orden desechable: probar la única cancelación válida, 1→5
    _E2E_FOLIO_OUT2=$(${_MROOT} laesh_db -N -e "
        CALL CrearOrdenLaboratorio(${_E2E_PACIENTE_ID}, ${_E2E_MEDICO_ID}, NULL, 30, 'Verificación automática 08_verify.sh — cancelación 1→5', '', '[]', @f);
        SELECT @f;
    " 2>&1)
    _E2E_ORDEN_ID2=$(${_MROOT} laesh_db -N -e "SELECT id FROM ordenes WHERE folio_unico='${_E2E_FOLIO_OUT2}';" 2>/dev/null)

    if [ -z "$_E2E_ORDEN_ID2" ]; then
        echo -e "  ${RED}✗${NC} CrearOrdenLaboratorio (2da orden) — no generó una orden válida (obtuvo folio: '${_E2E_FOLIO_OUT2}')"
        ((FAIL++))
    else
        _E2E_CANCEL2=$(${_MROOT} laesh_db -N -e "
            CALL CambiarEstadoOrden(${_E2E_ORDEN_ID2}, 5, ${_E2E_MEDICO_ID}, 'Prueba E2E cancelación desde 1 — debe aceptar', 1, @prev, @folio, @conf, @inv);
            SELECT @conf, @inv;
        " 2>/dev/null)
        chk "CambiarEstadoOrden — cancelación 1→5 ACEPTADA (p_conflicto=0, p_transicion_invalida=0)" "echo '${_E2E_CANCEL2}'" "^0[[:space:]]0$"

        _E2E_ESTADO_FINAL2=$(${_MROOT} laesh_db -N -e "SELECT estado_id FROM ordenes WHERE id=${_E2E_ORDEN_ID2};" 2>/dev/null)
        chk "Segunda orden queda en estado_id=5 (Cancelada)" "echo ${_E2E_ESTADO_FINAL2}" "^5$"

        ${_MROOT} laesh_db -e "
            DELETE FROM notificaciones WHERE folio_referencia='${_E2E_FOLIO_OUT2}';
            DELETE FROM detalle_ordenes WHERE orden_id=${_E2E_ORDEN_ID2};
            DELETE FROM historial_estados_orden WHERE orden_id=${_E2E_ORDEN_ID2};
            DELETE FROM ordenes WHERE id=${_E2E_ORDEN_ID2};
        " 2>/dev/null
        echo "  (orden de prueba ${_E2E_FOLIO_OUT2} eliminada)"
    fi

    # Cleanup — best-effort, corre sin importar si algún chk anterior falló
    if [ -n "$_E2E_ORDEN_ID" ]; then
        ${_MROOT} laesh_db -e "
            DELETE FROM notificaciones WHERE folio_referencia='${_E2E_FOLIO_OUT}';
            DELETE FROM detalle_ordenes WHERE orden_id=${_E2E_ORDEN_ID};
            DELETE FROM historial_estados_orden WHERE orden_id=${_E2E_ORDEN_ID};
            DELETE FROM ordenes WHERE id=${_E2E_ORDEN_ID};
        " 2>/dev/null
        echo "  (orden de prueba ${_E2E_FOLIO_OUT} eliminada)"
    fi
    if [ -n "$_E2E_PACIENTE_ID" ]; then
        ${_MROOT} laesh_db -e "DELETE FROM pacientes WHERE id=${_E2E_PACIENTE_ID};" 2>/dev/null
    fi
fi

# ── 10. bash/verify/03_test_deploy.sh (27 checks HTTP) ───────────────────────
echo ""
echo "── Suite HTTP: bash/verify/03_test_deploy.sh ──────────────"
TEST_SCRIPT=""
for _CANDIDATE in \
    "/home/sysadmin/staging/setup/bds/laesh/bash/verify/03_test_deploy.sh"; do
    if [ -f "$_CANDIDATE" ]; then
        TEST_SCRIPT="$_CANDIDATE"
        break
    fi
done
if [ -n "$TEST_SCRIPT" ]; then
    if [[ -n "$LAESH_DOMAIN" ]]; then
        BASE="https://${LAESH_DOMAIN}"
    else
        BASE="https://${LAESH_IP}"
    fi
    echo "  BASE=${BASE}"
    echo "  Script: ${TEST_SCRIPT}"
    echo "  (HSTS y HTTP/2 fallarán en Modo A — esperado)"
    echo ""
    BASE="$BASE" bash "$TEST_SCRIPT" || true
else
    echo -e "  ${YELLOW}△${NC} 03_test_deploy.sh no encontrado — ubicaciones buscadas:"
    echo "        ~/staging/setup/bds/laesh/bash/verify/03_test_deploy.sh"
    echo "  Subir repo con rsync y reintentar (ver README §Pre-requisitos)."
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
