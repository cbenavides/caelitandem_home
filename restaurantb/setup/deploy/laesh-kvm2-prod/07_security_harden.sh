#!/usr/bin/env bash
# ==============================================================================
# LAESH KVM2 · Paso 7 — Security Hardening
# UFW, OPcache, backup cron, logrotate, SSH (opcional con flag).
# Idempotente.
#
# Uso:
#   sudo bash 07_security_harden.sh             # con SSH hardening
#   sudo bash 07_security_harden.sh --skip-ssh  # sin SSH (primera vez sin llave pública)
# ==============================================================================
set -euo pipefail
[ "$EUID" -ne 0 ] && { echo "[ERROR] Requiere sudo"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  △${NC} $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; exit 1; }
log()  { echo "  → $*"; }

SKIP_SSH=false; [[ "${1:-}" == "--skip-ssh" ]] && SKIP_SSH=true
LAESH_ROOT_PASS="${LAESH_ROOT_PASS:-}"
LAESH_APP_PASS="${LAESH_APP_PASS:-}"
LAESH_JWT_SECRET="${LAESH_JWT_SECRET:-}"
[[ -z "$LAESH_APP_PASS" ]] && warn "LAESH_APP_PASS no definida — cron cache_renew no tendrá contraseña BD (warm-up de BD fallará)"
# Incidente 2026-09-19: sin esta variable, cache_renew.php y cms_cleanup.php
# fallan fail-loud en el bootstrap de commons.php (Gap 1 — config.php exige
# LAESH_JWT_SECRET en producción) y lo hacen en silencio total, porque
# display_errors=Off en CLI — nada llega a cache-renew.log/cms-cleanup.log,
# solo un stack trace en php-fpm-error.log.
[[ -z "$LAESH_JWT_SECRET" ]] && warn "LAESH_JWT_SECRET no definida — cache_renew y cms_cleanup fallarán en silencio (Gap 1 fail-loud)"

# ── 1. UFW ────────────────────────────────────────────────────────────────────
echo "── 1/8 UFW Firewall ──────────────────────────────────────────"
apt-get install -yq ufw 2>/dev/null | grep -v '^$' || true
ufw --force reset > /dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp   comment 'HTTP'
ufw allow 443/tcp  comment 'HTTPS'
ufw deny 3306/tcp  comment 'MariaDB (no exponer)'
ufw deny 9502/tcp  comment 'Swoole bridge (solo loopback)'
ufw --force enable
ufw status numbered
ok "UFW activo — 22, 80, 443 permitidos; 3306, 9502 bloqueados"

# ── 2. OPcache + Cache L2 ─────────────────────────────────────────────────────
echo ""
echo "── 2/8 OPcache PHP 8.3 + Cache L2 ───────────────────────────"

# Copiar ini completo desde /opt/laesh/configs/ (instalado por 01_preflight.sh)
SRC_OPCACHE="/opt/laesh/configs/10-opcache-laesh.ini"
DST_FPM="/etc/php/8.3/fpm/conf.d/10-opcache-laesh.ini"
DST_CLI="/etc/php/8.3/cli/conf.d/10-opcache-laesh.ini"

if [ -f "$SRC_OPCACHE" ]; then
    cp "$SRC_OPCACHE" "$DST_FPM"
    # CLI: misma config pero SIN JIT (P-INFRA-02).
    # opcache.jit=tracing + opcache.enable_cli=1 + extension=swoole.so → hang indefinido en CLI.
    # PHP-FPM no se ve afectado (proceso separado, sin el conflicto de extensiones en CLI).
    sed 's/^opcache\.jit=.*/opcache.jit=0/' "$SRC_OPCACHE" \
        | sed 's/^opcache\.jit_buffer_size=.*/opcache.jit_buffer_size=0M/' \
        | sed '1s/^/; CLI: JIT deshabilitado — P-INFRA-02 (Swoole+JIT CLI = hang)\n/' \
        > "$DST_CLI"
    ok "OPcache ini: FPM (JIT tracing activo) + CLI (JIT=0 — P-INFRA-02 fix)"
else
    warn "10-opcache-laesh.ini no encontrado en /opt/laesh/configs/ — usando inline"
    cat > "$DST_FPM" << 'OPCACHE'
