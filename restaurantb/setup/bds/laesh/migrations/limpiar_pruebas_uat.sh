#!/usr/bin/env bash
# ==============================================================================
# LAESH — limpiar_pruebas_uat.sh   (uso MANUAL en KVM2, base laesh_db)
#
# Deja los portales de Bloc Digital sin datos operativos de pruebas:
#   Solicitudes (Hoy/Anteriores), indicadores, pacientes, notificaciones,
#   PDFs de resultados, folios, contadores de médicos, sesiones y logs.
# Personal de Recepción, Médicos y Administradores: se ELIMINAN todas las
#   cuentas operativas de prueba para que los portales queden completamente
#   limpios y no aparezcan listados en el portal de Recepción.
#   Únicamente permanece activo el Admin Jacob (ADMIN_ID, por defecto 9531747410).
#
# NO TOCA: catálogo de estudios y promociones (cat_*, rel_*, catalogo_promociones),
#          CMS (web_contenidos), configuraciones del sistema, permisos base.
# PURGA: catalogos_ui queda en 0 registros para alta manual previa en UAT (Universidades, Centros de Trabajo y Especialidades).
#
# Uso:
#   bash limpiar_pruebas_uat.sh            # pide confirmación escrita
#   bash limpiar_pruebas_uat.sh --yes      # sin confirmación
#   ADMIN_ID=9531747410 bash limpiar_pruebas_uat.sh
# Requiere sudo. Hace backup (backup_db.sh, el mismo del cron) ANTES de borrar
# y se aborta si el backup falla.
# ==============================================================================
set -euo pipefail

DB="laesh_db"
MCNF="/opt/laesh/configs/.mariadb-root.cnf"
BACKUP_SCRIPT="/opt/laesh/scripts/backup_db.sh"
ADMIN_ID="${ADMIN_ID:-9531747410}"   # username/email/id del único admin que queda activo
ASSUME_YES=false
[[ "${1:-}" == "--yes" ]] && ASSUME_YES=true

SQL() { sudo mariadb --defaults-extra-file="$MCNF" "$DB" "$@"; }

echo "=========================================================="
echo "🧹 [LAESH] Limpieza Integral para Pruebas UAT  (BD: $DB)"
echo "=========================================================="

