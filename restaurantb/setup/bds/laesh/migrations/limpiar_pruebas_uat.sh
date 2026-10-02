#!/usr/bin/env bash
set -e

echo "=========================================================="
echo "🧹 [LAESH] Iniciando Limpieza Integral para Pruebas UAT"
echo "=========================================================="

# 1. EJECUCIÓN SQL EN MARIADB (TRANSACCIONES, CATÁLOGOS Y LOGS)
sudo mariadb --defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf laesh_db <<'SQL_CLEANUP'
SET FOREIGN_KEY_CHECKS = 0;

-- 1.1 Truncar tablas del ciclo de solicitudes / órdenes (resetea AUTO_INCREMENT a 1)
TRUNCATE TABLE `historial_estados_orden`;
TRUNCATE TABLE `resultados_pdf`;
TRUNCATE TABLE `ordenes`;
TRUNCATE TABLE `pacientes`;

-- 1.2 Compatibilidad retroactiva: truncar detalle_ordenes SOLO si aún existe
SET @tabla_detalle = (
    SELECT COUNT(*) FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = 'detalle_ordenes'
);
SET @sql_detalle = IF(@tabla_detalle > 0, 'TRUNCATE TABLE detalle_ordenes', 'DO 0');
PREPARE stmt_det FROM @sql_detalle;
EXECUTE stmt_det;
DEALLOCATE PREPARE stmt_det;

-- 1.3 Limpiar notificaciones del ciclo de órdenes y reiniciar contador
DELETE FROM `notificaciones`
WHERE `tipo` IN ('nueva_orden', 'orden_actualizada', 'resultados_listos')
   OR `folio_referencia` IS NOT NULL;
ALTER TABLE `notificaciones` AUTO_INCREMENT = 1;

-- 1.4 Sincronizar contadores de actividad médica (evita KPIs fantasma en Recepción)
UPDATE `perfiles_medicos` SET `total_ordenes` = 0;

-- 1.5 Reiniciar folio correlativo atómico a 0 (la próxima orden será folio 1)
INSERT INTO `folios_control` (`tipo_documento`, `ultimo_folio`)
VALUES ('orden_laboratorio', 0)
ON DUPLICATE KEY UPDATE `ultimo_folio` = 0;

-- 1.6 Purgar trazas de pruebas previas en logs operativos y fallbacks SQL
DELETE FROM `sys_logs`
WHERE `message` LIKE '%Solicitud%'
   OR `message` LIKE '%orden%'
   OR `message` LIKE '%Orden%'
   OR `message` LIKE '%PDF%'
   OR `url` LIKE '%/orden%';
ALTER TABLE `sys_logs` AUTO_INCREMENT = 1;

TRUNCATE TABLE `fallback_log`;

-- 1.7 Limpiar candados y rate-limiting de Delight-Auth (previene bloqueos en UAT)
TRUNCATE TABLE `users_throttling`;

SET FOREIGN_KEY_CHECKS = 1;
SQL_CLEANUP

echo "✓ Base de datos saneada y reseteada exitosamente."

# 2. LIMPIEZA DE ARCHIVOS FÍSICOS (PDFs Y CACHÉ RESIDUAL)
echo "📁 Purgando archivos PDF de resultados de prueba anteriores..."
if [ -d "/opt/laesh/uploads/pdfs" ]; then
    # Elimina únicamente los PDFs de resultados y temporales, respetando .gitkeep
    sudo find /opt/laesh/uploads/pdfs/ -type f -name "resultado_ord_*.pdf" -delete 2>/dev/null || true
    sudo find /opt/laesh/uploads/pdfs/ -type f -name "*.tmp*" -delete 2>/dev/null || true
    echo "✓ Directorio /opt/laesh/uploads/pdfs/ limpio."
fi

# 3. PURGA DEL LOG FÍSICO APP.LOG (Opcional pero recomendado para UAT)
if [ -f "/opt/laesh/logs/app.log" ]; then
    sudo truncate -s 0 /opt/laesh/logs/app.log
    echo "✓ Archivo /opt/laesh/logs/app.log truncado a 0 bytes."
fi

# 4. LIMPIEZA DE CACHÉ DE SESIONES JWT RESIDUALES
if [ -d "/opt/laesh/cache" ]; then
    sudo rm -f /opt/laesh/cache/laesh_cache_*_JTI_*.php 2>/dev/null || true
    echo "✓ Caché OPcache L2 de tokens JTI purgado."
fi

echo ""
echo "=========================================================="
echo "📊 VERIFICACIÓN DE ESTADO POST-LIMPIEZA (DEBE DAR 0)"
echo "=========================================================="

sudo mariadb --defaults-extra-file=/opt/laesh/configs/.mariadb-root.cnf laesh_db -e "
SELECT 'ordenes' AS entidad, COUNT(*) AS total FROM ordenes
UNION ALL SELECT 'pacientes', COUNT(*) FROM pacientes
UNION ALL SELECT 'resultados_pdf', COUNT(*) FROM resultados_pdf
UNION ALL SELECT 'historial_estados_orden', COUNT(*) FROM historial_estados_orden
UNION ALL SELECT 'notificaciones (ordenes)', COUNT(*) FROM notificaciones WHERE tipo != 'catalogo_actualizado'
UNION ALL SELECT 'perfiles_medicos (total_ordenes activos)', COALESCE(SUM(total_ordenes), 0) FROM perfiles_medicos
UNION ALL SELECT 'sys_logs (trazas ordenes)', COUNT(*) FROM sys_logs WHERE message LIKE '%Solicitud%' OR message LIKE '%orden%'
UNION ALL SELECT 'fallback_log (errores)', COUNT(*) FROM fallback_log
UNION ALL SELECT 'users_throttling (bloqueos)', COUNT(*) FROM users_throttling;

SELECT tipo_documento, ultimo_folio, actualizado_en
FROM folios_control
WHERE tipo_documento = 'orden_laboratorio';
"

echo "Archivos PDF residuales en disco: $(sudo find /opt/laesh/uploads/pdfs/ -type f -name 'resultado_ord_*.pdf' 2>/dev/null | wc -l)"
echo "=========================================================="
echo "✨ Sistema 100% listo para pruebas UAT limpias."