; OPcache — LAESH KVM2 producción FPM (fallback inline)
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=4000
opcache.validate_timestamps=0
opcache.jit=tracing
opcache.jit_buffer_size=64M
OPCACHE
    # CLI sin JIT (P-INFRA-02 — Swoole + JIT CLI = hang indefinido)
    sed 's/^opcache\.jit=.*/opcache.jit=0/' "$DST_FPM" \
        | sed 's/^opcache\.jit_buffer_size=.*/opcache.jit_buffer_size=0M/' \
        | sed '1s/^/; CLI: JIT deshabilitado — P-INFRA-02\n/' \
        > "$DST_CLI"
fi

systemctl reload php8.3-fpm
ok "OPcache configurado — FPM: bytecode RAM + JIT tracing | CLI: bytecode RAM (sin JIT, P-INFRA-02)"

# Cache renew cron (Cache L2 warm-up diario 5 AM — §15.9.6 Tecnica_Infraestructura)
CACHE_CRON_SRC="/opt/laesh/crones/cache_renew.cron"
CACHE_CRON_DST="/etc/cron.d/laesh-cache-renew"
if [ -f "$CACHE_CRON_SRC" ]; then
    # Copiar y sustituir __LAESH_APP_PASS__ / __LAESH_JWT_SECRET__ (igual que en
    # php-fpm-laesh.conf). El cron necesita ambas para que config.php arranque
    # en CLI: LAESH_DB_PASS para MariaDB, LAESH_JWT_SECRET porque config.php
    # falla fail-loud sin ella (Gap 1, incidente 2026-09-19).
    sed -e "s/__LAESH_APP_PASS__/${LAESH_APP_PASS}/g" \
        -e "s/__LAESH_JWT_SECRET__/${LAESH_JWT_SECRET}/g" \
        "$CACHE_CRON_SRC" > "$CACHE_CRON_DST"
    chmod 640 "$CACHE_CRON_DST"   # 640: root lee, www-data no necesita leer el archivo
    ok "Cron cache_renew instalado (@reboot + 5 AM diario, www-data)"
else
    # Fallback inline (sin LAESH_DB_PASS/LAESH_JWT_SECRET — el cron fallará al
    # bootstrapear commons.php hasta que se corrijan manualmente en el archivo)
    cat > "$CACHE_CRON_DST" << 'CRON'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LAESH_CACHE_DIR=/opt/laesh/cache
LAESH_DB_HOST=127.0.0.1
LAESH_DB_PORT=3306
LAESH_DB_USER=laesh_app
LAESH_DB_NAME=laesh_db
APP_ENV=production
0 5 * * * www-data /usr/bin/php8.3 /opt/laesh/www/laesh-swbldi/crons/cache_renew.php >> /opt/laesh/logs/cache-renew.log 2>&1
1 5 * * * www-data sleep 5 && curl -sf -k https://127.0.0.1/ -H "Host: localhost" -o /dev/null --max-time 15 >> /opt/laesh/logs/cache-renew.log 2>&1
@reboot www-data sleep 90 && /usr/bin/php8.3 /opt/laesh/www/laesh-swbldi/crons/cache_renew.php >> /opt/laesh/logs/cache-renew-boot.log 2>&1 && sleep 15 && curl -sf -k https://127.0.0.1/ -H "Host: localhost" -o /dev/null --max-time 15 >> /opt/laesh/logs/cache-renew-boot.log 2>&1
CRON
    chmod 640 "$CACHE_CRON_DST"
    warn "cache_renew.cron fuente no encontrado — instalado fallback (sin LAESH_DB_PASS ni LAESH_JWT_SECRET)"
fi

# ── 2b. CMS cleanup cron (diario 01:00 AM) ───────────────────────────────────
CMS_CLEANUP_SRC="/opt/laesh/crones/cms-cleanup.cron"
CMS_CLEANUP_DST="/etc/cron.d/laesh-cms-cleanup"
if [ -f "$CMS_CLEANUP_SRC" ]; then
    sed -e "s/__LAESH_APP_PASS__/${LAESH_APP_PASS}/g" \
        -e "s/__LAESH_JWT_SECRET__/${LAESH_JWT_SECRET}/g" \
        "$CMS_CLEANUP_SRC" > "$CMS_CLEANUP_DST"
    chmod 640 "$CMS_CLEANUP_DST"
    ok "Cron cms-cleanup instalado (1 AM diario, www-data)"
