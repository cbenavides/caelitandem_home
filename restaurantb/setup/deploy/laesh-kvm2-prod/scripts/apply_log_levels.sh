#!/usr/bin/env bash
# ==============================================================================
# LAESH — apply_log_levels.sh
# Lee /opt/laesh/logs/log-levels.conf y aplica los niveles de log a cada
# servicio del stack. Disparado automáticamente por laesh-log-levels.service
# cuando el archivo cambia (vía inotify / systemd path unit).
#
# También puede ejecutarse manualmente:
#   sudo bash /opt/laesh/scripts/apply_log_levels.sh
#
# Servicios afectados:
#   Nginx   → modifica error_log level en nginx.conf → nginx -s reload
#   MariaDB → SET GLOBAL sin reinicio (cambio inmediato)
#   PHP-FPM → modifica 99-laesh.ini → systemctl reload php8.3-fpm
#   App PHP → escribe /opt/laesh/configs/app-log-level.php (cacheado por OPcache)
# ==============================================================================

set -uo pipefail

CONFIG="/opt/laesh/logs/log-levels.conf"
APPLY_LOG="/opt/laesh/logs/apply-log-levels.log"
MARIADB_CNF="/opt/laesh/configs/.mariadb-root.cnf"
PHP_INI="/etc/php/8.3/fpm/conf.d/99-laesh.ini"
PHP_INI_CLI="/etc/php/8.3/cli/conf.d/99-laesh.ini"
APP_LEVEL_PHP="/opt/laesh/configs/app-log-level.php"
TS() { date '+%Y-%m-%d %H:%M:%S'; }

if [ ! -f "$CONFIG" ]; then
    echo "[$( TS )] [ERROR] $CONFIG no existe" >> "$APPLY_LOG"
    exit 1
fi

echo "[$( TS )] [START] Aplicando log-levels.conf..." >> "$APPLY_LOG"

# ── Leer configuración ────────────────────────────────────────────────────────
parse_conf() {
    local key="$1" default="$2"
    grep -E "^${key}=" "$CONFIG" 2>/dev/null | tail -1 | cut -d= -f2- | tr -d '[:space:]' || echo "$default"
}

NGINX_LEVEL=$(        parse_conf nginx_error_level warn)
MARIADB_SLOW_LOG=$(   parse_conf mariadb_slow_query_log ON)
MARIADB_SLOW_TIME=$(  parse_conf mariadb_slow_query_time 2)
MARIADB_VERBOSITY=$(  parse_conf mariadb_log_error_verbosity 2)
MARIADB_GENERAL_LOG=$(parse_conf mariadb_general_log OFF)
PHP_ERROR_REPORTING=$(parse_conf php_error_reporting production)
APP_LOG_LEVEL=$(      parse_conf app_log_level WARN)

# ── 1. Nginx ──────────────────────────────────────────────────────────────────
NGINX_CONF="/etc/nginx/nginx.conf"
VALID_NGINX_LEVELS="debug|info|notice|warn|error|crit|alert|emerg"

if [[ "$NGINX_LEVEL" =~ ^(debug|info|notice|warn|error|crit|alert|emerg)$ ]]; then
    # Reemplazar nivel en la línea error_log del nginx.conf principal
    if grep -q "error_log.*nginx-error.log" "$NGINX_CONF" 2>/dev/null; then
        sed -i "s|error_log\s*/opt/laesh/logs/nginx-error.log [a-z]*;|error_log  /opt/laesh/logs/nginx-error.log ${NGINX_LEVEL};|" "$NGINX_CONF"
        nginx -t 2>/dev/null && nginx -s reload 2>/dev/null \
            && echo "[$( TS )] [OK] Nginx error_log → ${NGINX_LEVEL} (reload graceful)" >> "$APPLY_LOG" \
            || echo "[$( TS )] [ERROR] Nginx reload falló — revisa nginx -t" >> "$APPLY_LOG"
    else
        echo "[$( TS )] [WARN] Nginx: no se encontró línea error_log esperada en $NGINX_CONF" >> "$APPLY_LOG"
    fi
else
    echo "[$( TS )] [ERROR] nginx_error_level='${NGINX_LEVEL}' inválido (válidos: ${VALID_NGINX_LEVELS})" >> "$APPLY_LOG"
fi

# ── 2. MariaDB (SET GLOBAL — sin reinicio) ────────────────────────────────────
if [ -f "$MARIADB_CNF" ] && command -v mariadb &>/dev/null; then
    MARIADB_SQL="
