#!/usr/bin/env bash
# ==============================================================================
# LAESH — dump_preserve_tables.sh
#
# Paso previo a un setup_hostinger.sh --drop cuando se quiere preservar datos
# reales (usuarios, RBAC, configuraciones, CMS, catálogos) en vez de perderlos
# con el seed por defecto. Hace un dump SOLO-DATOS de la lista de tablas a
# preservar, y verifica fila por fila que el dump coincide con lo que hay en
# vivo ANTES de continuar — no genera un dump "de fe".
#
# Usado y probado en el setup E2E del 2026-09-20 (ver .agents/pending.md,
# P-LAESH-*). Nota: este dump por sí solo NO es apto para restaurar tal cual
# si el schema cambió entre el dump y el rebuild (columnas agregadas o
# eliminadas) — para restaurar, preferir restore_preserve_tables.sh, que usa
# el backup COMPLETO (con CREATE TABLE) y copia por nombre de columna, inmune
# a ese desfase. Este script sirve para la verificación de conteos pre-drop,
# no como fuente única del restore.
#
# Uso: sudo bash dump_preserve_tables.sh [ruta_salida_dir]
# ==============================================================================
set -euo pipefail

DB_NAME="laesh_db"
MCNF="/opt/laesh/configs/.mariadb-root.cnf"
OUT_DIR="${1:-/home/sysadmin/backups_pre_e2e}"
STAMP=$(date '+%Y%m%d_%H%M%S')
OUT_FILE="${OUT_DIR}/laesh_db_PRESERVE_TABLES_${STAMP}.sql"

# Lista canónica de tablas a preservar en un setup --drop (Fase B del plan de
# migración). Ajustar aquí si el modelo de datos agrega nuevas tablas de
# usuarios/catálogos/configuración que también deban sobrevivir un rebuild.
PRESERVE_TABLES=(
  users users_confirmations users_remembered users_resets users_throttling users_2fa
  empleados perfiles_medicos
  rbac_permisos rbac_permisos_usuarios
  configuraciones
  web_contenidos catalogo_promociones
  cat_categorias cat_estudios cat_gabinetes cat_subgabinetes cat_igabinetes
  rel_estudio_gabinete rel_igabinete_vinculos
  catalogos_ui
)

if [ ! -f "$MCNF" ]; then
  echo "ERROR: no se encontró $MCNF (¿corriendo sin sudo?)"
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "=== 1. Verificando cuáles de las ${#PRESERVE_TABLES[@]} tablas a preservar existen en $DB_NAME ==="
EXISTING_TABLES=()
MISSING_TABLES=()
for t in "${PRESERVE_TABLES[@]}"; do
  exists=$(mariadb --defaults-extra-file="$MCNF" -N -e "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB_NAME}' AND TABLE_NAME='${t}'")
  if [ "$exists" = "1" ]; then
    EXISTING_TABLES+=("$t")
  else
    MISSING_TABLES+=("$t")
  fi
done

echo "Existen (${#EXISTING_TABLES[@]}): ${EXISTING_TABLES[*]}"
if [ "${#MISSING_TABLES[@]}" -gt 0 ]; then
  echo "NO EXISTEN aún en KVM2 (${#MISSING_TABLES[@]}) — se omiten del dump, se crearán vacías por el --drop: ${MISSING_TABLES[*]}"
fi

echo
echo "=== 2. Conteo de filas EN VIVO (antes del dump) ==="
declare -A LIVE_COUNTS
for t in "${EXISTING_TABLES[@]}"; do
  c=$(mariadb --defaults-extra-file="$MCNF" -N -e "SELECT COUNT(*) FROM \`${DB_NAME}\`.\`${t}\`")
  LIVE_COUNTS[$t]=$c
  printf "  %-30s %s\n" "$t" "$c"
done

echo
echo "=== 3. Dump solo-datos (--extended-insert=FALSE para poder contar 1 INSERT = 1 fila) ==="
mariadb-dump \
  --defaults-extra-file="$MCNF" \
  --single-transaction \
  --no-create-info \
  --skip-triggers \
  --skip-add-drop-table \
  --extended-insert=FALSE \
  --default-character-set=utf8mb4 \
  "$DB_NAME" "${EXISTING_TABLES[@]}" \
  > "$OUT_FILE"

gzip -f "$OUT_FILE"
OUT_FILE="${OUT_FILE}.gz"
SIZE=$(du -sh "$OUT_FILE" | cut -f1)
echo "Dump generado: $OUT_FILE ($SIZE)"

echo
echo "=== 4. Conteo de filas EN EL DUMP (debe coincidir con el paso 2) ==="
MISMATCH=0
for t in "${EXISTING_TABLES[@]}"; do
  dc=$(zcat "$OUT_FILE" | grep -c "^INSERT INTO \`${t}\`" || true)
  live=${LIVE_COUNTS[$t]}
  status="OK"
  if [ "$dc" != "$live" ]; then
    status="*** MISMATCH ***"
    MISMATCH=1
  fi
  printf "  %-30s vivo=%-8s dump=%-8s %s\n" "$t" "$live" "$dc" "$status"
done

echo
chown sysadmin:sysadmin "$OUT_FILE" 2>/dev/null || true
if [ "$MISMATCH" -eq 1 ]; then
  echo "!!! HAY DISCREPANCIAS — NO continuar a --drop hasta resolver esto !!!"
  exit 1
else
  echo "=== TODO CONSISTENTE — listo para el paso --drop ==="
  echo "Archivo final: $OUT_FILE"
fi