else
    # Fallback inline si el archivo fuente no llegó (sin LAESH_APP_PASS/LAESH_JWT_SECRET)
    cat > "$CMS_CLEANUP_DST" << 'CRON'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LAESH_DB_HOST=127.0.0.1
LAESH_DB_PORT=3306
LAESH_DB_USER=laesh_app
LAESH_DB_NAME=laesh_db
APP_ENV=production
0 1 * * * www-data /usr/bin/php8.3 /opt/laesh/www/laesh-swbldi/crons/cms_cleanup.php >> /opt/laesh/logs/cms-cleanup.log 2>&1
CRON
    chmod 640 "$CMS_CLEANUP_DST"
    warn "cms-cleanup.cron fuente no encontrado — instalado fallback (sin LAESH_APP_PASS ni LAESH_JWT_SECRET)"
fi

# ── 2c. Logrotate — reinstalar config + fix inmediato de ownership ────────────
# BUG-LOGROTATE-01 (2026-09-13): el bloque único de mantenimiento usaba
# "create root adm" para todos los logs, incluyendo cms-cleanup.log y
# cache-renew.log, que son escritos por www-data. Post-rotación nocturna
# www-data no podía escribir → logs en 0 bytes aunque el cron sí se disparaba.
# Fix: logrotate-laesh.conf ahora tiene dos bloques separados por owner.
# Este step reinstala la config correcta Y corrige el ownership de los archivos
# que logrotate ya creó mal (fix inmediato sin esperar al próximo ciclo de cron).
echo ""
echo "── 2c/8 Logrotate — reinstalar config (BUG-LOGROTATE-01) ────"
LOGROTATE_SRC="/opt/laesh/crones/logrotate-laesh.conf"
if [ -f "$LOGROTATE_SRC" ]; then
    cp "$LOGROTATE_SRC" /etc/logrotate.d/laesh
    chmod 644 /etc/logrotate.d/laesh
    ok "Logrotate reinstalado → /etc/logrotate.d/laesh"
    ok "  cms-cleanup.log + cache-renew*.log → create 0640 www-data www-data"
    ok "  backup/monitor/disk/alerts logs    → create 0640 root adm (sin cambio)"
else
    warn "logrotate-laesh.conf no encontrado en /opt/laesh/crones/ — saltando reinstalación"
    warn "  Desplegar primero con deploy.sh y volver a ejecutar este script"
fi

# Fix inmediato: corregir ownership de archivos ya creados con root:adm incorrecto.
# Idempotente: solo hace chown si el owner actual NO es www-data.
for _log in \
    /opt/laesh/logs/cms-cleanup.log \
    /opt/laesh/logs/cache-renew.log \
    /opt/laesh/logs/cache-renew-boot.log; do
    if [ -f "$_log" ]; then
        _owner=$(stat -c '%U' "$_log")
        if [ "$_owner" != "www-data" ]; then
            chown www-data:www-data "$_log"
            ok "Chown www-data:www-data → ${_log} (era ${_owner}:$(stat -c '%G' "$_log"))"
        else
            ok "${_log} — ya es www-data (sin cambio)"
        fi
    fi
done

# BUG-LOGROTATE-02 (2026-09-18, hallado durante fix de seguridad WS §2.4c):
# /opt/laesh/logs/ es root:adm 755 por diseño (convención estándar — logrotate
# gestiona el `create` de cada archivo ya rotado). Pero swoole-laesh.service corre
# 100% como www-data desde el arranque (a diferencia de nginx/php-fpm, cuyo master
# arranca como root y puede crear su propio log antes de bajar privilegios) — su
# PRIMER intento de escribir swoole.log falla con "Permission denied" porque
# www-data no puede CREAR un archivo nuevo en un directorio root:adm (aunque el
# archivo, una vez creado, sí sería escribible según logrotate-laesh.conf). Mismo
# patrón que BUG-LOGROTATE-01 arriba — se resuelve igual: pre-crear el archivo con
# el owner correcto ANTES de que el servicio lo necesite. Directorio NO se toca.
if [ ! -f /opt/laesh/logs/swoole.log ]; then
    touch /opt/laesh/logs/swoole.log
    chown www-data:www-data /opt/laesh/logs/swoole.log
    chmod 0640 /opt/laesh/logs/swoole.log
    ok "swoole.log pre-creado (www-data:www-data, 0640) — evita 'Permission denied' en primer arranque"
