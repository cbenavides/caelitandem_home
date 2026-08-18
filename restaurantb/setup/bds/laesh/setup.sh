#!/bin/bash

# ==============================================================================
# Setup Orchestrator — LAESH Bloc Digital Database
# DB: laesh_db @ 127.0.0.1:6002 (dev) | Docker db:3306 (prod)
# Idempotente: puede ejecutarse múltiples veces sin error.
# ==============================================================================

set -e

# Credenciales de desarrollo (leer de .env si existe)
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-6002}"
DB_USER="${DB_USER:-root}"
DB_PASS="${DB_PASS:-comite_2026}"

# Directorio de este script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

MYSQL_CMD="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS"

echo "=================================================================="
echo " LAESH Bloc Digital — Setup de Base de Datos"
echo " Host: $DB_HOST:$DB_PORT | DB: laesh_db"
echo "=================================================================="

# ── PASO 0: Verificar que $auth->install() se haya ejecutado previamente.
# La tabla 'users' debe existir antes de continuar con el script 04.
# Ejecutar manualmente: php laesh-swbldi/commons/install_auth.php
# ──────────────────────────────────────────────────────────────────────
echo ""
echo "ADVERTENCIA: Este setup asume que Delight-Auth ya fue instalado."
echo "Si es la primera vez, ejecutar PRIMERO:"
echo "  php laesh-swbldi/commons/install_auth.php"
echo ""

# Función para ejecutar un script con reporte de estado
run_sql() {
    local script="$1"
    local desc="$2"
    echo "→ Ejecutando $script ($desc)..."
    $MYSQL_CMD < "$DIR/$script"
    echo "  ✓ OK"
}

# Secuencia de instalación
run_sql "00_database.sql"       "Base de datos y usuario de app"
run_sql "01_auth_schema.sql"    "Placeholder Delight-Auth (DDL via \$auth->install())"
run_sql "02_core_schema.sql"    "Core: CONFIGURACIONES, WEB_CONTENIDOS, ESTUDIOS, CATALOGOS_UI"
run_sql "03_transactional_schema.sql" "Transaccional: ORDENES, NOTIFICACIONES, HISTORIAL, etc."
run_sql "04_auth_extensions.sql" "Auth Extensions: EMPLEADOS, PERFILES_MEDICOS, RBAC"
run_sql "05_system_tables.sql"  "Sistema: SYS_LOGS, FALLBACK_LOG + Event Scheduler"
run_sql "06_indexes.sql"        "Índices de rendimiento"
run_sql "07_seed_catalogs.sql"  "Datos semilla: catálogos, estudios, configuraciones"
run_sql "08_stored_procedures.sql" "Procedimientos: CrearOrden, ProcesarPDF"

echo ""
echo "=================================================================="
echo " ✅ laesh_db configurada y sembrada exitosamente."
echo ""
echo " Credenciales de app: laesh_app / laesh_2026_dev"
echo " (cambiar contraseña antes de deploy a producción OCI)"
echo "=================================================================="