# ── 0. Resolver el Admin que se conserva (debe ser EXACTAMENTE 1) ─────────────
ADMIN_SQL=$(printf '%s' "$ADMIN_ID" | sed "s/'/''/g")
KEEP_UID=$(SQL -N -B -e "
  SELECT u.id FROM users u
  WHERE (u.username = '$ADMIN_SQL' OR u.email = '$ADMIN_SQL' OR u.id = '$ADMIN_SQL'
         OR u.email LIKE '$ADMIN_SQL@%')
    AND EXISTS (SELECT 1 FROM empleados e WHERE e.user_id = u.id AND e.rol = 'ADMIN');")
if [ "$(printf '%s\n' "$KEEP_UID" | grep -c .)" -ne 1 ]; then
    echo "❌ No se encontró exactamente 1 usuario ADMIN para '$ADMIN_ID' (hallados: '${KEEP_UID//$'\n'/,}')."
    echo "   Nada fue modificado. Revisa con:  SELECT id,username,email FROM users;"
    exit 1
fi
echo "✓ Admin que permanecerá activo → users.id=$KEEP_UID ($ADMIN_ID)"

echo ""
echo "Antes de limpiar:"
SQL -e "
SELECT 'ordenes' entidad, COUNT(*) total FROM ordenes
UNION ALL SELECT 'pacientes', COUNT(*) FROM pacientes
UNION ALL SELECT 'perfiles_medicos', COUNT(*) FROM perfiles_medicos
UNION ALL SELECT 'empleados (todos los roles)', COUNT(*) FROM empleados
UNION ALL SELECT 'users (cuentas totales)', COUNT(*) FROM users
UNION ALL SELECT 'catalogos_ui', COUNT(*) FROM catalogos_ui
UNION ALL SELECT 'notificaciones', COUNT(*) FROM notificaciones;"

if ! $ASSUME_YES; then
    read -r -p "⚠️  Se borrarán datos operativos y cuentas de prueba. Escribe LIMPIAR para continuar: " CONF
    [ "$CONF" = "LIMPIAR" ] || { echo "Cancelado. Nada modificado."; exit 1; }
fi

# ── 1. BACKUP PREVIO (mismo script del cron laesh-backup) ─────────────────────
echo "💾 Respaldo previo con $BACKUP_SCRIPT ..."
sudo bash "$BACKUP_SCRIPT"
BK=$(sudo ls -1t /opt/laesh/backups/db/laesh_db_2*.sql.gz 2>/dev/null | head -1)
[ -n "$BK" ] || { echo "❌ No se localizó el backup; abortando sin tocar la BD."; exit 1; }
echo "✓ Backup: $BK ($(sudo du -h "$BK" | cut -f1))"
echo "  Restauración: gunzip -c $BK | sudo mariadb --defaults-extra-file=$MCNF $DB"

# ── 2. SQL: datos operativos, sesiones, logs, médicos, personal y catálogos ────
SQL <<SQL_CLEANUP
SET FOREIGN_KEY_CHECKS = 0;

-- 2.1 Ciclo de solicitudes y pacientes (resetea AUTO_INCREMENT a 1)
TRUNCATE TABLE \`historial_estados_orden\`;
TRUNCATE TABLE \`resultados_pdf\`;
TRUNCATE TABLE \`ordenes\`;
TRUNCATE TABLE \`pacientes\`;

-- 2.2 Compatibilidad retroactiva: detalle_ordenes solo si existe
SET @t = (SELECT COUNT(*) FROM information_schema.tables
          WHERE table_schema = DATABASE() AND table_name = 'detalle_ordenes');
SET @s = IF(@t > 0, 'TRUNCATE TABLE detalle_ordenes', 'DO 0');
PREPARE st FROM @s; EXECUTE st; DEALLOCATE PREPARE st;

-- 2.3 Notificaciones (purga total para inicio limpio de pruebas)
TRUNCATE TABLE \`notificaciones\`;

-- 2.4 Cuentas y perfiles de médicos: purga total para que no aparezcan en recepción
TRUNCATE TABLE \`perfiles_medicos\`;

-- 2.5 Folio correlativo (la próxima solicitud será folio 1)
INSERT INTO \`folios_control\` (\`tipo_documento\`, \`ultimo_folio\`)
VALUES ('orden_laboratorio', 0)
ON DUPLICATE KEY UPDATE \`ultimo_folio\` = 0;

-- 2.6 Catálogos UI (universidades y lugares de trabajo): purga total para alta manual previa en UAT
TRUNCATE TABLE \`catalogos_ui\`;

-- 2.7 Logs operativos, auditoría y de tiempo real (trazas E2E)
TRUNCATE TABLE \`sys_logs\`;
TRUNCATE TABLE \`fallback_log\`;
TRUNCATE TABLE \`ws_conexiones_log\`;
TRUNCATE TABLE \`ws_rechazos_log\`;
TRUNCATE TABLE \`users_audit_log\`;

-- 2.8 Candados Delight-Auth, tokens de recuperación y confirmaciones
TRUNCATE TABLE \`users_throttling\`;
TRUNCATE TABLE \`users_resets\`;
TRUNCATE TABLE \`users_confirmations\`;

-- 2.9 Personal y Cuentas: eliminar todos excepto el Admin conservado
DELETE FROM \`empleados\` WHERE \`user_id\` <> ${KEEP_UID};
UPDATE \`empleados\` SET \`activo\` = 1 WHERE \`user_id\` = ${KEEP_UID};

-- 2.10 Delight-Auth y RBAC: eliminar sesiones, tokens y permisos de los eliminados
DELETE FROM \`users_remembered\` WHERE \`user\` <> ${KEEP_UID};
DELETE FROM \`jwt_jti_registry\` WHERE \`user_id\` <> ${KEEP_UID};
DELETE FROM \`rbac_permisos_usuarios\` WHERE \`user_id\` <> ${KEEP_UID};

SET @t2fa = (SELECT COUNT(*) FROM information_schema.tables
             WHERE table_schema = DATABASE() AND table_name = 'users_2fa');
SET @s2fa = IF(@t2fa > 0, 'DELETE FROM users_2fa WHERE user_id <> ${KEEP_UID}', 'DO 0');
PREPARE st2fa FROM @s2fa; EXECUTE st2fa; DEALLOCATE PREPARE st2fa;

-- 2.11 Eliminar cuentas de usuarios en Delight-Auth (excepto Admin conservado)
DELETE FROM \`users\` WHERE \`id\` <> ${KEEP_UID};
UPDATE \`users\` SET \`status\` = 0 WHERE \`id\` = ${KEEP_UID};

SET FOREIGN_KEY_CHECKS = 1;
SQL_CLEANUP
echo "✓ Base de datos saneada."

# ── 3. Archivos físicos ───────────────────────────────────────────────────────
echo "📁 Purgando PDFs de resultados y temporales de prueba..."
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
    echo "✓ Caché de tokens JTI purgado."
fi

# ── 4. Verificación ───────────────────────────────────────────────────────────
echo ""
echo "=========================================================="
echo "📊 VERIFICACIÓN POST-LIMPIEZA (todo debe dar 0, salvo lo indicado)"
echo "=========================================================="
SQL -e "
SELECT 'ordenes' entidad, COUNT(*) total FROM ordenes
UNION ALL SELECT 'pacientes', COUNT(*) FROM pacientes
UNION ALL SELECT 'resultados_pdf', COUNT(*) FROM resultados_pdf
UNION ALL SELECT 'historial_estados_orden', COUNT(*) FROM historial_estados_orden
UNION ALL SELECT 'notificaciones (total)', COUNT(*) FROM notificaciones
UNION ALL SELECT 'perfiles_medicos (debe ser 0)', COUNT(*) FROM perfiles_medicos
UNION ALL SELECT 'empleados (debe ser 1: Admin Jacob)', COUNT(*) FROM empleados
UNION ALL SELECT 'users (debe ser 1: Admin Jacob)', COUNT(*) FROM users
UNION ALL SELECT 'catalogos_ui (debe ser 0: purga total)', COUNT(*) FROM catalogos_ui
UNION ALL SELECT 'sys_logs', COUNT(*) FROM sys_logs
UNION ALL SELECT 'users_audit_log', COUNT(*) FROM users_audit_log
UNION ALL SELECT 'fallback_log', COUNT(*) FROM fallback_log
UNION ALL SELECT 'users_throttling', COUNT(*) FROM users_throttling;

SELECT e.user_id, u.username, u.email, e.rol, e.activo, u.status 
FROM empleados e 
JOIN users u ON u.id = e.user_id;

SELECT tipo_documento, ultimo_folio FROM folios_control WHERE tipo_documento='orden_laboratorio';"
echo "PDFs residuales en disco: $(sudo find /opt/laesh/uploads/pdfs/ -type f 2>/dev/null | wc -l)"
echo "=========================================================="
echo "✨ Listo para el ciclo UAT. Backup previo: $BK"
