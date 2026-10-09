#!/usr/bin/env bash
# ==============================================================================
# LAESH — limpiar_pruebas_uat.sh   (uso MANUAL en KVM2, base laesh_db)
#
# Deja los portales de Block Digital limpios de datos operativos de prueba para
# liberar el ambiente UAT (User Acceptance Testing):
#   - Solicitudes (Hoy / Anteriores): purga total de ordenes y pacientes.
#   - Indicadores y Estadísticas: reinicio a 0 en base de datos.
#   - Trazabilidad y Auditoría: purga de historial_estados_orden y resultados_pdf.
#   - Notificaciones: purga de notificaciones del sistema y websocket.
#   - Folios: reinicio de folios_control a 0 (la próxima solicitud será Folio #1).
#   - Médicos: se resetea total_ordenes = 0 para todos los médicos legítimos.
#
# CONSERVACIÓN DE CATÁLOGOS Y CUENTAS LEGÍTIMAS (creadas antes de las 12:00 PM):
#   - Cuentas conservadas (7 usuarios activos):
#       * Administradores: Jacob Santiago Blanco (1), Carlos Benavides (173)
#       * Recepción: Jacob Santiago Blanco (178)
#       * Médicos: Dr. Hedilbero Reyes (174), Dr. Felipe Perez (175),
#                  Dra. Lucia Diaz (176), Dr. Eduardo Garcia (177)
#   - Catálogos UI conservados (53 elementos activos):
#       * Universidades (23), Lugares de Trabajo (18), Especialidades (12)
#   - Catálogo de Estudios y Promociones: 100% intactos (cat_*, rel_*, promociones)
#   - CMS y Web Contenidos: 100% intactos (web_contenidos)
#
# PURGA DE SEED LOCAL (cuentas de prueba >= 179 creadas tras las 3:00 PM):
#   - Elimina usuarios 9990000001..7 (Admin LAESH, Recepción Demo, Médicos Demo 1..5)
#   - Elimina sesiones huérfanas, tokens JWT, throttling y registros 2FA asociados.
#
# Uso:
#   bash limpiar_pruebas_uat.sh            # pide confirmación escrita (LIMPIAR)
#   bash limpiar_pruebas_uat.sh --yes      # ejecución directa sin confirmación
#
# Requiere sudo. Realiza backup previo con backup_db.sh antes de cualquier cambio.
# ==============================================================================
set -euo pipefail

DB="laesh_db"
MCNF="/opt/laesh/configs/.mariadb-root.cnf"
BACKUP_SCRIPT="/opt/laesh/scripts/backup_db.sh"
CUTOFF_USER_ID=179   # Cuentas con ID >= 179 corresponden al seed de prueba local post-3pm
ASSUME_YES=false
[[ "${1:-}" == "--yes" ]] && ASSUME_YES=true

SQL() { sudo mariadb --defaults-extra-file="$MCNF" "$DB" "$@"; }

echo "=========================================================="
echo "🧹 [LAESH] Limpieza Integral para Ciclo de Pruebas UAT"
echo "   Base de Datos: $DB"
echo "=========================================================="

# ── 0. Resumen Pre-Vuelo ───────────────────────────────────────────────────────
echo ""
echo "📊 Estado actual antes de la limpieza:"
SQL -e "
SELECT 'ordenes (solicitudes operativas)' entidad, COUNT(*) total FROM ordenes
UNION ALL SELECT 'pacientes', COUNT(*) FROM pacientes
UNION ALL SELECT 'historial_estados_orden (trazabilidad)', COUNT(*) FROM historial_estados_orden
UNION ALL SELECT 'resultados_pdf', COUNT(*) FROM resultados_pdf
UNION ALL SELECT 'notificaciones', COUNT(*) FROM notificaciones
UNION ALL SELECT 'catalogos_ui (Universidades/Lugares/Especialidades)', COUNT(*) FROM catalogos_ui
UNION ALL SELECT 'perfiles_medicos (totales)', COUNT(*) FROM perfiles_medicos
UNION ALL SELECT 'empleados (todos los roles)', COUNT(*) FROM empleados
UNION ALL SELECT 'users (cuentas totales)', COUNT(*) FROM users;
"