else
    _owner=$(stat -c '%U' /opt/laesh/logs/swoole.log)
    if [ "$_owner" != "www-data" ]; then
        chown www-data:www-data /opt/laesh/logs/swoole.log
        ok "Chown www-data:www-data → swoole.log (era ${_owner}:$(stat -c '%G' /opt/laesh/logs/swoole.log))"
    else
        ok "swoole.log — ya es www-data (sin cambio)"
    fi
fi

# ── 3. Disk monitor cron (diario 06:00 AM) ───────────────────────────────────
echo ""
echo "── 3/8 Disk monitor cron ─────────────────────────────────────"
DISK_SCRIPT="/opt/laesh/scripts/disk_monitor.sh"
if [ -f "$DISK_SCRIPT" ]; then
    chmod +x "$DISK_SCRIPT"
    DISK_CRON="0 6 * * * root bash ${DISK_SCRIPT} >> /opt/laesh/logs/disk-monitor.log 2>&1"
    if ! grep -qF "$DISK_SCRIPT" /etc/cron.d/laesh-disk-monitor 2>/dev/null; then
        echo "$DISK_CRON" > /etc/cron.d/laesh-disk-monitor
        chmod 644 /etc/cron.d/laesh-disk-monitor
        ok "Cron disk monitor diario (06:00, root)"
    else
        warn "Cron disk monitor ya existía"
    fi
else
    warn "disk_monitor.sh no encontrado en /opt/laesh/scripts/ — monitoreo de disco deshabilitado"
fi

# ── 4. SMTP swaks.conf + monitor_services cron + log-levels systemd ──────────
echo ""
echo "── 4/8 SMTP / Monitor / Log-levels ──────────────────────────"

# 4a. Substituir __SMTP_PASS__ en swaks.conf y proteger con 600
SWAKS_SRC="/opt/laesh/configs/swaks.conf"
SMTP_PASS="${LAESH_SMTP_PASS:-}"
if [ -f "$SWAKS_SRC" ]; then
    # Permisos siempre — independiente de si la pass está definida
    chown root:root "$SWAKS_SRC"
    chmod 600 "$SWAKS_SRC"
    if [[ -n "$SMTP_PASS" ]]; then
        sed -i "s/__SMTP_PASS__/${SMTP_PASS}/g" "$SWAKS_SRC"
        ok "swaks.conf protegido (600 root:root) + pass sustituida — SMTP listo"
    else
        warn "LAESH_SMTP_PASS no definida — swaks.conf tiene placeholder __SMTP_PASS__"
        warn "  Sustituir manualmente: sudo sed -i 's/__SMTP_PASS__/TU_PASS/' ${SWAKS_SRC}"
        ok "swaks.conf permisos: 600 root:root (archivo protegido aunque pass sea manual)"
    fi
else
    warn "swaks.conf no encontrado en /opt/laesh/configs/ — alertas SMTP deshabilitadas"
fi

# 4a-2. Smoke test SMTP (opcional — reporta resultado pero no detiene el pipeline)
TEST_SMTP_SCRIPT="/opt/laesh/scripts/test_smtp.sh"
if [ -f "$TEST_SMTP_SCRIPT" ] && [[ -n "$SMTP_PASS" ]]; then
    chmod +x "$TEST_SMTP_SCRIPT"
    log "Ejecutando smoke test SMTP..."
    if bash "$TEST_SMTP_SCRIPT" >> /opt/laesh/logs/alerts-smtp.log 2>&1; then
        ok "SMTP smoke test OK — correo de prueba enviado"
    else
        warn "SMTP smoke test falló (exit $?) — revisar: /opt/laesh/logs/alerts-smtp.log"
        warn "  Correr manualmente para diagnóstico: sudo bash ${TEST_SMTP_SCRIPT}"
    fi
elif [ -f "$TEST_SMTP_SCRIPT" ] && [[ -z "$SMTP_PASS" ]]; then
    warn "SMTP smoke test omitido — LAESH_SMTP_PASS no definida"
fi

