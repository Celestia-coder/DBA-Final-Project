-- =====================================================================
-- Brewlevard - 04_procedures.sql   (Member 4)
-- Run AFTER 01_schema.sql, 02_data.sql, 03_views.sql.
-- Run in MySQL Workbench as a whole script (it sets its own DELIMITER).
--
--   sp_stock_in  : new batch + STOCK_IN transaction + item quantity (+)
--   sp_stock_out : FEFO deduction across batches, one STOCK_OUT row per
--                  batch affected, NULL expiration last, expired batches
--                  skipped for reason USED, rejects if stock is short.
--   Both reject DISCONTINUED (and unknown) items.
--   Each procedure is ONE transaction: any error rolls everything back.
-- =====================================================================

USE brewlevard;

DROP PROCEDURE IF EXISTS sp_stock_in;
DROP PROCEDURE IF EXISTS sp_stock_out;

DELIMITER //

-- ---------------------------------------------------------------------
-- sp_stock_in(item, quantity, expiration date or NULL, reason, remarks)
--   reason: 'PURCHASE' or 'CORRECTION'
--   date_received is today (CURDATE()).
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_stock_in(
    IN p_item_id         INT UNSIGNED,
    IN p_quantity        DECIMAL(10,3),
    IN p_expiration_date DATE,
    IN p_reason          VARCHAR(20),
    IN p_remarks         VARCHAR(255)
)
BEGIN
    DECLARE v_status   VARCHAR(20) DEFAULT NULL;
    DECLARE v_batch_id INT UNSIGNED;

    -- Any error (including our own SIGNALs): undo everything, re-raise.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Input checks
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_stock_in: quantity must be greater than 0.';
    END IF;

    IF p_reason IS NULL OR p_reason NOT IN ('PURCHASE', 'CORRECTION') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_stock_in: reason must be PURCHASE or CORRECTION.';
    END IF;

    IF p_expiration_date IS NOT NULL AND p_expiration_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_stock_in: expiration date is already in the past.';
    END IF;

    START TRANSACTION;

    -- Lock the item row so concurrent calls cannot interleave.
    SELECT status INTO v_status
    FROM inventory_item
    WHERE item_id = p_item_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_stock_in: item does not exist.';
    END IF;

    IF v_status = 'DISCONTINUED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_stock_in: item is DISCONTINUED; stock cannot be added.';
    END IF;

    -- 1) new batch
    INSERT INTO stock_batch
        (item_id, quantity_received, quantity_remaining, date_received, expiration_date)
    VALUES
        (p_item_id, p_quantity, p_quantity, CURDATE(), p_expiration_date);

    SET v_batch_id = LAST_INSERT_ID();

    -- 2) movement history
    INSERT INTO stock_transaction
        (item_id, batch_id, transaction_type, quantity, reason, remarks)
    VALUES
        (p_item_id, v_batch_id, 'STOCK_IN', p_quantity, p_reason, p_remarks);

    -- 3) item total
    UPDATE inventory_item
    SET quantity = quantity + p_quantity
    WHERE item_id = p_item_id;

    COMMIT;

    SELECT v_batch_id AS batch_id,
           p_item_id  AS item_id,
           p_quantity AS quantity_added,
           (SELECT quantity FROM inventory_item WHERE item_id = p_item_id) AS new_item_quantity;
END //