echo ""
echo "📋 Cuentas que PERMANECERÁN activas (Pre-12 PM):"
SQL -e "
SELECT u.id user_id, u.username, u.email, e.rol, e.activo
FROM users u
JOIN empleados e ON e.user_id = u.id
WHERE u.id < $CUTOFF_USER_ID
ORDER BY e.rol, u.id;
"

echo ""
echo "🗑️  Cuentas de seed de prueba que SERÁN ELIMINADAS (>= 179):"
SQL -e "
SELECT u.id user_id, u.username, u.email, e.rol
FROM users u
LEFT JOIN empleados e ON e.user_id = u.id
WHERE u.id >= $CUTOFF_USER_ID
ORDER BY u.id;
"

if ! $ASSUME_YES; then
    echo ""
    read -r -p "⚠️  Escribe LIMPIAR para proceder con el saneamiento UAT: " CONF
    [ "$CONF" = "LIMPIAR" ] || { echo "Cancelado por el usuario. Nada fue modificado."; exit 1; }
fi

# ── 1. BACKUP PREVIO AUTOMATIZADO ─────────────────────────────────────────────
echo ""
echo "💾 Ejecutando respaldo previo con $BACKUP_SCRIPT ..."
if [ -f "$BACKUP_SCRIPT" ]; then
    sudo bash "$BACKUP_SCRIPT"
else
    echo "⚠️  $BACKUP_SCRIPT no encontrado; ejecutando mariadb-dump directo de emergencia..."
    sudo mkdir -p /opt/laesh/backups/db/
    sudo mariadb-dump --defaults-extra-file="$MCNF" --single-transaction --routines --triggers --events --add-drop-table "$DB" | gzip -9 > "/opt/laesh/backups/db/laesh_db_pre_uat_$(date +%Y%m%d_%H%M%S).sql.gz"
fi

BK=$(sudo ls -1t /opt/laesh/backups/db/laesh_db_*.sql.gz 2>/dev/null | head -1)
[ -n "$BK" ] || { echo "❌ ERROR: No se generó el respaldo; abortando sin modificar la BD."; exit 1; }
echo "✓ Respaldo verificado: $BK ($(sudo du -h "$BK" | cut -f1))"
echo "  Comando de restauración ante rollback:"
echo "    gunzip -c $BK | sudo mariadb --defaults-extra-file=$MCNF $DB"

# ── 2. SQL: SANEAMIENTO DE DATOS OPERATIVOS Y CUENTAS DE PRUEBA ───────────────
echo ""
echo "⚙️  Ejecutando sentencias de limpieza SQL..."
SQL <<SQL_CLEANUP
SET FOREIGN_KEY_CHECKS = 0;

