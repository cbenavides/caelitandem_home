#!/usr/bin/env bash
# =============================================================================
# LAESH — 01_install_auth.sh
# Paso 0 del pipeline de setup — invocado por setup.sh automáticamente.
#
# Crea las 7 tablas de Delight-Auth (PHP-Auth) directamente en laesh_db
# vía el contenedor MariaDB. Idempotente: usa CREATE TABLE IF NOT EXISTS.
#
# Uso directo (solo si se necesita ejecutar aislado):
#   bash setup/bds/laesh/bash/01_install_auth.sh
#
# Variables de entorno sobreescribibles:
#   DB_CONTAINER  (default: restaurantb_db)
#   DB_NAME       (default: laesh_db)
#   DB_USER       (default: root)
#   DB_PASS       (default: comite_2026)
#
# Pre-requisito: contenedor $DB_CONTAINER corriendo (docker ps).
# Nota: $auth->install() no existe en esta versión de Delight-Auth;
#       DDL derivado del código fuente — más confiable que la API.
# Siguiente paso automático: setup.sh → 00_database.sql … 08_stored_procedures.sql
#                            setup.sh → bash/02_seed_users.sh
# =============================================================================
set -euo pipefail

DB_CONTAINER="${DB_CONTAINER:-restaurantb_db}"
DB_NAME="${DB_NAME:-laesh_db}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-comite_2026}"

# Verificar que el contenedor esté corriendo
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
  echo "[ERROR] Contenedor '${DB_CONTAINER}' no está corriendo."
  echo "        Ejecuta: docker compose up -d"
  exit 1
fi

run_sql() {
  docker exec -i "${DB_CONTAINER}" \
    mariadb -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" <<< "$1" 2>/dev/null \
    || docker exec -i "${DB_CONTAINER}" \
       mysql -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" <<< "$1" 2>/dev/null
}

echo "═══════════════════════════════════════════════════════"
echo "  LAESH — Instalación tablas Delight-Auth"
echo "═══════════════════════════════════════════════════════"

echo "→ Creando tabla users..."
run_sql "
CREATE TABLE IF NOT EXISTS \`users\` (
    \`id\`           INT(10)      UNSIGNED NOT NULL AUTO_INCREMENT,
    \`email\`        VARCHAR(249) COLLATE utf8mb4_unicode_ci NOT NULL,
    \`password\`     VARCHAR(255) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
    \`username\`     VARCHAR(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    \`status\`       TINYINT(4)   UNSIGNED NOT NULL DEFAULT 0,
    \`verified\`     TINYINT(1)   UNSIGNED NOT NULL DEFAULT 0,
    \`resettable\`   TINYINT(1)   UNSIGNED NOT NULL DEFAULT 1,
    \`roles_mask\`   INT(10)      UNSIGNED NOT NULL DEFAULT 0,
    \`registered\`   INT(10)      UNSIGNED NOT NULL,
    \`last_login\`   INT(10)      UNSIGNED DEFAULT NULL,
    \`force_logout\` MEDIUMINT(7) UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (\`id\`),
    UNIQUE KEY \`email\` (\`email\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"
echo "  ✓ users"

echo "→ Creando tabla users_remembered..."
run_sql "
CREATE TABLE IF NOT EXISTS \`users_remembered\` (
    \`id\`       BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
    \`user\`     INT(10)    UNSIGNED NOT NULL,
    \`selector\` VARCHAR(24)  CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    \`token\`    VARCHAR(200) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    \`expires\`  INT(10)    UNSIGNED NOT NULL,
    PRIMARY KEY (\`id\`),
    UNIQUE KEY \`selector\` (\`selector\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"
echo "  ✓ users_remembered"

echo "→ Creando tabla users_throttling..."
run_sql "
CREATE TABLE IF NOT EXISTS \`users_throttling\` (
    \`bucket\`         VARCHAR(255) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    \`tokens\`         FLOAT        UNSIGNED NOT NULL,
    \`replenished_at\` INT(10)      UNSIGNED NOT NULL,
    \`expires_at\`     INT(10)      UNSIGNED NOT NULL,
    PRIMARY KEY (\`bucket\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"
echo "  ✓ users_throttling"

echo "→ Creando tabla users_confirmations..."
run_sql "
CREATE TABLE IF NOT EXISTS \`users_confirmations\` (
    \`id\`       INT(10)      UNSIGNED NOT NULL AUTO_INCREMENT,
    \`user_id\`  INT(10)      UNSIGNED NOT NULL,
    \`email\`    VARCHAR(249) COLLATE utf8mb4_unicode_ci NOT NULL,
    \`selector\` VARCHAR(24)  CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    \`token\`    VARCHAR(200) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    \`expires\`  INT(10)      UNSIGNED NOT NULL,
    PRIMARY KEY (\`id\`),
    UNIQUE KEY \`selector\` (\`selector\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"
echo "  ✓ users_confirmations"

echo "→ Creando tabla users_resets..."
run_sql "
CREATE TABLE IF NOT EXISTS \`users_resets\` (
    \`id\`       BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT,
    \`user\`     INT(10)    UNSIGNED NOT NULL,
    \`selector\` VARCHAR(24)  CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    \`token\`    VARCHAR(200) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL,
    \`expires\`  INT(10)      UNSIGNED NOT NULL,
    PRIMARY KEY (\`id\`),
    UNIQUE KEY \`selector\` (\`selector\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"
echo "  ✓ users_resets"

echo "→ Creando tabla users_audit_log..."
run_sql "
CREATE TABLE IF NOT EXISTS \`users_audit_log\` (
    \`id\`           BIGINT(20)   UNSIGNED NOT NULL AUTO_INCREMENT,
    \`user_id\`      INT(10)      UNSIGNED NOT NULL,
    \`event_at\`     INT(10)      UNSIGNED NOT NULL,
    \`event_type\`   VARCHAR(64)  COLLATE utf8mb4_unicode_ci NOT NULL,
    \`admin_id\`     INT(10)      UNSIGNED DEFAULT NULL,
    \`ip_address\`   VARCHAR(45)  COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    \`user_agent\`   VARCHAR(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    \`details_json\` MEDIUMTEXT   COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    PRIMARY KEY (\`id\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"
echo "  ✓ users_audit_log"

echo "→ Creando tabla users_2fa..."
run_sql "
CREATE TABLE IF NOT EXISTS \`users_2fa\` (
    \`id\`         BIGINT(20)   UNSIGNED NOT NULL AUTO_INCREMENT,
    \`user_id\`    INT(10)      UNSIGNED NOT NULL,
    \`mechanism\`  TINYINT(4)   UNSIGNED NOT NULL,
    \`seed\`       VARBINARY(255) NOT NULL,
    \`created_at\` INT(10)      UNSIGNED NOT NULL,
    \`expires_at\` INT(10)      UNSIGNED DEFAULT NULL,
    PRIMARY KEY (\`id\`),
    KEY \`user_id_mechanism\` (\`user_id\`, \`mechanism\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
"
echo "  ✓ users_2fa"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅ 7 tablas Delight-Auth instaladas en ${DB_NAME}"
echo "  Siguiente paso (si ejecutas aislado):"
echo "    bash setup/bds/laesh/setup.sh   ← orquestador completo (recomendado)"
echo "═══════════════════════════════════════════════════════"