-- ---------------------------------------------------------------------
-- sp_stock_out(item, quantity, reason, remarks)
--   reason: 'USED', 'DAMAGED', 'EXPIRED' or 'CORRECTION'
--   FEFO: earliest expiration first; batches with no expiration last.
--   USED never takes from batches whose expiration_date is before today.
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_stock_out(
    IN p_item_id  INT UNSIGNED,
    IN p_quantity DECIMAL(10,3),
    IN p_reason   VARCHAR(20),
    IN p_remarks  VARCHAR(255)
)
BEGIN
    DECLARE v_status    VARCHAR(20)  DEFAULT NULL;
    DECLARE v_available DECIMAL(10,3) DEFAULT 0;
    DECLARE v_needed    DECIMAL(10,3);
    DECLARE v_take      DECIMAL(10,3);
    DECLARE v_batch_id  INT UNSIGNED;
    DECLARE v_batch_rem DECIMAL(10,3);
    DECLARE v_first_txn INT UNSIGNED DEFAULT NULL;
    DECLARE v_done      TINYINT DEFAULT 0;

    -- FEFO cursor. ORDER BY (expiration_date IS NULL) puts NULLs last.
    DECLARE cur_batches CURSOR FOR
        SELECT batch_id, quantity_remaining
        FROM stock_batch
        WHERE item_id = p_item_id
          AND quantity_remaining > 0
          AND (p_reason <> 'USED'
               OR expiration_date IS NULL
               OR expiration_date >= CURDATE())
        ORDER BY (expiration_date IS NULL), expiration_date, date_received, batch_id
        FOR UPDATE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Input checks
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_stock_out: quantity must be greater than 0.';
    END IF;

    IF p_reason IS NULL OR p_reason NOT IN ('USED', 'DAMAGED', 'EXPIRED', 'CORRECTION') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_stock_out: reason must be USED, DAMAGED, EXPIRED or CORRECTION.';
    END IF;

    START TRANSACTION;

    SELECT status INTO v_status
    FROM inventory_item
    WHERE item_id = p_item_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_stock_out: item does not exist.';
    END IF;

    IF v_status = 'DISCONTINUED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_stock_out: item is DISCONTINUED; stock cannot be deducted.';
    END IF;

    -- Is there enough in the batches this reason is allowed to use?
    SELECT COALESCE(SUM(quantity_remaining), 0) INTO v_available
    FROM stock_batch
    WHERE item_id = p_item_id
      AND quantity_remaining > 0
      AND (p_reason <> 'USED'
           OR expiration_date IS NULL
           OR expiration_date >= CURDATE())
    FOR UPDATE;

    IF v_available < p_quantity THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_stock_out: insufficient stock (expired batches are not usable for USED).';
    END IF;

    -- FEFO loop: one STOCK_OUT row per batch touched.
    SET v_needed = p_quantity;
    OPEN cur_batches;

    fefo_loop: LOOP
        FETCH cur_batches INTO v_batch_id, v_batch_rem;
        IF v_done = 1 THEN
            LEAVE fefo_loop;
        END IF;

        SET v_take = LEAST(v_batch_rem, v_needed);

        UPDATE stock_batch
        SET quantity_remaining = quantity_remaining - v_take
        WHERE batch_id = v_batch_id;

        INSERT INTO stock_transaction
            (item_id, batch_id, transaction_type, quantity, reason, remarks)
        VALUES
            (p_item_id, v_batch_id, 'STOCK_OUT', v_take, p_reason, p_remarks);

        IF v_first_txn IS NULL THEN
            SET v_first_txn = LAST_INSERT_ID();
        END IF;

        SET v_needed = v_needed - v_take;
        IF v_needed <= 0 THEN
            LEAVE fefo_loop;
        END IF;
    END LOOP fefo_loop;

    CLOSE cur_batches;

    UPDATE inventory_item
    SET quantity = quantity - p_quantity
    WHERE item_id = p_item_id;

    COMMIT;

    -- Show what this call did (one row per batch affected).
    SELECT t.transaction_id, t.batch_id, b.expiration_date,
           t.quantity AS deducted, t.reason
    FROM stock_transaction t
    JOIN stock_batch b ON b.batch_id = t.batch_id
    WHERE t.item_id = p_item_id
      AND t.transaction_id >= v_first_txn
      AND t.transaction_type = 'STOCK_OUT'
    ORDER BY t.transaction_id;
END //

DELIMITER ;