# 4a-3. SMTP check diario (08:30 AM, root) — verifica conectividad sin enviar email
SMTP_CHECK_SCRIPT="/opt/laesh/scripts/check_smtp.sh"
if [ -f "$SMTP_CHECK_SCRIPT" ]; then
    chmod +x "$SMTP_CHECK_SCRIPT"
    SMTP_CHECK_CRON="30 8 * * * root bash ${SMTP_CHECK_SCRIPT} >> /opt/laesh/logs/smtp-check.log 2>&1"
    if ! grep -qF "$SMTP_CHECK_SCRIPT" /etc/cron.d/laesh-smtp-check 2>/dev/null; then
        echo "$SMTP_CHECK_CRON" > /etc/cron.d/laesh-smtp-check
        chmod 644 /etc/cron.d/laesh-smtp-check
        ok "Cron SMTP check diario (08:30, root) → /opt/laesh/logs/smtp-check.log"
    else
        warn "Cron SMTP check ya existía"
    fi
else
    warn "check_smtp.sh no encontrado en /opt/laesh/scripts/ — SMTP check diario deshabilitado"
fi

# 4b. Monitor services cron (cada 10 min, root, con flock anti-solapamiento)
MONITOR_SCRIPT="/opt/laesh/scripts/monitor_services.sh"
if [ -f "$MONITOR_SCRIPT" ]; then
    chmod +x "$MONITOR_SCRIPT"
    chmod +x /opt/laesh/scripts/send_alert.sh 2>/dev/null || true
    MONITOR_CRON="*/10 * * * * root bash ${MONITOR_SCRIPT} >> /opt/laesh/logs/monitor-services.log 2>&1"
    if ! grep -qF "$MONITOR_SCRIPT" /etc/cron.d/laesh-monitor 2>/dev/null; then
        echo "$MONITOR_CRON" > /etc/cron.d/laesh-monitor
        chmod 644 /etc/cron.d/laesh-monitor
        ok "Cron monitor_services instalado (cada 10 min, root)"
    else
        warn "Cron monitor_services ya existía"
    fi
    # Crear directorio de estado del monitor (archivos .last_alert por servicio)
    mkdir -p /opt/laesh/monitor
    ok "Directorio de estado del monitor: /opt/laesh/monitor/"
else
    warn "monitor_services.sh no encontrado — monitoreo de servicios deshabilitado"
fi

# 4c. Log-levels systemd path unit (hot-reload de log-levels.conf vía inotify)
# Copiar log-levels.conf a destino si no existe (no sobreescribir si ya fue editado)
LOG_LEVELS_CONF="/opt/laesh/logs/log-levels.conf"
if [ ! -f "$LOG_LEVELS_CONF" ]; then
    # Buscar fuente del pipeline en orden de preferencia
    # (paso 1 ya debería haberlo copiado desde ${SETUP_DIR}/logs/; esto es fallback)
    for src in \
        "/home/sysadmin/staging/setup/deploy/laesh-kvm2-prod/logs/log-levels.conf" \
        "/home/sysadmin/staging/setup/logs/log-levels.conf"; do
        [ -f "$src" ] && { cp "$src" "$LOG_LEVELS_CONF"; ok "log-levels.conf copiado desde ${src}"; break; }
    done
fi
[ -f "$LOG_LEVELS_CONF" ] || cat > "$LOG_LEVELS_CONF" << 'LOGCONF'
nginx_error_level=warn
mariadb_slow_query_log=ON
mariadb_slow_query_time=2
mariadb_log_error_verbosity=2
mariadb_general_log=OFF
php_error_reporting=production
app_log_level=WARN
LOGCONF

chmod +x /opt/laesh/scripts/apply_log_levels.sh 2>/dev/null || true

# Permisos 664 root:www-data para que PHP-FPM (www-data) pueda escribir el archivo
# desde admrc/views/sistema.php (tab Infra — log-levels en caliente).
chown root:www-data "$LOG_LEVELS_CONF"
chmod 664 "$LOG_LEVELS_CONF"
ok "log-levels.conf permisos: 664 root:www-data (editable desde admrc/sistema?tab=infra)"

