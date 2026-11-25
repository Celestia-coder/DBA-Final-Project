-- =====================================================================
-- Brewlevard - 03_views.sql   (Member 3)
-- Run AFTER 01_schema.sql and 02_data.sql.
-- Run in MySQL Workbench as a whole script (or File > Open SQL Script).
--
-- This script creates the reporting and analytical views for Brewlevard:
--   1. v_current_stock     : Inventory monitoring across all items
--   2. v_low_stock         : Reorder alert (items at or below minimum)
--   3. v_expiring_batches  : Batches expired or expiring within 7 days
--   4. v_stock_history     : Full audit trail of stock in and stock out
--   5. v_cups_remaining    : Drink production capacity & bottleneck ingredient
--   6. v_restock_forecast  : Suggested purchase quantities for low stock
--   7. v_dashboard         : One-screen executive KPI overview
--   8. v_recipe_details    : Product recipe composition and servings
--   9. v_batch_inventory   : Batch-level tracking and consumption status
-- =====================================================================

USE brewlevard;

-- ---------------------------------------------------------------------
-- 1. v_current_stock: Inventory Monitoring
--    Displays current stock levels for every ingredient and supply,
--    categorized with units of measure, minimum stock, and stock status.
--    Used in 05_demo_script.sql Step 3 to verify item total.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_current_stock;
CREATE VIEW v_current_stock AS
SELECT
    i.item_id,
    i.item_name,
    c.category_name,
    i.quantity,
    u.abbreviation AS unit,
    u.unit_name,
    i.minimum_stock_level,
    i.status,
    CASE
        WHEN i.status = 'DISCONTINUED' THEN 'DISCONTINUED'
        WHEN i.quantity = 0 THEN 'OUT OF STOCK'
        WHEN i.quantity <= i.minimum_stock_level THEN 'LOW STOCK'
        ELSE 'IN STOCK'
    END AS stock_status
FROM inventory_item i
JOIN category c ON c.category_id = i.category_id
JOIN unit u     ON u.unit_id = i.unit_id
ORDER BY c.category_name ASC, i.item_name ASC;


-- ---------------------------------------------------------------------
-- 2. v_low_stock: Low-Stock Alerts
--    Lists active inventory items that have reached or fallen below
--    their assigned minimum stock levels (including items at zero).
--    Used in 05_demo_script.sql Step 9 and README.md.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_low_stock;
CREATE VIEW v_low_stock AS
SELECT
    i.item_id,
    i.item_name,
    c.category_name,
    i.quantity,
    u.abbreviation AS unit,
    i.minimum_stock_level,
    ROUND(i.minimum_stock_level - i.quantity, 3) AS deficit,
    CASE
        WHEN i.quantity = 0 THEN 'OUT OF STOCK'
        ELSE 'LOW STOCK'
    END AS stock_status
FROM inventory_item i
JOIN category c ON c.category_id = i.category_id
JOIN unit u     ON u.unit_id = i.unit_id
WHERE i.status = 'ACTIVE'
  AND i.quantity <= i.minimum_stock_level
ORDER BY i.quantity ASC, deficit DESC, i.item_name ASC;


-- ---------------------------------------------------------------------
-- 3. v_expiring_batches: Expiration Date Monitoring
--    Lists batches with remaining stock that are already expired or
--    nearing expiration within 7 days, allowing staff to prevent waste.
--    Used in 05_demo_script.sql Step 9 and README.md.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_expiring_batches;
CREATE VIEW v_expiring_batches AS
SELECT
    b.batch_id,
    b.item_id,
    i.item_name,
    c.category_name,
    b.quantity_remaining,
    u.abbreviation AS unit,
    b.date_received,
    b.expiration_date,
    DATEDIFF(b.expiration_date, CURDATE()) AS days_remaining,
    CASE
        WHEN b.expiration_date < CURDATE() THEN 'EXPIRED'
        WHEN b.expiration_date = CURDATE() THEN 'EXPIRES TODAY'
        ELSE 'EXPIRING SOON'
    END AS expiry_status
