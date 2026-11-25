-- =====================================================================
-- Brewlevard - 05_demo_script.sql   (Member 4)  -- presentation order
-- Prereq: 01_schema, 02_data, 03_views, 04_procedures already run.
-- Run ONE STEP AT A TIME (highlight + Ctrl+Enter). Steps 7-8 are
-- supposed to FAIL - that is the demo.
-- The demo creates its own item ('Oat Milk (Demo)') so it never
-- disturbs the seed data. To repeat it, re-run 01-04 on a fresh database.
-- CHECK BEFORE PRESENTING: the view column names in steps 3, 5, 9 and
-- the seeded name 'Fresh Milk' match what Members 2 and 3 wrote.
-- =====================================================================
USE brewlevard;

-- 1. CREATE (new item): minimum stock 5 L, same category as the milk
INSERT INTO inventory_item (category_id, unit_id, item_name, description, minimum_stock_level)
VALUES ((SELECT category_id FROM (SELECT category_id FROM inventory_item
                                  WHERE item_name LIKE '%Milk%' LIMIT 1) c),
        (SELECT unit_id FROM unit WHERE abbreviation = 'L'),
        'Oat Milk (Demo)', 'Demo item for the presentation', 5);
SET @oat = LAST_INSERT_ID();

-- 2. STOCK IN: two deliveries with different expiry dates (batch A is earlier)
CALL sp_stock_in(@oat, 5,  DATE_ADD(CURDATE(), INTERVAL 3  DAY), 'PURCHASE', 'Delivery A - 5 L, expires in 3 days');
CALL sp_stock_in(@oat, 10, DATE_ADD(CURDATE(), INTERVAL 10 DAY), 'PURCHASE', 'Delivery B - 10 L, expires in 10 days');

-- 3. READ: item total (15) = sum of its batches (5 + 10)
SELECT * FROM v_current_stock WHERE item_name = 'Oat Milk (Demo)';
SELECT batch_id, quantity_received, quantity_remaining, expiration_date
FROM stock_batch WHERE item_id = @oat ORDER BY batch_id;

-- 4. STOCK OUT with FEFO: 7 L > batch A (5), so 5 from A, then 2 from B
CALL sp_stock_out(@oat, 7, 'USED', 'Morning rush');
SELECT batch_id, quantity_remaining FROM stock_batch WHERE item_id = @oat;   -- A = 0, B = 8

-- 5. MOVEMENT HISTORY: 2 STOCK_IN rows + 2 STOCK_OUT rows (one per batch)
SELECT * FROM v_stock_history WHERE item_name = 'Oat Milk (Demo)';

-- 6. UPDATE (quantity): correction is a stock-out with reason CORRECTION
CALL sp_stock_out(@oat, 1, 'CORRECTION', 'Miscounted by 1 L');               -- item total = 7

-- 7. REJECTED: more than we have (7 L left, asking for 100)
CALL sp_stock_out(@oat, 100, 'USED', 'Should fail');                          -- ERROR: insufficient stock

-- 8. DELETE (discontinue) then REJECTED: discontinued items cannot move
UPDATE inventory_item SET status = 'DISCONTINUED' WHERE item_id = @oat;
CALL sp_stock_in(@oat, 5, NULL, 'PURCHASE', 'Should fail');                   -- ERROR: DISCONTINUED
CALL sp_stock_out(@oat, 1, 'USED', 'Should fail');                            -- ERROR: DISCONTINUED
-- (history is kept)
SELECT COUNT(*) AS history_rows_kept FROM stock_transaction WHERE item_id = @oat;   -- 5

-- 9. SEEDED DEMO CASES: the prof's scenarios, one view each
SELECT * FROM v_cups_remaining;       -- "cups from X liters" (milk)
SELECT * FROM v_low_stock;            -- at/below minimum, incl. the item at zero
SELECT * FROM v_expiring_batches;     -- expiring within 7 days + already expired
SELECT * FROM v_restock_forecast;     -- what to reorder
SELECT * FROM v_dashboard;            -- one-screen summary

-- 10. EXPIRED BATCHES ARE SKIPPED FOR 'USED' (use the seeded milk with an expired batch)
SELECT batch_id, quantity_remaining, expiration_date FROM stock_batch
WHERE item_id = (SELECT item_id FROM inventory_item WHERE item_name = 'Fresh Milk') ORDER BY expiration_date;
-- CALL sp_stock_out((SELECT item_id FROM inventory_item WHERE item_name = 'Fresh Milk'), 1, 'USED', 'Live demo');
-- -> takes from the earliest NON-expired batch; use reason 'EXPIRED' to write off the expired one.

-- 11. INTEGRITY: item.quantity must equal its batch total (expect 0 rows)
SELECT i.item_id, i.item_name, i.quantity, COALESCE(SUM(b.quantity_remaining), 0) AS batch_total
FROM inventory_item i LEFT JOIN stock_batch b ON b.item_id = i.item_id
GROUP BY i.item_id, i.item_name, i.quantity
HAVING i.quantity <> COALESCE(SUM(b.quantity_remaining), 0);
