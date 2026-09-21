#!/usr/bin/env bash
# ==============================================================================
# LAESH — restore_preserve_tables.sh
#
# Restaura las tablas "a preservar" (usuarios, RBAC, configuraciones, CMS,
# catálogos — ver PRESERVE_TABLES) sobre una laesh_db recién reconstruida por
# setup_hostinger.sh --drop, usando el BACKUP COMPLETO pre-drop (con
# CREATE TABLE intacto) como fuente.
#
# Incidente real 2026-09-20 que este script corrige: un primer intento de
# restore usó un dump solo-datos con INSERT posicional (sin nombres de
# columna) — el schema de perfiles_medicos en KVM2 tenía una columna
# (foto_url) que ya se había eliminado del schema base localmente pero nunca
# se había aplicado a la BD viva de KVM2. El desfase de columnas corrió los
# valores del INSERT y dejó 14 tablas vacías en producción (TRUNCATE previo,
# el resto del dump nunca llegó a cargar tras el primer error).
#
# Este script es inmune a ese desfase: carga el backup COMPLETO en una BD
# temporal (con su propio CREATE TABLE, schema viejo intacto), y copia cada
# tabla por INTERSECCIÓN de nombres de columna (information_schema.COLUMNS)
# hacia la BD real — columnas que ya no existen se ignoran, columnas nuevas
# quedan con su DEFAULT. TRUNCATE + INSERT van en la MISMA sesión de mariadb
# (SET FOREIGN_KEY_CHECKS=0 no persiste entre invocaciones separadas del
# cliente — segundo bug real encontrado y corregido el 2026-09-20).
#
# Uso: sudo bash restore_preserve_tables.sh <backup_completo.sql.gz>
#   (el backup completo lo genera scripts/backup_db.sh — vive normalmente en
#    /opt/laesh/backups/db/laesh_db_YYYYMMDD_HHMMSS.sql.gz)
# ==============================================================================
set -euo pipefail

MCNF="/opt/laesh/configs/.mariadb-root.cnf"
FULL_BACKUP="${1:?Uso: sudo bash restore_preserve_tables.sh <ruta al backup completo .sql.gz>}"
TMP_DB="laesh_db_restore_tmp"
LIVE_DB="laesh_db"

# Misma lista canónica que dump_preserve_tables.sh — mantener sincronizadas.
TABLES=(
  users users_confirmations users_remembered users_resets users_throttling users_2fa
  empleados perfiles_medicos
  rbac_permisos rbac_permisos_usuarios
  configuraciones
  web_contenidos catalogo_promociones
  cat_categorias cat_estudios cat_gabinetes cat_subgabinetes cat_igabinetes
  rel_estudio_gabinete rel_igabinete_vinculos
  catalogos_ui
)

if [ ! -f "$MCNF" ]; then echo "ERROR: falta $MCNF (¿corriendo sin sudo?)"; exit 1; fi
if [ ! -f "$FULL_BACKUP" ]; then echo "ERROR: no existe $FULL_BACKUP"; exit 1; fi

MC() { mariadb --defaults-extra-file="$MCNF" "$@"; }

echo "=== 1. Conteo ACTUAL en laesh_db (seed por defecto u otro estado previo) ==="
for t in "${TABLES[@]}"; do
  c=$(MC -N -e "SELECT COUNT(*) FROM \`${LIVE_DB}\`.\`${t}\`" 2>/dev/null || echo "N/A (tabla no existe)")
  printf "  %-30s %s\n" "$t" "$c"
done

echo
echo "=== 2. Creando BD temporal ${TMP_DB} y cargando el backup completo (schema del momento del backup) ==="
MC -e "DROP DATABASE IF EXISTS \`${TMP_DB}\`; CREATE DATABASE \`${TMP_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
# --force: ignora errores no críticos de rutinas/triggers/eventos (dependen de
# DEFINER, pueden no aplicar en un contexto temporal) — los datos de tabla se
# dumpean antes de esa sección y ya están cargados cuando eso ocurriría.
zcat "$FULL_BACKUP" \
  | sed "s/\`laesh_db\`/\`${TMP_DB}\`/g; s/ laesh_db\./ ${TMP_DB}./g; s/USE laesh_db/USE ${TMP_DB}/g" \
  | mariadb --defaults-extra-file="$MCNF" --force "${TMP_DB}"
echo "  ✓ Backup completo cargado en ${TMP_DB}"

echo
echo "=== 3. Conteo de filas en el backup (fuente de verdad) ==="
declare -A SRC_COUNTS
for t in "${TABLES[@]}"; do
  c=$(MC -N -e "SELECT COUNT(*) FROM \`${TMP_DB}\`.\`${t}\`" 2>/dev/null || echo "0")
  SRC_COUNTS[$t]=$c
  printf "  %-30s %s\n" "$t" "$c"
done

echo
echo "=== 4. Copiando por INTERSECCIÓN de columnas (TRUNCATE + INSERT en la misma sesión) ==="
for t in "${TABLES[@]}"; do
  if [ "${SRC_COUNTS[$t]:-0}" = "0" ]; then
    echo "  ${t}: sin filas en el backup, se omite"
    continue
  fi
  COLS=$(MC -N -e "
    SELECT GROUP_CONCAT(BINARY a.COLUMN_NAME ORDER BY a.ORDINAL_POSITION SEPARATOR ',')
    FROM information_schema.COLUMNS a
    JOIN information_schema.COLUMNS b
      ON b.TABLE_SCHEMA='${LIVE_DB}' AND b.TABLE_NAME='${t}' AND b.COLUMN_NAME=a.COLUMN_NAME
    WHERE a.TABLE_SCHEMA='${TMP_DB}' AND a.TABLE_NAME='${t}'
  ")
  if [ -z "$COLS" ]; then
    echo "  ${t}: SIN COLUMNAS COMPARTIDAS — omitida, revisar manualmente"
    continue
  fi
  MC -e "SET FOREIGN_KEY_CHECKS=0; TRUNCATE TABLE \`${LIVE_DB}\`.\`${t}\`; INSERT INTO \`${LIVE_DB}\`.\`${t}\` (${COLS}) SELECT ${COLS} FROM \`${TMP_DB}\`.\`${t}\`; SET FOREIGN_KEY_CHECKS=1;"
  echo "  ✓ ${t} (columnas: ${COLS})"
done

echo
echo "=== 5. Verificación final ==="
MISMATCH=0
for t in "${TABLES[@]}"; do
  live=$(MC -N -e "SELECT COUNT(*) FROM \`${LIVE_DB}\`.\`${t}\`" 2>/dev/null || echo "N/A")
  src=${SRC_COUNTS[$t]:-0}
  status="OK"
  if [ "$live" != "$src" ]; then status="*** MISMATCH ***"; MISMATCH=1; fi
  printf "  %-30s backup=%-8s actual=%-8s %s\n" "$t" "$src" "$live" "$status"
done

echo
echo "=== 6. Limpieza BD temporal ==="
MC -e "DROP DATABASE \`${TMP_DB}\`;"
echo "  ✓ ${TMP_DB} eliminada"

echo
if [ "$MISMATCH" -eq 1 ]; then
  echo "!!! HAY DISCREPANCIAS — revisar manualmente antes de dar el restore por bueno !!!"
  exit 1
else
  echo "=== RESTORE COMPLETO Y CONSISTENTE ==="
fi
