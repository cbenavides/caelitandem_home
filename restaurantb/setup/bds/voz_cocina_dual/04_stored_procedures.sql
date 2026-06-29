USE `vcd01`;

DELIMITER //

DROP PROCEDURE IF EXISTS RegistrarComanda //
CREATE PROCEDURE RegistrarComanda(
    IN p_mesa_id INT UNSIGNED,
    IN p_mesero_id INT UNSIGNED,
    IN p_texto_transcrito TEXT,
    IN p_json_productos JSON
)
BEGIN
    DECLARE v_comanda_id BIGINT UNSIGNED;
    DECLARE v_total DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_producto_id INT UNSIGNED;
    DECLARE v_cantidad INT UNSIGNED;
    DECLARE v_precio DECIMAL(10,2);
    DECLARE i INT DEFAULT 0;
    DECLARE n INT;

    START TRANSACTION;

    INSERT INTO comandas (mesa_id, mesero_id, texto_transcrito, total, hora_captura)
    VALUES (p_mesa_id, p_mesero_id, p_texto_transcrito, 0.00, NOW());
    
    SET v_comanda_id = LAST_INSERT_ID();
    SET n = JSON_LENGTH(p_json_productos);

    WHILE i < n DO
        SET v_producto_id = JSON_UNQUOTE(JSON_EXTRACT(p_json_productos, CONCAT('$[',i,'].producto_id')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_json_productos, CONCAT('$[',i,'].cantidad')));
        
        SELECT precio INTO v_precio FROM productos WHERE id = v_producto_id AND disponible = 1;
        
        IF v_precio IS NOT NULL THEN
            INSERT INTO detalle_comandas (comanda_id, producto_id, cantidad, precio_unitario, subtotal)
            VALUES (v_comanda_id, v_producto_id, v_cantidad, v_precio, v_precio * v_cantidad);
            
            SET v_total = v_total + (v_precio * v_cantidad);
        END IF;
        
        SET i = i + 1;
    END WHILE;

    UPDATE comandas SET total = v_total WHERE id = v_comanda_id;

    COMMIT;

    SELECT v_comanda_id AS comanda_id, v_total AS total, 'success' AS estado;
END //

DROP PROCEDURE IF EXISTS CobrarMesa //
CREATE PROCEDURE CobrarMesa(
    IN p_mesa_id INT UNSIGNED,
    IN p_cajero_id INT UNSIGNED
)
BEGIN
    DECLARE v_total_general DECIMAL(10,2);
    DECLARE v_num_comandas INT;

    START TRANSACTION;

    SELECT SUM(total), COUNT(id) INTO v_total_general, v_num_comandas
    FROM comandas
    WHERE mesa_id = p_mesa_id AND estado IN ('pendiente', 'en_preparacion', 'listo', 'entregado');

    IF v_num_comandas > 0 THEN
        INSERT INTO tickets (comanda_id, total_pagado, cobrado_por_user_id)
        SELECT id, total, p_cajero_id
        FROM comandas
        WHERE mesa_id = p_mesa_id AND estado IN ('pendiente', 'en_preparacion', 'listo', 'entregado');
        
        UPDATE comandas SET estado = 'cobrado' 
        WHERE mesa_id = p_mesa_id AND estado IN ('pendiente', 'en_preparacion', 'listo', 'entregado');
        
        COMMIT;
        SELECT v_total_general AS total, v_num_comandas AS num_comandas, 'success' AS estado;
    ELSE
        ROLLBACK;
        SELECT 0.00 AS total, 0 AS num_comandas, 'error_no_comandas' AS estado;
    END IF;
END //

DROP PROCEDURE IF EXISTS GenerarCorteZ //
CREATE PROCEDURE GenerarCorteZ(
    IN p_cajero_id INT UNSIGNED,
    IN p_efectivo_declarado DECIMAL(10,2)
)
BEGIN
    DECLARE v_corte_id BIGINT UNSIGNED;
    DECLARE v_total_calculado DECIMAL(10,2);
    DECLARE v_fondo_caja DECIMAL(10,2);

    START TRANSACTION;

    SELECT id, fondo_caja INTO v_corte_id, v_fondo_caja
    FROM cortes_caja
    WHERE cajero_id = p_cajero_id AND estado = 'abierto'
    LIMIT 1;

    IF v_corte_id IS NOT NULL THEN
        SELECT COALESCE(SUM(total_pagado), 0.00) INTO v_total_calculado
        FROM tickets
        WHERE cobrado_por_user_id = p_cajero_id AND corte_id IS NULL;

        UPDATE tickets SET corte_id = v_corte_id
        WHERE cobrado_por_user_id = p_cajero_id AND corte_id IS NULL;

        UPDATE cortes_caja 
        SET total_efectivo_declarado = p_efectivo_declarado,
            total_calculado = v_total_calculado + v_fondo_caja,
            fecha_cierre = NOW(),
            estado = 'cerrado'
        WHERE id = v_corte_id;

        COMMIT;
        SELECT v_corte_id AS corte_id, (v_total_calculado + v_fondo_caja) AS calculado, 'success' AS estado;
    ELSE
        ROLLBACK;
        SELECT 0 AS corte_id, 0.00 AS calculado, 'error_no_abierto' AS estado;
    END IF;
END //

DELIMITER ;