# Instalar systemd path unit y service
for unit in laesh-log-levels.path laesh-log-levels.service; do
    SRC_UNIT="/opt/laesh/configs/${unit}"
    [ -f "$SRC_UNIT" ] && cp "$SRC_UNIT" "/etc/systemd/system/${unit}"
done

systemctl daemon-reload
# reset-failed antes de enable/start para que re-ejecuciones no queden bloqueadas
# por un fallo anterior del service (oneshot que falló en initial apply).
systemctl reset-failed laesh-log-levels.path laesh-log-levels.service 2>/dev/null || true
systemctl enable laesh-log-levels.path 2>/dev/null || true
if systemctl is-active --quiet laesh-log-levels.path; then
    ok "laesh-log-levels.path ya activo — editar /opt/laesh/logs/log-levels.conf para cambiar niveles en caliente"
elif systemctl start laesh-log-levels.path 2>/dev/null; then
    ok "laesh-log-levels.path activo — editar /opt/laesh/logs/log-levels.conf para cambiar niveles en caliente"
else
    warn "laesh-log-levels.path no pudo activarse:"
    systemctl status laesh-log-levels.path --no-pager 2>/dev/null | tail -5 | sed 's/^/    /' || true
fi

# Aplicar niveles iniciales desde el config
bash /opt/laesh/scripts/apply_log_levels.sh 2>/dev/null \
    && ok "Log levels aplicados (initial apply)" \
    || warn "apply_log_levels.sh falló en aplicación inicial — verificar /opt/laesh/logs/apply-log-levels.log"

# ── 5. Backup cron (mysqldump horario) ────────────────────────────────────────
echo ""
echo "── 5/8 Backup BD cron ────────────────────────────────────────"
BACKUP_SCRIPT="/opt/laesh/scripts/backup_db.sh"
if [ -f "$BACKUP_SCRIPT" ]; then
    chmod +x "$BACKUP_SCRIPT"
    CRON_LINE="0 20 * * * root bash ${BACKUP_SCRIPT} >> /opt/laesh/logs/backup-db.log 2>&1"
    if ! grep -qF "$BACKUP_SCRIPT" /etc/cron.d/laesh-backup 2>/dev/null; then
        echo "$CRON_LINE" > /etc/cron.d/laesh-backup
        chmod 644 /etc/cron.d/laesh-backup
        ok "Cron backup diario 20:00 instalado"
    else
        warn "Cron backup ya existía"
    fi
else
    warn "backup_db.sh no encontrado en /opt/laesh/scripts/ — instalar scripts primero"
fi

# ── 5. Check expiry cert cron (semanal) ───────────────────────────────────────
echo ""
echo "── 6/8 Cron check cert expiry ───────────────────────────────"
CHECK_SCRIPT="/opt/laesh/crones/check_cert_expiry.sh"
if [ -f "$CHECK_SCRIPT" ]; then
    chmod +x "$CHECK_SCRIPT"
    CRON_CERT="0 8 * * 1 root bash ${CHECK_SCRIPT} >> /opt/laesh/logs/cert-expiry.log 2>&1"
    if ! grep -qF "$CHECK_SCRIPT" /etc/cron.d/laesh-cert-check 2>/dev/null; then
        echo "$CRON_CERT" > /etc/cron.d/laesh-cert-check
        chmod 644 /etc/cron.d/laesh-cert-check
        ok "Cron check cert semanal (lunes 08:00)"
    else
        warn "Cron cert check ya existía"
    fi
else
    warn "check_cert_expiry.sh no encontrado en /opt/laesh/crones/"
fi

