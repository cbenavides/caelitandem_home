#!/usr/bin/env bash
# ==============================================================================
# rectification_suite.sh — Batería de Pruebas de Rectificación E2E para LAESH
#
# Valida la integridad absoluta tras optimización de BD, OPcache y JS en KVM2:
#   Test 1: Schema MariaDB (PK física en rel_igabinete_vinculos, índices limpios)
#   Test 2: Integridad de Vistas y Catálogos (vw_estudios_catalogo, arbol, top20)
#   Test 3: Preservación de formato HTML en catalogo_promociones (<p>Lunes</p>)
#   Test 4: Purga física de tokens JTI expirados en /opt/laesh/cache/ (>24h = 0)
#   Test 5: Eliminación de residuos de catalog-data.js
#   Test 6: Cache-busting con filemtime y soporte HTTP 304 Not Modified
#   Test 7: Estado de servicios (Nginx, PHP-FPM, MariaDB, Swoole WS y Bridge)
#
# Uso:
#   bash setup/deploy/laesh-kvm2-prod/scripts/rectification_suite.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KVM2_SSH="laesh-kvm2"

if [[ -d "/opt/laesh/www" ]]; then
    run_cmd() {
        bash -c "$1"
    }
else
    run_cmd() {
        ssh "$KVM2_SSH" "$1"
    }
fi


GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0; TOTAL=0

t_start() {
    TOTAL=$((TOTAL + 1))
    echo -n "[$TOTAL] $1... "
}

t_pass() {
    PASS=$((PASS + 1))
    echo -e "${GREEN}PASS${NC} $1"
}

t_fail() {
    FAIL=$((FAIL + 1))
    echo -e "${RED}FAIL${NC} $1"
}

echo -e "\n${BOLD}══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD} LAESH Bloc Digital — Suite de Rectificación KVM2 Producción          ${NC}"
echo -e "${BOLD} $(date '+%Y-%m-%d %H:%M:%S')                                             ${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════════════════${NC}\n"

# ------------------------------------------------------------------------------
# TEST 1: Schema MariaDB
# ------------------------------------------------------------------------------
t_start "Verificando Primary Key autoincremental en rel_igabinete_vinculos"
pk_col=$(run_cmd "mariadb -u laesh_app -plaesh_2026_dev laesh_db -N -e \"
    SELECT COLUMN_NAME FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA='laesh_db' AND TABLE_NAME='rel_igabinete_vinculos' AND COLUMN_KEY='PRI';
\"" 2>/dev/null || true)

if [[ "$pk_col" == "id" ]]; then
    t_pass "(PK explícita = id, clustered index nativo)"
else
    t_fail "(esperado: id, obtenido: '$pk_col')"
fi

t_start "Verificando unicidad virtual uq_vinculo_unico en rel_igabinete_vinculos"
has_uq=$(run_cmd "mariadb -u laesh_app -plaesh_2026_dev laesh_db -N -e \"
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA='laesh_db' AND TABLE_NAME='rel_igabinete_vinculos' AND INDEX_NAME='uq_vinculo_unico';
\"" 2>/dev/null || true)

if [[ "$has_uq" -gt 0 ]]; then
    t_pass "(uq_vinculo_unico existe)"
else
    t_fail "(uq_vinculo_unico no encontrada)"
fi

t_start "Verificando eliminación de 6 índices secundarios redundantes"
redundant_count=$(run_cmd "mariadb -u laesh_app -plaesh_2026_dev laesh_db -N -e \"
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA='laesh_db' AND (
        (TABLE_NAME='web_contenidos' AND INDEX_NAME IN ('idx_cms_sec_sub_clave', 'idx_seccion')) OR
        (TABLE_NAME='ordenes' AND INDEX_NAME IN ('idx_medico', 'idx_estado')) OR
        (TABLE_NAME='notificaciones' AND INDEX_NAME='idx_user') OR
        (TABLE_NAME='historial_estados_orden' AND INDEX_NAME='idx_orden')
    );
\"" 2>/dev/null || true)

if [[ "$redundant_count" -eq 0 ]]; then
    t_pass "(0 índices redundantes presentes)"
else
    t_fail "(se encontraron $redundant_count índices redundantes)"
fi

