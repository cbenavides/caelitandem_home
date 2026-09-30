-- =============================================================================
-- m005 — Retirar la tabla `detalle_ordenes` (2026-09-30)
--
-- Motivo: tabla de solo escritura que nunca tuvo filas. Los estudios de cada
-- orden viven en `ordenes.estudios` (JSON de nombres); la app solo insertaba en
-- detalle_ordenes cuando llegaban IDs numéricos, cosa que el frontend nunca envía
-- (verificado en KVM2: 26 órdenes, 0 con IDs numéricos, 0 filas en la tabla).
-- Ningún SP, vista ni consulta la lee. El INSERT ya se retiró de
-- rc/negocio/Ordenes.php y md/negocio/Ordenes.php, y el DDL de 03_transactional_schema.sql.
--
-- Idempotente. Por seguridad NO borra si la tabla tuviera filas: en ese caso
-- falla con un error explícito y no toca nada.
-- =============================================================================

USE `laesh_db`;

DELIMITER //
DROP PROCEDURE IF EXISTS `m005_drop_detalle_ordenes` //
CREATE PROCEDURE `m005_drop_detalle_ordenes`()
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_filas  INT DEFAULT 0;

    SELECT COUNT(*) INTO v_existe
      FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'detalle_ordenes';

    IF v_existe = 1 THEN
        SELECT COUNT(*) INTO v_filas FROM `detalle_ordenes`;
        IF v_filas > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'm005: detalle_ordenes tiene filas — revisar antes de retirarla';
        END IF;
        DROP TABLE `detalle_ordenes`;
    END IF;
END //
DELIMITER ;

CALL `m005_drop_detalle_ordenes`();
DROP PROCEDURE IF EXISTS `m005_drop_detalle_ordenes`;