FROM stock_batch b
JOIN inventory_item i ON i.item_id = b.item_id
JOIN category c       ON c.category_id = i.category_id
JOIN unit u           ON u.unit_id = i.unit_id
WHERE b.expiration_date IS NOT NULL
  AND b.quantity_remaining > 0
  AND b.expiration_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
ORDER BY b.expiration_date ASC, b.quantity_remaining DESC;


-- ---------------------------------------------------------------------
-- 4. v_stock_history: Stock Movement History
--    Audit trail of all incoming and outgoing inventory transactions,
--    with dates, transaction types, batch references, reasons, and remarks.
--    Used in 05_demo_script.sql Step 5 and README.md.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_stock_history;
CREATE VIEW v_stock_history AS
SELECT
    t.transaction_id,
    t.transaction_date,
    t.item_id,
    i.item_name,
    c.category_name,
    t.batch_id,
    t.transaction_type,
    t.quantity,
    u.abbreviation AS unit,
    t.reason,
    b.expiration_date AS batch_expiration_date,
    t.remarks
FROM stock_transaction t
JOIN inventory_item i ON i.item_id = t.item_id
JOIN category c       ON c.category_id = i.category_id
JOIN unit u           ON u.unit_id = i.unit_id
JOIN stock_batch b    ON b.batch_id = t.batch_id
ORDER BY t.transaction_date DESC, t.transaction_id DESC;


-- ---------------------------------------------------------------------
-- 5. v_cups_remaining: Drink Production Capacity & Bottleneck
--    Computes the maximum number of servings/cups that can be made
--    for each product based on current stock, and identifies the
--    limiting ingredient (bottleneck).
--    Used in 05_demo_script.sql Step 9 and README.md.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_cups_remaining;
CREATE VIEW v_cups_remaining AS
WITH ingredient_servings AS (
    SELECT
        p.product_id,
        p.product_name,
        i.item_name AS limiting_ingredient,
        FLOOR((CASE WHEN i.status = 'ACTIVE' THEN i.quantity ELSE 0 END) / ri.quantity_required) AS possible_cups,
        ROW_NUMBER() OVER (
            PARTITION BY p.product_id
            ORDER BY ((CASE WHEN i.status = 'ACTIVE' THEN i.quantity ELSE 0 END) / ri.quantity_required) ASC,
                     i.item_id ASC
        ) AS rn
    FROM product p
    JOIN recipe_ingredient ri ON ri.product_id = p.product_id
    JOIN inventory_item i     ON i.item_id = ri.item_id
)
SELECT
    product_id,
    product_name,
    possible_cups AS cups_remaining,
    limiting_ingredient
FROM ingredient_servings
WHERE rn = 1
ORDER BY cups_remaining DESC, product_name ASC;


-- ---------------------------------------------------------------------
-- 6. v_restock_forecast: Reorder & Purchasing Forecast
--    Focuses on items at or below minimum stock level and computes
--    the exact shortage and suggested reorder quantity to reach
--    a healthy inventory buffer.
--    Used in 05_demo_script.sql Step 9.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_restock_forecast;
CREATE VIEW v_restock_forecast AS
SELECT
    i.item_id,
    i.item_name,
    c.category_name,
    i.quantity AS current_quantity,
    u.abbreviation AS unit,
    i.minimum_stock_level,
    ROUND(i.minimum_stock_level - i.quantity, 3) AS shortage,
    ROUND(GREATEST(i.minimum_stock_level * 2 - i.quantity, i.minimum_stock_level), 3) AS suggested_reorder_qty,
    CASE
        WHEN i.quantity = 0 THEN 'CRITICAL (OUT OF STOCK)'
        WHEN i.quantity < i.minimum_stock_level THEN 'HIGH (BELOW MINIMUM)'
        WHEN i.quantity = i.minimum_stock_level THEN 'MEDIUM (AT MINIMUM)'
        ELSE 'NORMAL'
    END AS priority
FROM inventory_item i
JOIN category c ON c.category_id = i.category_id
JOIN unit u     ON u.unit_id = i.unit_id
WHERE i.status = 'ACTIVE'
  AND i.quantity <= i.minimum_stock_level