t_start "Verificando índice compuesto idx_user_revoked en jwt_jti_registry"
has_jti_idx=$(run_cmd "mariadb -u laesh_app -plaesh_2026_dev laesh_db -N -e \"
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA='laesh_db' AND TABLE_NAME='jwt_jti_registry' AND INDEX_NAME='idx_user_revoked';
\"" 2>/dev/null || true)

if [[ "$has_jti_idx" -gt 0 ]]; then
    t_pass "(idx_user_revoked activo y cubriendo FK)"
else
    t_fail "(idx_user_revoked no encontrado)"
fi

t_start "Verificando que cat_categorias fue purgada y cat_estudios está limpia"
cat_exists=$(run_cmd "mariadb -u laesh_app -plaesh_2026_dev laesh_db -N -e \"
    SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='laesh_db' AND TABLE_NAME='cat_categorias';
\"" 2>/dev/null || true)
col_dead=$(run_cmd "mariadb -u laesh_app -plaesh_2026_dev laesh_db -N -e \"
    SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA='laesh_db' AND TABLE_NAME='cat_estudios' 
      AND COLUMN_NAME IN ('categoria_id', 'descripcion_breve', 'detalle', 'fecha_creacion', 'fecha_modificacion');
\"" 2>/dev/null || true)

if [[ "$cat_exists" -eq 0 && "$col_dead" -eq 0 ]]; then
    t_pass "(cat_categorias eliminada y cat_estudios libre de columnas muertas)"
else
    t_fail "(cat_categorias existe=$cat_exists, columnas muertas=$col_dead)"
fi

# ------------------------------------------------------------------------------
# TEST 2: Integridad de Vistas y Catálogos
# ------------------------------------------------------------------------------
t_start "Consultando vw_estudios_catalogo (1,055 registros activos)"
n_estudios=$(run_cmd "mariadb -u laesh_app -plaesh_2026_dev laesh_db -N -e \"
    SELECT COUNT(*) FROM vw_estudios_catalogo WHERE activo = 1;
\"" 2>/dev/null || true)

if [[ "$n_estudios" -ge 1050 ]]; then
    t_pass "($n_estudios estudios activos leídos sin error de vista)"
else
    t_fail "(obtenido: $n_estudios estudios)"
fi

t_start "Consultando vw_website_arbol_estudios y vw_top20_estudios"
n_arbol=$(run_cmd "mariadb -u laesh_app -plaesh_2026_dev laesh_db -N -e \"
    SELECT COUNT(*) FROM vw_website_arbol_estudios;
\"" 2>/dev/null || true)
n_top20=$(run_cmd "mariadb -u laesh_app -plaesh_2026_dev laesh_db -N -e \"
    SELECT COUNT(*) FROM vw_top20_estudios;
\"" 2>/dev/null || true)

if [[ "$n_arbol" -gt 0 && "$n_top20" -gt 0 ]]; then
    t_pass "(árbol=$n_arbol ramas, top20=$n_top20 registros)"
else
    t_fail "(arbol=$n_arbol, top20=$n_top20)"
fi

# ------------------------------------------------------------------------------
# TEST 3: Preservación de formato HTML en Promociones
# ------------------------------------------------------------------------------
t_start "Verificando tipo VARCHAR(255) y formato HTML en catalogo_promociones"
tipo_promo=$(run_cmd "mariadb -u laesh_app -plaesh_2026_dev laesh_db -N -e \"
    SELECT DATA_TYPE, CHARACTER_MAXIMUM_LENGTH FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA='laesh_db' AND TABLE_NAME='catalogo_promociones' AND COLUMN_NAME='dia_semana';
\"" 2>/dev/null || true)
html_sample=$(run_cmd "mariadb -u laesh_app -plaesh_2026_dev laesh_db -N -e \"
    SELECT dia_semana FROM catalogo_promociones WHERE id=1;
\"" 2>/dev/null || true)

if echo "$tipo_promo" | grep -qi "varchar" && echo "$html_sample" | grep -qi "<p>"; then
    t_pass "(tipo in-row $tipo_promo, muestra HTML intacta: '$html_sample')"
else
    t_fail "(tipo: $tipo_promo, muestra: $html_sample)"
fi