SET GLOBAL slow_query_log = '${MARIADB_SLOW_LOG}';
SET GLOBAL long_query_time = ${MARIADB_SLOW_TIME};
SET GLOBAL log_error_verbosity = ${MARIADB_VERBOSITY};
SET GLOBAL general_log = '${MARIADB_GENERAL_LOG}';
"
    if mariadb --defaults-extra-file="$MARIADB_CNF" -e "$MARIADB_SQL" 2>/dev/null; then
        echo "[$( TS )] [OK] MariaDB → slow_log=${MARIADB_SLOW_LOG} slow_time=${MARIADB_SLOW_TIME}s verbosity=${MARIADB_VERBOSITY} general_log=${MARIADB_GENERAL_LOG}" >> "$APPLY_LOG"
    else
        echo "[$( TS )] [ERROR] MariaDB SET GLOBAL falló — ¿.mariadb-root.cnf correcto?" >> "$APPLY_LOG"
    fi
else
    echo "[$( TS )] [WARN] MariaDB: .mariadb-root.cnf no encontrado o mariadb no instalado" >> "$APPLY_LOG"
fi

# ── 3. PHP-FPM (error_reporting en ini → reload graceful) ────────────────────
declare -A PHP_REPORTING_MAP=(
    [production]="E_ALL & ~E_DEPRECATED & ~E_STRICT"
    [development]="E_ALL"
    [minimal]="E_ERROR | E_WARNING | E_PARSE"
    [off]="0"   # silencia todos los errores PHP (solo diagnóstico — no usar en prod normal)
)

if [[ -v "PHP_REPORTING_MAP[$PHP_ERROR_REPORTING]" ]]; then
    PHP_REPORTING_VALUE="${PHP_REPORTING_MAP[$PHP_ERROR_REPORTING]}"

    for INI_FILE in "$PHP_INI" "$PHP_INI_CLI"; do
        if [ -f "$INI_FILE" ]; then
            # IMPORTANTE: escapar '&' antes de usarlo en el reemplazo de sed.
            # '&' en sed replacement = "el texto que coincidió" → sin escapar, cada ejecución
            # del script concatena el valor anterior, corrompiendo la línea progresivamente.
            _PHP_REP_ESCAPED="${PHP_REPORTING_VALUE//&/\\&}"
            sed -i "s|^error_reporting[[:space:]]*=.*|error_reporting = ${_PHP_REP_ESCAPED}|" "$INI_FILE"
        fi
    done

    if systemctl reload php8.3-fpm 2>/dev/null; then
        echo "[$( TS )] [OK] PHP-FPM error_reporting → ${PHP_ERROR_REPORTING} (${PHP_REPORTING_VALUE}) — reload graceful" >> "$APPLY_LOG"
    else
        echo "[$( TS )] [ERROR] PHP-FPM reload falló" >> "$APPLY_LOG"
    fi
else
    echo "[$( TS )] [ERROR] php_error_reporting='${PHP_ERROR_REPORTING}' inválido (válidos: production|development|minimal)" >> "$APPLY_LOG"
fi

# ── 4. App PHP — Logger.php (archivo PHP leído en cada log call) ──────────────
# Logger.php puede incluir este archivo para conocer el nivel mínimo activo.
# OPcache: como validate_timestamps=0, se invalida manualmente tras escritura.
VALID_APP_LEVELS="DEBUG|INFO|WARN|ERROR|CRITICAL"

if [[ "$APP_LOG_LEVEL" =~ ^(DEBUG|INFO|WARN|ERROR|CRITICAL)$ ]]; then
    cat > "$APP_LEVEL_PHP" << PHP
<?php
// Auto-generado por apply_log_levels.sh — NO editar manualmente.
// Editar /opt/laesh/logs/log-levels.conf y guardar para regenerar.
// Generado: $( TS )
return ['app_log_level' => '${APP_LOG_LEVEL}'];
PHP
    # Invalidar OPcache del archivo recién escrito
    if command -v php8.3 &>/dev/null; then
        php8.3 -r "if(function_exists('opcache_invalidate')) opcache_invalidate('${APP_LEVEL_PHP}', true);" 2>/dev/null || true
    fi
    echo "[$( TS )] [OK] App PHP log_level → ${APP_LOG_LEVEL} — ${APP_LEVEL_PHP} actualizado" >> "$APPLY_LOG"
else
    echo "[$( TS )] [ERROR] app_log_level='${APP_LOG_LEVEL}' inválido (válidos: ${VALID_APP_LEVELS})" >> "$APPLY_LOG"
fi

echo "[$( TS )] [DONE] Todos los niveles aplicados." >> "$APPLY_LOG"
exit 0