ORDER BY
    CASE
        WHEN i.quantity = 0 THEN 1
        WHEN i.quantity < i.minimum_stock_level THEN 2
        ELSE 3
    END ASC,
    shortage DESC,
    i.item_name ASC;


-- ---------------------------------------------------------------------
-- 7. v_dashboard: One-Screen Executive Summary
--    Provides an instant KPI summary of active items, stock health,
--    expiring batches, products, and transaction counts in a single row.
--    Used in 05_demo_script.sql Step 9.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_dashboard;
CREATE VIEW v_dashboard AS
SELECT
    (SELECT COUNT(*) FROM inventory_item WHERE status = 'ACTIVE')                                                                   AS active_items,
    (SELECT COUNT(*) FROM inventory_item WHERE status = 'ACTIVE' AND quantity > minimum_stock_level)                                 AS items_in_stock,
    (SELECT COUNT(*) FROM inventory_item WHERE status = 'ACTIVE' AND quantity > 0 AND quantity <= minimum_stock_level)              AS low_stock_items,
    (SELECT COUNT(*) FROM inventory_item WHERE status = 'ACTIVE' AND quantity = 0)                                                 AS out_of_stock_items,
    (SELECT COUNT(*) FROM stock_batch WHERE quantity_remaining > 0)                                                                  AS active_batches,
    (SELECT COUNT(*) FROM stock_batch WHERE quantity_remaining > 0 AND expiration_date < CURDATE())                                  AS expired_batches_in_stock,
    (SELECT COUNT(*) FROM stock_batch WHERE quantity_remaining > 0 AND expiration_date >= CURDATE() AND expiration_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)) AS batches_expiring_soon,
    (SELECT COUNT(*) FROM product)                                                                                                   AS total_products,
    (SELECT COUNT(*) FROM stock_transaction)                                                                                         AS total_transactions;


-- ---------------------------------------------------------------------
-- 8. v_recipe_details: Product Recipe Composition
--    Shows each product's full recipe breakdown, required amounts,
--    current ingredient stock, and how many servings each ingredient supports.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_recipe_details;
CREATE VIEW v_recipe_details AS
SELECT
    p.product_id,
    p.product_name,
    i.item_id,
    i.item_name,
    ri.quantity_required,
    u.abbreviation AS unit,
    i.quantity AS current_stock,
    FLOOR((CASE WHEN i.status = 'ACTIVE' THEN i.quantity ELSE 0 END) / ri.quantity_required) AS servings_possible
FROM product p
JOIN recipe_ingredient ri ON ri.product_id = p.product_id
JOIN inventory_item i     ON i.item_id = ri.item_id
JOIN unit u               ON u.unit_id = i.unit_id
ORDER BY p.product_id ASC, i.item_name ASC;


-- ---------------------------------------------------------------------
-- 9. v_batch_inventory: Detailed Batch Inventory
--    Batch-by-batch status tracking showing date received, expiry date,
--    remaining vs received quantity, and consumption lifecycle status.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_batch_inventory;
CREATE VIEW v_batch_inventory AS
SELECT
    b.batch_id,
    b.item_id,
    i.item_name,
    c.category_name,
    b.quantity_received,
    b.quantity_remaining,
    u.abbreviation AS unit,
    b.date_received,
    b.expiration_date,
    DATEDIFF(b.expiration_date, CURDATE()) AS days_until_expiration,
    CASE
        WHEN b.quantity_remaining = 0 THEN 'DEPLETED'
        WHEN b.expiration_date IS NOT NULL AND b.expiration_date < CURDATE() THEN 'EXPIRED'
        WHEN b.expiration_date IS NOT NULL AND b.expiration_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY) THEN 'EXPIRING SOON'
        ELSE 'ACTIVE'
    END AS batch_status
FROM stock_batch b
JOIN inventory_item i ON i.item_id = b.item_id
JOIN category c       ON c.category_id = i.category_id
JOIN unit u           ON u.unit_id = i.unit_id
ORDER BY b.batch_id ASC;


-- ---------------------------------------------------------------------
-- Verification: Display all created views
-- ---------------------------------------------------------------------
SHOW FULL TABLES WHERE Table_type = 'VIEW';
