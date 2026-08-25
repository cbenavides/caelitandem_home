#!/usr/bin/env bash
# ==============================================================================
# 03_test_deploy.sh — Suite de Pruebas de Deploy LAESH
#
# Verifica 27 puntos tras el deploy de portales LAESH:
#   1. HTTP Status (portales, redirects, login.php)
#   2. Assets estáticos (CSS, JS, old-path → 404)
#   3. CSP headers (unsafe-inline, unpkg, youtube, OSM, ytimg, wss)
#   4. Headers de seguridad (HSTS, X-Frame-Options, Referrer, nosniff, HTTP/2)
#   5. PHP operativo (body checks: HTML, form login, redirect a login)
#
# Uso:
#   bash setup/bds/laesh/bash/03_test_deploy.sh
#   BASE=https://caelitandem.lat bash setup/bds/laesh/bash/03_test_deploy.sh
#   BASE=https://192.168.1.71:8443 bash setup/bds/laesh/bash/03_test_deploy.sh
#
# Variables:
#   BASE   URL base del entorno a probar (default: https://caelitandem.lat)
# ==============================================================================

BASE="${BASE:-https://caelitandem.lat}"
PASS=0; FAIL=0

green="\e[32m✅\e[0m"
red="\e[31m❌\e[0m"

check_status() {
  local label="$1" url="$2" expected="$3"
  local got
  got=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 10 "$url")
  if [ "$got" = "$expected" ]; then
    echo -e "  $green $label → HTTP $got"
    ((PASS++))
  else
    echo -e "  $red $label → esperado HTTP $expected, obtuvo HTTP $got"
    ((FAIL++))
  fi
}

check_header() {
  local label="$1" url="$2" header="$3" pattern="$4"
  local got
  got=$(curl -sk -I --max-time 10 "$url" | grep -i "^${header}:" || echo "")
  if echo "$got" | grep -qi "$pattern"; then
    echo -e "  $green $label → contiene '$pattern'"
    ((PASS++))
  else
    echo -e "  $red $label → '$pattern' NO encontrado en header ${header}"
    ((FAIL++))
  fi
}

check_body() {
  local label="$1" url="$2" pattern="$3"
  local got
  got=$(curl -skL --max-time 10 "$url" | head -c 5000)
  if echo "$got" | grep -qi "$pattern"; then
    echo -e "  $green $label → body contiene '$pattern'"
    ((PASS++))
  else
    echo -e "  $red $label → '$pattern' NO en body"
    ((FAIL++))
  fi
}

check_http2() {
  local label="$1" url="$2"
  local ver
  ver=$(curl -sk --http2 -o /dev/null -w "%{http_version}" --max-time 10 "$url")
  if [ "$ver" = "2" ]; then
    echo -e "  $green $label → HTTP/$ver"
    ((PASS++))
  else
    echo -e "  $red $label → HTTP/$ver (esperado HTTP/2)"
    ((FAIL++))
  fi
}

echo ""
echo "======================================================"
echo "  LAESH Deploy — Suite de Pruebas  v3"
echo "  Base: $BASE"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "======================================================"

# ── BLOQUE 1: HTTP Status Portales ──────────────────────────────────────────
echo ""
echo "── 1. HTTP Status Portales ─────────────────────────────────────────"
check_status "GET /laesh/"              "$BASE/laesh/"              "200"
check_status "GET /laesh/md/"           "$BASE/laesh/md/"           "302"
check_status "GET /laesh/rc/"           "$BASE/laesh/rc/"           "302"
check_status "GET /laesh/adrc/"         "$BASE/laesh/adrc/"         "302"
check_status "301 /laesh/md"            "$BASE/laesh/md"            "301"
check_status "301 /laesh/rc"            "$BASE/laesh/rc"            "301"
check_status "301 /laesh/adrc"          "$BASE/laesh/adrc"          "301"
check_status "GET /laesh/login/login.php" "$BASE/laesh/login/login.php" "200"

# ── BLOQUE 2: Assets Estáticos ───────────────────────────────────────────────
echo ""
echo "── 2. Assets Estáticos ─────────────────────────────────────────────"
check_status "CSS portal.css"            "$BASE/laesh-web-assets-uipv1a/css/portal.css" "200"
check_status "JS app.js"                 "$BASE/laesh-web-assets-uipv1a/js/app.js"      "200"
check_status "JS website.js"             "$BASE/laesh-web-assets-uipv1a/js/website.js"  "200"
check_status "Old /laesh-web-assets 404" "$BASE/laesh-web-assets/css/portal.css"        "404"

# ── BLOQUE 3: CSP ────────────────────────────────────────────────────────────
echo ""
echo "── 3. CSP (Content-Security-Policy) ────────────────────────────────"
check_header "script-src unsafe-inline"    "$BASE/" "content-security-policy" "unsafe-inline"
check_header "unpkg.com (CKEditor)"        "$BASE/" "content-security-policy" "unpkg.com"
check_header "frame-src youtube.com"       "$BASE/" "content-security-policy" "youtube.com"
check_header "frame-src openstreetmap.org" "$BASE/" "content-security-policy" "openstreetmap.org"
check_header "img-src i.ytimg.com"         "$BASE/" "content-security-policy" "i.ytimg.com"
check_header "connect-src wss:"            "$BASE/" "content-security-policy" "wss:"

# ── BLOQUE 4: Headers de Seguridad ───────────────────────────────────────────
echo ""
echo "── 4. Headers de Seguridad ─────────────────────────────────────────"
check_header "HSTS"            "$BASE/" "strict-transport-security" "max-age=31536000"
check_header "X-Frame-Options" "$BASE/" "x-frame-options"           "SAMEORIGIN"
check_header "Referrer-Policy" "$BASE/" "referrer-policy"           "strict-origin"
check_header "X-Content-Type"  "$BASE/" "x-content-type-options"    "nosniff"
check_http2  "HTTP/2 activo"   "$BASE/"

# ── BLOQUE 5: PHP Operativo ──────────────────────────────────────────────────
echo ""
echo "── 5. PHP Operativo (body checks) ──────────────────────────────────"
check_body "HTML válido en /laesh/"         "$BASE/laesh/"               "<!doctype\|<html"
check_body "Form login en login.php"        "$BASE/laesh/login/login.php" "<form\|telefono\|password\|login"
check_body "MD redirect llega a login"      "$BASE/laesh/md/"            "<form\|login\|redirect"
check_body "RC redirect llega a login"      "$BASE/laesh/rc/"            "<form\|login\|redirect"

# ── RESUMEN ──────────────────────────────────────────────────────────────────
echo ""
echo "======================================================"
TOTAL=$((PASS+FAIL))
echo "  Resultado: $PASS/$TOTAL pruebas pasaron"
if [ $FAIL -eq 0 ]; then
  echo -e "  $green DEPLOY EXITOSO — todos los checks OK"
else
  echo -e "  $red $FAIL checks fallaron — revisar arriba"
fi
echo "======================================================"
echo ""
