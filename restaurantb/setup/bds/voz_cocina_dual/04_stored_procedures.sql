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

DROP PROCEDURE IF EXISTS CerrarCuentaMesa //
CREATE PROCEDURE CerrarCuentaMesa(
    IN p_mesa_id INT UNSIGNED,
    IN p_mesero_id INT UNSIGNED
)
BEGIN
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_num_productos INT;
    DECLARE v_ticket_id BIGINT UNSIGNED;

    START TRANSACTION;

    SELECT COALESCE(SUM(subtotal), 0), COUNT(*) INTO v_total, v_num_productos
    FROM detalle_comandas dc
    JOIN comandas c ON c.id = dc.comanda_id
    WHERE c.mesa_id = p_mesa_id AND dc.estado = 'activo' AND c.estado IN ('pendiente', 'en_preparacion', 'listo', 'entregado');

    IF v_num_productos > 0 THEN
        INSERT INTO tickets (mesa_id, mesero_id, total, num_productos)
        VALUES (p_mesa_id, p_mesero_id, v_total, v_num_productos);
        
        SET v_ticket_id = LAST_INSERT_ID();
        
        UPDATE comandas SET estado = 'cobrado' 
        WHERE mesa_id = p_mesa_id AND estado IN ('pendiente', 'en_preparacion', 'listo', 'entregado');
        
        COMMIT;
        SELECT v_ticket_id AS ticket_id, v_total AS total, v_num_productos AS num_productos, 'success' AS estado;
    ELSE
        ROLLBACK;
        SELECT 0 AS ticket_id, 0.00 AS total, 0 AS num_productos, 'error_no_comandas' AS estado;
    END IF;
END //

DELIMITER ;
