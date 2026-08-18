#!/usr/bin/env bash
# =============================================================================
# LAESH — 02_seed_users.sh
# Equivalente bash de webapp/seed_first_users.php
#
# Crea los 3 usuarios semilla (ADMIN, RECEPCION, MEDICO) ejecutando el script
# PHP dentro del contenedor web, donde Delight-Auth y la BD están disponibles.
#
# Uso:
#   bash setup/bds/laesh/bash/02_seed_users.sh
#
# Pre-requisitos:
#   1. Contenedores restaurantb_web y restaurantb_db corriendo.
#   2. Tablas Delight-Auth ya creadas (01_install_auth.sh).
#   3. Script idempotente: si el usuario ya existe, actualiza empleado/permisos.
#
# Contraseñas semilla (formato ddmmyyyy + especial = 10 chars):
#   ADMIN     9990000001  010120001!
#   RECEPCION 9990000002  010120002!
#   MEDICO    9990000003  010120003!
# =============================================================================
set -euo pipefail

WEB_CONTAINER="restaurantb_web"
PHP_SCRIPT="/var/www/html/laesh-swbldi/website/uipv1/webapp/seed_first_users.php"

# Verificar que el contenedor esté corriendo
if ! docker ps --format '{{.Names}}' | grep -q "^${WEB_CONTAINER}$"; then
  echo "[ERROR] Contenedor '${WEB_CONTAINER}' no está corriendo."
  echo "        Ejecuta: docker compose up -d"
  exit 1
fi

# Verificar que el script PHP exista dentro del contenedor
if ! docker exec "${WEB_CONTAINER}" test -f "${PHP_SCRIPT}" 2>/dev/null; then
  echo "[ERROR] Script no encontrado en el contenedor: ${PHP_SCRIPT}"
  echo "        Verifica que el volumen de laesh-swbldi esté montado."
  exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "  LAESH — Semilla de Usuarios (3 perfiles)"
echo "═══════════════════════════════════════════════════════"
echo ""

docker exec "${WEB_CONTAINER}" php "${PHP_SCRIPT}"

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo "═══════════════════════════════════════════════════════"
  echo "  ✅ Seed completado. Prueba el login en:"
  echo "     http://localhost:6001/laesh-swbldi/website/uipv1/index.html"
  echo "═══════════════════════════════════════════════════════"
else
  echo "[ERROR] El script PHP terminó con código ${EXIT_CODE}."
  exit $EXIT_CODE
fi