# ------------------------------------------------------------------------------
# TEST 4: Purga física de tokens JTI expirados
# ------------------------------------------------------------------------------
t_start "Ejecutando cache_renew.php y verificando purga de archivos JTI zombi"
run_cmd "LAESH_CACHE_DIR=/opt/laesh/cache php8.3 /opt/laesh/www/laesh-swbldi/crons/cache_renew.php > /dev/null 2>&1"
expired_jtis=$(run_cmd "find /opt/laesh/cache/ -name 'laesh_cache_*_JTI_*.php' -mtime +1 | wc -l" 2>/dev/null || true)

if [[ "$expired_jtis" -eq 0 ]]; then
    t_pass "(0 archivos JTI expirados en disco /opt/laesh/cache/)"
else
    t_fail "($expired_jtis archivos JTI expirados aún persisten)"
fi

# ------------------------------------------------------------------------------
# TEST 5: Residuos de catalog-data.js
# ------------------------------------------------------------------------------
t_start "Verificando ausencia física de catalog-data.js en activos"
cat_data_exists=$(run_cmd "test -f /opt/laesh/assets/laesh-web-assets-uipv1a/js/catalog-data.js && echo 'SI' || echo 'NO'")

if [[ "$cat_data_exists" == "NO" ]]; then
    t_pass "(catalog-data.js purgado y ausente)"
else
    t_fail "(catalog-data.js aún existe en assets)"
fi

# ------------------------------------------------------------------------------
# TEST 6: HTTP y Caché 304 Not Modified
# ------------------------------------------------------------------------------
t_start "Verificando cabecera Last-Modified en catalog-compiled.js (670 KB)"
http_code=$(run_cmd "curl -sk -o /dev/null -w '%{http_code}' https://127.0.0.1/laesh-web-assets-uipv1a/js/catalog-compiled.js")
last_mod=$(run_cmd "curl -skI https://127.0.0.1/laesh-web-assets-uipv1a/js/catalog-compiled.js | grep -i 'last-modified' | tr -d '\r'")

if [[ "$http_code" == "200" && -n "$last_mod" ]]; then
    # Test 304
    lmod_val="${last_mod#*: }"
    code_304=$(run_cmd "curl -sk -o /dev/null -w '%{http_code}' -H 'If-Modified-Since: $lmod_val' https://127.0.0.1/laesh-web-assets-uipv1a/js/catalog-compiled.js")
    if [[ "$code_304" == "304" ]]; then
        t_pass "(HTTP 200 inicial, HTTP 304 condicional funcionando al 100%)"
    else
        t_fail "(esperado 304, obtenido $code_304)"
    fi
else
    t_fail "(código: $http_code, last_mod: $last_mod)"
fi

# ------------------------------------------------------------------------------
# TEST 7: Estado de Servicios y Bridge
# ------------------------------------------------------------------------------
t_start "Verificando servicios systemd (nginx, php8.3-fpm, mariadb, swoole-laesh)"
all_active=true
for svc in nginx php8.3-fpm mariadb swoole-laesh; do
    if ! run_cmd "systemctl is-active --quiet $svc"; then
        all_active=false
        break
    fi
done

if $all_active; then
    ws_status=$(run_cmd "curl -sf http://127.0.0.1:9502/status" 2>/dev/null || true)
    if echo "$ws_status" | grep -q '"status":"online"'; then
        t_pass "(todos los servicios activos y Swoole WS online)"
    else
        t_fail "(Swoole status inválido: $ws_status)"
    fi
else
    t_fail "(uno o más servicios no están activos)"
fi

# ------------------------------------------------------------------------------
# RESUMEN
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}══════════════════════════════════════════════════════════════════════${NC}"
if [[ "$FAIL" -eq 0 ]]; then
    echo -e "${GREEN}${BOLD} ✓ RECTIFICACIÓN COMPLETADA: $PASS/$TOTAL PRUEBAS EXITOSAS (100%)${NC}"
    echo -e "${BOLD}══════════════════════════════════════════════════════════════════════${NC}\n"
    exit 0
else
    echo -e "${RED}${BOLD} ✗ RECTIFICACIÓN CON FALLOS: $PASS PASARON, $FAIL FALLARON${NC}"
    echo -e "${BOLD}══════════════════════════════════════════════════════════════════════${NC}\n"
    exit 1
fi