# ── 7. MariaDB Least Privilege (opcional) ───────────────────────────────────────────────
echo ""
echo "── 7/8 MariaDB — Verificar Least Privilege laesh_app ────────"
# El usuario laesh_app debe tener solo DML (SELECT, INSERT, UPDATE, DELETE).
# setup_hostinger.sh ya lo crea así. Este paso solo verifica y alerta si hay GRANT extra.
if command -v mariadb &>/dev/null; then
    # Usar .mariadb-root.cnf si existe (creado por paso 4 con host=localhost socket).
    # Fallback unix_socket sin contraseña (solo funciona en fresh install pre-paso-4).
    # Sin esto, mariadb -u root falla con "Access denied" y GRANTS queda vacío
    # → grep silencioso → falso positivo "Least Privilege verificado".
    _MCNF_07="/opt/laesh/configs/.mariadb-root.cnf"
    if [ -f "$_MCNF_07" ]; then
        GRANTS=$(mariadb --defaults-extra-file="$_MCNF_07" \
                    -e "SHOW GRANTS FOR 'laesh_app'@'localhost';" 2>/dev/null || echo "")
    else
        GRANTS=$(mariadb -u root \
                    -e "SHOW GRANTS FOR 'laesh_app'@'localhost';" 2>/dev/null || echo "")
    fi
    if echo "$GRANTS" | grep -Eqi 'ALL PRIVILEGES|DROP|ALTER|CREATE|INDEX|LOCK'; then
        warn "⚠ laesh_app tiene permisos EXCESIVOS. Revisar SHOW GRANTS FOR 'laesh_app'@'localhost';"
        warn "  Solo debe tener: SELECT, INSERT, UPDATE, DELETE ON laesh_db.*"
    else
        ok "laesh_app — Least Privilege verificado (solo DML)"
    fi
else
    warn "MariaDB no disponible — verificar manualmente: SHOW GRANTS FOR 'laesh_app'@'localhost';"
fi

echo ""
echo "── 8/8 SSH Hardening ─────────────────────────────────────────"
if $SKIP_SSH; then
    warn "SSH hardening omitido (--skip-ssh). Ejecutar sin el flag cuando haya llave pública en authorized_keys."
else
    # Verificar que existe llave pública antes de deshabilitar password.
    # No usar grep -c en cadena con || dentro de $() — captura stdout de TODOS
    # los comandos que corren, produciendo "0\n0" en lugar de "0" → falla -eq.
    _HAS_PUBKEY=false
    grep -qE 'ssh-|ecdsa-|sk-' /root/.ssh/authorized_keys 2>/dev/null && _HAS_PUBKEY=true
    grep -qE 'ssh-|ecdsa-|sk-' /home/sysadmin/.ssh/authorized_keys 2>/dev/null && _HAS_PUBKEY=true
    if ! $_HAS_PUBKEY; then
        warn "⚠ No se encontró llave pública en authorized_keys."
        warn "  SSH hardening OMITIDO para evitar bloqueo de acceso."
        warn "  Agrega tu llave pública y re-ejecuta: sudo bash 07_security_harden.sh"
    else
        SSHD="/etc/ssh/sshd_config"
        cp "$SSHD" "${SSHD}.bak-$(date +%F)"
        sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/'          "$SSHD"
        sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' "$SSHD"
        sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/'   "$SSHD"
        sed -i 's/^#\?MaxAuthTries .*/MaxAuthTries 3/'                  "$SSHD"
        # Ubuntu 24.04 usa ssh.service (no sshd.service); detectar cuál existe.
        _SSH_SVC="$(systemctl list-unit-files --type=service 2>/dev/null \
                    | grep -oE '^sshd?\.service' | head -1 | sed 's/\.service//')"
        _SSH_SVC="${_SSH_SVC:-ssh}"
        # Ubuntu 24.04 / Hostinger: cloud-init crea 50-cloud-init.conf con
        # PasswordAuthentication yes, que gana sobre sshd_config porque el Include
        # está al inicio (línea 12) y OpenSSH aplica la primera ocurrencia.
        # Neutralizar ese override para que nuestro hardening tenga efecto real.
        _CLOUDINIT_CONF="/etc/ssh/sshd_config.d/50-cloud-init.conf"
        if [[ -f "${_CLOUDINIT_CONF}" ]]; then
            sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' "${_CLOUDINIT_CONF}" 2>/dev/null || true
            ok "cloud-init SSH override neutralizado (50-cloud-init.conf → PasswordAuthentication no)"
        fi
        sshd -t && systemctl reload "$_SSH_SVC"
        ok "SSH: root login off, password off, pubkey only, MaxAuthTries=3"
        # Verificar que la config efectiva sea correcta (sshd -T lee la config cargada)
        if sshd -T 2>/dev/null | grep -q "^passwordauthentication yes"; then
            warn "⚠ sshd -T aún muestra passwordauthentication yes — revisar sshd_config.d manualmente"
        else
            ok "Verificado: sshd -T confirma passwordauthentication no"
        fi
    fi
fi

echo ""
ok "Security hardening completo"