-- 2.1 Ciclo de Solicitudes, Pacientes y Trazabilidad (Reseteo de AUTO_INCREMENT a 1)
TRUNCATE TABLE \`historial_estados_orden\`;
TRUNCATE TABLE \`resultados_pdf\`;
TRUNCATE TABLE \`ordenes\`;
TRUNCATE TABLE \`pacientes\`;

-- 2.2 Compatibilidad retroactiva: detalle_ordenes si existiera
SET @t_det = (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'detalle_ordenes');
SET @s_det = IF(@t_det > 0, 'TRUNCATE TABLE detalle_ordenes', 'DO 0');
PREPARE st_det FROM @s_det; EXECUTE st_det; DEALLOCATE PREPARE st_det;

-- 2.3 Notificaciones operativas y en tiempo real
TRUNCATE TABLE \`notificaciones\`;

-- 2.4 Control de Folios (Próxima orden generará estrictamente el Folio #1)
INSERT INTO \`folios_control\` (\`tipo_documento\`, \`ultimo_folio\`)
VALUES ('orden_laboratorio', 0)
ON DUPLICATE KEY UPDATE \`ultimo_folio\` = 0;

-- 2.5 Catálogos UI (Universidades, Centros de Trabajo, Especialidades): Asegurar que todos estén activos
UPDATE \`catalogos_ui\` SET \`activo\` = 1;

-- 2.6 Perfiles Médicos: Eliminar cuentas demo post-3pm y resetear contadores de médicos legítimos
DELETE FROM \`perfiles_medicos\` WHERE \`user_id\` >= ${CUTOFF_USER_ID};
UPDATE \`perfiles_medicos\` SET \`total_ordenes\` = 0, \`estado_id\` = 1;

-- 2.7 Empleados y Cuentas de Personal: Eliminar cuentas demo post-3pm y activar legítimas
DELETE FROM \`empleados\` WHERE \`user_id\` >= ${CUTOFF_USER_ID};
UPDATE \`empleados\` SET \`activo\` = 1 WHERE \`user_id\` < ${CUTOFF_USER_ID};

-- 2.8 RBAC: Eliminar asignaciones de permisos de cuentas demo
DELETE FROM \`rbac_permisos_usuarios\` WHERE \`user_id\` >= ${CUTOFF_USER_ID};

-- 2.9 Delight-Auth: Purgar sesiones, throttling, confirmaciones y tokens huérfanos
TRUNCATE TABLE \`users_throttling\`;
TRUNCATE TABLE \`users_resets\`;
TRUNCATE TABLE \`users_confirmations\`;
TRUNCATE TABLE \`users_remembered\`;
TRUNCATE TABLE \`jwt_jti_registry\`;

SET @t_2fa = (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'users_2fa');
SET @s_2fa = IF(@t_2fa > 0, 'DELETE FROM users_2fa WHERE user_id >= ${CUTOFF_USER_ID}', 'DO 0');
PREPARE st_2fa FROM @s_2fa; EXECUTE st_2fa; DEALLOCATE PREPARE st_2fa;

-- 2.10 Delight-Auth Users: Eliminar usuarios demo post-3pm y activar cuentas legítimas
DELETE FROM \`users\` WHERE \`id\` >= ${CUTOFF_USER_ID};
UPDATE \`users\` SET \`status\` = 0 WHERE \`id\` < ${CUTOFF_USER_ID};

-- 2.11 Logs Operativos, Auditoría de Sesión y Websocket
TRUNCATE TABLE \`sys_logs\`;
TRUNCATE TABLE \`fallback_log\`;
TRUNCATE TABLE \`ws_conexiones_log\`;
TRUNCATE TABLE \`ws_rechazos_log\`;
TRUNCATE TABLE \`users_audit_log\`;

SET FOREIGN_KEY_CHECKS = 1;
SQL_CLEANUP
echo "✓ Base de datos saneada con éxito."

# ── 3. ARCHIVOS FÍSICOS, LOGS Y COMPILACIÓN DE CATÁLOGOS ──────────────────────
echo ""
echo "📁 Purgando archivos temporales y PDFs de prueba..."
if [ -d "/opt/laesh/uploads/pdfs" ]; then
    sudo find /opt/laesh/uploads/pdfs/ -type f \( -name "*.pdf" -o -name "*.tmp*" \) -delete 2>/dev/null || true
    echo "✓ /opt/laesh/uploads/pdfs/ limpio."
fi
if [ -f "/opt/laesh/logs/app.log" ]; then
    sudo truncate -s 0 /opt/laesh/logs/app.log && echo "✓ app.log truncado."
fi
if [ -f "/opt/laesh/logs/swoole.log" ]; then
    sudo truncate -s 0 /opt/laesh/logs/swoole.log && echo "✓ swoole.log truncado."
fi
if [ -f "/opt/laesh/logs/ws_audit.log" ]; then
    sudo truncate -s 0 /opt/laesh/logs/ws_audit.log && echo "✓ ws_audit.log truncado."
fi
if [ -d "/opt/laesh/cache" ]; then
    sudo rm -f /opt/laesh/cache/laesh_cache_*_JTI_*.php /opt/laesh/cache/*.tmp 2>/dev/null || true
    echo "✓ Caché de tokens y temporales purgado."
fi

echo ""
echo "🔄 Recompilando catálogos y configuraciones de frontend..."
if php8.3 -r 'require "/opt/laesh/www/laesh-swbldi/commons/autoload.php"; Common\CatalogBuilder::build(); Common\ConfigBuilder::build();' 2>/dev/null; then
    sudo chown www-data:www-data /opt/laesh/assets/laesh-web-assets-uipv1a/js/catalog-compiled.js /opt/laesh/assets/laesh-web-assets-uipv1a/js/catalog-data.js /opt/laesh/assets/laesh-web-assets-uipv1a/js/config-compiled.js 2>/dev/null || true
    sudo chmod 0664 /opt/laesh/assets/laesh-web-assets-uipv1a/js/catalog-compiled.js /opt/laesh/assets/laesh-web-assets-uipv1a/js/catalog-data.js /opt/laesh/assets/laesh-web-assets-uipv1a/js/config-compiled.js 2>/dev/null || true
    echo "✓ catalog-compiled.js y config-compiled.js recompilados con permisos www-data."
else
    echo "ℹ️  Compilación de catálogos omitida (entorno sin webapp local)."
fi

# ── 4. VERIFICACIÓN POST-LIMPIEZA ─────────────────────────────────────────────
echo ""
echo "=========================================================="
echo "📊 VERIFICACIÓN POST-LIMPIEZA UAT"
echo "=========================================================="
SQL -e "
SELECT 'ordenes (debe ser 0)' entidad, COUNT(*) total FROM ordenes
UNION ALL SELECT 'pacientes (debe ser 0)', COUNT(*) FROM pacientes
UNION ALL SELECT 'resultados_pdf (debe ser 0)', COUNT(*) FROM resultados_pdf
UNION ALL SELECT 'historial_estados_orden (debe ser 0)', COUNT(*) FROM historial_estados_orden
UNION ALL SELECT 'notificaciones (debe ser 0)', COUNT(*) FROM notificaciones
UNION ALL SELECT 'perfiles_medicos (debe ser 4)', COUNT(*) FROM perfiles_medicos
UNION ALL SELECT 'empleados (debe ser 7: 2 Admins, 1 Recepción, 4 Médicos)', COUNT(*) FROM empleados
UNION ALL SELECT 'users (debe ser 7 cuentas legítimas)', COUNT(*) FROM users
UNION ALL SELECT 'catalogos_ui (debe ser 53 activos)', COUNT(*) FROM catalogos_ui
UNION ALL SELECT 'sys_logs (debe ser 0)', COUNT(*) FROM sys_logs
UNION ALL SELECT 'users_audit_log (debe ser 0)', COUNT(*) FROM users_audit_log
UNION ALL SELECT 'fallback_log (debe ser 0)', COUNT(*) FROM fallback_log
UNION ALL SELECT 'users_throttling (debe ser 0)', COUNT(*) FROM users_throttling;

SELECT e.user_id, u.username, u.email, e.rol, e.activo, u.status 
FROM empleados e 
JOIN users u ON u.id = e.user_id
ORDER BY e.rol, e.user_id;

SELECT pm.user_id, pm.nombre_completo, pm.cedula_profesional, pm.total_ordenes, pm.estado_id
FROM perfiles_medicos pm
ORDER BY pm.user_id;

SELECT tipo_documento, ultimo_folio FROM folios_control WHERE tipo_documento='orden_laboratorio';
"

echo "Archivos PDF residuales en disco: $(sudo find /opt/laesh/uploads/pdfs/ -type f 2>/dev/null | wc -l)"
echo "=========================================================="
echo "✨ Ambiente UAT 100% limpio y listo para inicio de pruebas."
echo "   Respaldo disponible en: $BK"
