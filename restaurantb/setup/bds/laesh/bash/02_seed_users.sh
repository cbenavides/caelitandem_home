#!/usr/bin/env bash
# =============================================================================
# LAESH — 02_seed_users.sh
# Paso final del pipeline de setup — invocado por setup.sh automáticamente.
#
# Crea los 3 usuarios semilla (ADMIN, RECEPCION, MEDICO) ejecutando
# commons/seed_first_users.php dentro del contenedor PHP-FPM,
# donde Delight-Auth y la BD están disponibles.
# Idempotente: si el usuario ya existe, actualiza empleado/permisos.
#
# Uso directo (solo si se necesita ejecutar aislado):
#   bash setup/bds/laesh/bash/02_seed_users.sh
#
# Variables de entorno sobreescribibles:
#   WEB_CONTAINER  (default: restaurantb_phpfpm)
#
# Pre-requisitos:
#   1. Contenedor $WEB_CONTAINER corriendo (docker ps).
#   2. setup.sh ya ejecutado (tablas Auth + schema + seed catálogos).
#
# Contraseñas semilla (formato ddmmyyyy + especial, 10 chars):
#   ADMIN     9990000001  010120001!
#   RECEPCION 9990000002  010120002!
#   MEDICO    9990000003  010120003!
# =============================================================================
set -euo pipefail

WEB_CONTAINER="${WEB_CONTAINER:-restaurantb_phpfpm}"
PHP_SCRIPT="/var/www/html/laesh-swbldi/commons/seed_first_users.php"

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
  echo "     https://192.168.0.120:8443/laesh/"
  echo "═══════════════════════════════════════════════════════"
else
  echo "[ERROR] El script PHP terminó con código ${EXIT_CODE}."
  exit $EXIT_CODE
fi
