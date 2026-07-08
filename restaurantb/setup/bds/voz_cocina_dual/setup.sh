#!/bin/bash

# ==============================================================================
# Setup Orchestrator for Comandas VOSK Database
# ==============================================================================

# Parse configuration from MCP context
MCP_JSON="/home/carlos/GitHub/agua_chatledger/.mcp.json"
if [ ! -f "$MCP_JSON" ]; then
    echo "Error: $MCP_JSON not found."
    exit 1
fi

# Extract bdrestaurant-host-a MySQL URI using grep/sed (minimal dependencies)
MYSQL_URI=$(grep -A 15 '"bdrestaurant-host-a"' "$MCP_JSON" | grep "mysql://" | sed -E 's/.*mysql:\/\/([^"]+)".*/\1/')

if [ -z "$MYSQL_URI" ]; then
    echo "Error: Could not extract MySQL URI from $MCP_JSON"
    exit 1
fi

# URI format: root:comite_2026@127.0.0.1:6002
DB_USER=$(echo "$MYSQL_URI" | cut -d':' -f1)
DB_PASS_HOST=$(echo "$MYSQL_URI" | cut -d':' -f2-)
DB_PASS=$(echo "$DB_PASS_HOST" | cut -d'@' -f1)
DB_HOST_PORT=$(echo "$DB_PASS_HOST" | cut -d'@' -f2)
DB_HOST=$(echo "$DB_HOST_PORT" | cut -d':' -f1)
DB_PORT=$(echo "$DB_HOST_PORT" | cut -d':' -f2)

# If URI has a db path at the end like 127.0.0.1:6002/db, strip it
DB_PORT=$(echo "$DB_PORT" | cut -d'/' -f1)

echo "Extracted Credentials:"
echo "Host: $DB_HOST"
echo "Port: $DB_PORT"
echo "User: $DB_USER"

# Build MySQL command
MYSQL_CMD="mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS"

echo "---------------------------------------------------------"
echo "Executing setup scripts..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

scripts=(
    "00_database.sql"
    "01_auth_schema.sql"
    "02_core_schema.sql"
    "09_alter_add_nlp_columns.sql"
    "03_transactional_schema.sql"
    "04_stored_procedures.sql"
    "05_seed_data.sql"
    "06_indexes.sql"
    "07_catalogo_versiones.sql"
    "08_pwa_telemetry.sql"
    "10_comandas_idempotencia.sql"
)

for script in "${scripts[@]}"; do
    echo "Running $script..."
    $MYSQL_CMD < "$DIR/$script"
    if [ $? -ne 0 ]; then
        echo "Error executing $script. Aborting."
        exit 1
    fi
done

echo "---------------------------------------------------------"
echo "Database vcd01 created and seeded successfully."
echo "Application DB User: vcd01 / vcd01"
echo "---------------------------------------------------------"
