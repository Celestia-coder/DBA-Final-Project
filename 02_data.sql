USE brewlevard;
SET @today = CURDATE();

-- 1. CATEGORY
INSERT INTO category (category_id, category_name, description) VALUES
(1, 'Coffee Beans', 'Whole bean coffee for espresso and pour-over'),
(2, 'Dairy', 'Milk, cream and dairy alternatives'),
(3, 'Syrups & Sauces', 'Flavoring syrups and sauces'),
(4, 'Powders & Tea', 'Matcha, cocoa and tea'),
(5, 'Sweeteners & Add-ons', 'Sugar, spices and ice'),
(6, 'Brewing Supplies', 'Filters and machine care for brewing'),
(7, 'Packaging', 'Cups, lids, sleeves and straws'),
(8, 'Cleaning Supplies', 'Cleaning and sanitation');

-- 2. UNIT
INSERT INTO unit (unit_id, unit_name, abbreviation, unit_type) VALUES
(1, 'Liter', 'L', 'VOLUME'),
(2, 'Milliliter', 'ml', 'VOLUME'),
(3, 'Kilogram', 'kg', 'WEIGHT'),
(4, 'Gram', 'g', 'WEIGHT'),
(5, 'Piece', 'pcs', 'COUNT');

-- 3. INVENTORY_ITEM  (quantity = sum of the item's batches)
INSERT INTO inventory_item (item_id, category_id, unit_id, item_name, description, quantity, status, minimum_stock_level) VALUES
(1, 1, 3, 'Espresso Beans', 'Dark roast espresso blend', 5.300, 'ACTIVE', 3.000),
(2, 1, 3, 'Single-Origin Beans', 'Benguet arabica, medium roast', 2.800, 'ACTIVE', 2.000),
(3, 2, 1, 'Fresh Milk', 'Full cream fresh milk', 15.000, 'ACTIVE', 5.000),
(4, 2, 1, 'Whipping Cream', 'Heavy cream for toppings', 3.700, 'ACTIVE', 1.000),
(5, 2, 1, 'Oat Milk', 'Dairy-free milk alternative', 6.000, 'ACTIVE', 3.000),
(6, 2, 2, 'Condensed Milk', 'Sweetened condensed milk', 1300.000, 'ACTIVE', 1000.000),
(7, 3, 2, 'Caramel Syrup', 'Caramel flavoring syrup', 1500.000, 'ACTIVE', 1000.000),
(8, 3, 2, 'Vanilla Syrup', 'Vanilla flavoring syrup', 1400.000, 'ACTIVE', 1000.000),
(9, 3, 2, 'Hazelnut Syrup', 'Hazelnut flavoring syrup', 600.000, 'ACTIVE', 1000.000),
(10, 3, 2, 'Chocolate Sauce', 'Chocolate sauce for mocha', 1200.000, 'ACTIVE', 1000.000),
(11, 4, 4, 'Matcha Powder', 'Ceremonial grade matcha', 300.000, 'ACTIVE', 300.000),
(12, 4, 4, 'Cocoa Powder', 'Unsweetened cocoa powder', 1100.000, 'ACTIVE', 500.000),
(13, 4, 4, 'Black Tea Leaves', 'Loose black tea', 600.000, 'ACTIVE', 300.000),
(14, 5, 3, 'White Sugar', 'Refined white sugar', 3.000, 'ACTIVE', 2.000),
(15, 5, 3, 'Brown Sugar', 'Muscovado brown sugar', 1.500, 'ACTIVE', 1.000),
(16, 5, 4, 'Cinnamon Powder', 'Ground cinnamon for toppings', 250.000, 'ACTIVE', 100.000),
(17, 5, 3, 'Ice Cubes', 'Bagged ice cubes', 26.000, 'ACTIVE', 20.000),
(18, 6, 5, 'Coffee Paper Filters', 'V60 paper filters for pour-over', 150, 'ACTIVE', 100.000),
(19, 6, 4, 'Espresso Machine Cleaner', 'Backflush cleaning powder', 0.000, 'ACTIVE', 100.000),
(20, 7, 5, 'Paper Cup 12oz', 'Hot drink cup, 12 oz', 350, 'ACTIVE', 200.000),
(21, 7, 5, 'Paper Cup 16oz', 'Hot drink cup, 16 oz', 300, 'ACTIVE', 200.000),
(22, 7, 5, 'Plastic Cup 16oz', 'Cold drink cup, 16 oz', 280, 'ACTIVE', 200.000),
(23, 7, 5, 'Cup Lids', 'Universal cup lids', 650, 'ACTIVE', 300.000),
(24, 7, 5, 'Paper Straws', 'Biodegradable straws', 100, 'ACTIVE', 200.000),
(25, 7, 5, 'Cup Sleeves', 'Heat sleeves for hot cups', 250, 'ACTIVE', 100.000),
(26, 8, 1, 'Dishwashing Liquid', 'Dish soap for bar equipment', 4.500, 'ACTIVE', 2.000),
(27, 8, 1, 'Sanitizing Solution', 'Food-safe surface sanitizer', 3.500, 'ACTIVE', 2.000);

-- 4. PRODUCT
INSERT INTO product (product_id, product_name, description) VALUES
(1, 'Caffe Latte', 'Espresso with steamed milk'),
(2, 'Cappuccino', 'Espresso with milk foam and cinnamon'),
(3, 'Caramel Macchiato', 'Espresso with milk and caramel, 16oz'),
(4, 'Americano', 'Espresso with hot water'),
(5, 'Iced Latte', 'Espresso, milk and ice'),
(6, 'Hazelnut Latte', 'Latte with hazelnut syrup'),
(7, 'Mocha', 'Espresso with chocolate and milk'),
(8, 'Matcha Latte', 'Matcha with milk and sugar'),
(9, 'Iced Vanilla Latte', 'Iced latte with vanilla syrup'),
(10, 'Spanish Latte', 'Espresso with milk and sweetened condensed milk');

-- 5. RECIPE_INGREDIENT  (per 1 serving, in the item's own unit)
INSERT INTO recipe_ingredient (product_id, item_id, quantity_required) VALUES
-- Caffe Latte
(1, 1, 0.018),
(1, 3, 0.200),
(1, 20, 1.000),
(1, 23, 1.000),
-- Cappuccino
(2, 1, 0.018),
(2, 3, 0.150),
(2, 20, 1.000),
(2, 23, 1.000),
(2, 16, 2.000),
-- Caramel Macchiato
(3, 1, 0.018),
(3, 3, 0.180),
(3, 7, 30.000),
(3, 21, 1.000),
(3, 23, 1.000),
-- Americano
(4, 1, 0.018),
(4, 20, 1.000),
(4, 23, 1.000),
-- Iced Latte
(5, 1, 0.018),
(5, 3, 0.180),
(5, 17, 0.150),
(5, 22, 1.000),
(5, 23, 1.000),
-- Hazelnut Latte
(6, 1, 0.018),
(6, 3, 0.200),
(6, 9, 25.000),
(6, 20, 1.000),
(6, 23, 1.000),
-- Mocha
(7, 1, 0.018),
(7, 3, 0.180),
(7, 10, 30.000),
(7, 12, 5.000),
(7, 21, 1.000),
-- Matcha Latte
(8, 11, 4.000),
(8, 3, 0.200),
(8, 14, 0.010),
(8, 20, 1.000),
(8, 23, 1.000),
-- Iced Vanilla Latte
(9, 1, 0.018),
(9, 3, 0.180),
(9, 8, 20.000),
(9, 17, 0.150),
(9, 22, 1.000),
-- Spanish Latte
(10, 1, 0.018),
(10, 3, 0.150),
(10, 6, 30.000),
(10, 20, 1.000),
(10, 23, 1.000);

-- 6. STOCK_BATCH  (quantity_remaining already net of all STOCK_OUT rows below)
INSERT INTO stock_batch (batch_id, item_id, quantity_received, quantity_remaining, date_received, expiration_date) VALUES
(1, 1, 10.000, 0.000, DATE_SUB(@today, INTERVAL 45 DAY), DATE_ADD(@today, INTERVAL 60 DAY)), -- Espresso Beans | fully used
(2, 1, 10.000, 5.300, DATE_SUB(@today, INTERVAL 14 DAY), DATE_ADD(@today, INTERVAL 120 DAY)), -- Espresso Beans
(3, 2, 5.000, 2.800, DATE_SUB(@today, INTERVAL 30 DAY), DATE_ADD(@today, INTERVAL 90 DAY)), -- Single-Origin Beans
(4, 3, 15.000, 0.000, DATE_SUB(@today, INTERVAL 30 DAY), DATE_SUB(@today, INTERVAL 17 DAY)), -- Fresh Milk | fully used
(5, 3, 15.000, 0.000, DATE_SUB(@today, INTERVAL 20 DAY), DATE_SUB(@today, INTERVAL 7 DAY)), -- Fresh Milk | fully used
(6, 3, 10.000, 3.000, DATE_SUB(@today, INTERVAL 12 DAY), DATE_ADD(@today, INTERVAL 3 DAY)), -- Fresh Milk | expires within 7 days
(7, 3, 12.000, 12.000, DATE_SUB(@today, INTERVAL 3 DAY), DATE_ADD(@today, INTERVAL 10 DAY)), -- Fresh Milk
(8, 4, 4.000, 0.000, DATE_SUB(@today, INTERVAL 35 DAY), DATE_SUB(@today, INTERVAL 22 DAY)), -- Whipping Cream | fully used
(9, 4, 3.000, 1.200, DATE_SUB(@today, INTERVAL 12 DAY), DATE_SUB(@today, INTERVAL 2 DAY)), -- Whipping Cream | EXPIRED, still in stock
(10, 4, 3.000, 2.500, DATE_SUB(@today, INTERVAL 5 DAY), DATE_ADD(@today, INTERVAL 2 DAY)), -- Whipping Cream | expires within 7 days
(11, 5, 6.000, 2.000, DATE_SUB(@today, INTERVAL 35 DAY), DATE_SUB(@today, INTERVAL 3 DAY)), -- Oat Milk | EXPIRED, still in stock
(12, 5, 6.000, 4.000, DATE_SUB(@today, INTERVAL 14 DAY), DATE_ADD(@today, INTERVAL 60 DAY)), -- Oat Milk
(13, 6, 3000.000, 1300.000, DATE_SUB(@today, INTERVAL 30 DAY), DATE_ADD(@today, INTERVAL 5 DAY)), -- Condensed Milk | expires within 7 days
(14, 7, 3000.000, 1500.000, DATE_SUB(@today, INTERVAL 35 DAY), DATE_ADD(@today, INTERVAL 200 DAY)), -- Caramel Syrup
(15, 8, 3000.000, 1400.000, DATE_SUB(@today, INTERVAL 30 DAY), DATE_ADD(@today, INTERVAL 220 DAY)), -- Vanilla Syrup
(16, 9, 2500.000, 600.000, DATE_SUB(@today, INTERVAL 40 DAY), DATE_ADD(@today, INTERVAL 150 DAY)), -- Hazelnut Syrup
(17, 10, 2500.000, 1200.000, DATE_SUB(@today, INTERVAL 25 DAY), DATE_ADD(@today, INTERVAL 120 DAY)), -- Chocolate Sauce
(18, 11, 1000.000, 300.000, DATE_SUB(@today, INTERVAL 30 DAY), DATE_ADD(@today, INTERVAL 100 DAY)), -- Matcha Powder
(19, 12, 2000.000, 1100.000, DATE_SUB(@today, INTERVAL 35 DAY), DATE_ADD(@today, INTERVAL 200 DAY)), -- Cocoa Powder
(20, 13, 1000.000, 600.000, DATE_SUB(@today, INTERVAL 45 DAY), DATE_ADD(@today, INTERVAL 90 DAY)), -- Black Tea Leaves
(21, 14, 10.000, 3.000, DATE_SUB(@today, INTERVAL 40 DAY), NULL), -- White Sugar
(22, 15, 5.000, 1.500, DATE_SUB(@today, INTERVAL 38 DAY), NULL), -- Brown Sugar
(23, 16, 400.000, 250.000, DATE_SUB(@today, INTERVAL 30 DAY), DATE_ADD(@today, INTERVAL 300 DAY)), -- Cinnamon Powder
(24, 17, 60.000, 26.000, DATE_SUB(@today, INTERVAL 10 DAY), NULL), -- Ice Cubes
(25, 18, 300, 150, DATE_SUB(@today, INTERVAL 30 DAY), NULL), -- Coffee Paper Filters
(26, 19, 500.000, 0.000, DATE_SUB(@today, INTERVAL 25 DAY), NULL), -- Espresso Machine Cleaner | fully used
(27, 20, 1000, 350, DATE_SUB(@today, INTERVAL 40 DAY), NULL), -- Paper Cup 12oz
(28, 21, 600, 300, DATE_SUB(@today, INTERVAL 40 DAY), NULL), -- Paper Cup 16oz
(29, 22, 500, 280, DATE_SUB(@today, INTERVAL 30 DAY), NULL), -- Plastic Cup 16oz
(30, 23, 1500, 650, DATE_SUB(@today, INTERVAL 40 DAY), NULL), -- Cup Lids
(31, 24, 500, 100, DATE_SUB(@today, INTERVAL 35 DAY), NULL), -- Paper Straws
(32, 25, 400, 250, DATE_SUB(@today, INTERVAL 30 DAY), NULL), -- Cup Sleeves
(33, 26, 10.000, 4.500, DATE_SUB(@today, INTERVAL 30 DAY), NULL), -- Dishwashing Liquid
(34, 27, 5.000, 3.500, DATE_SUB(@today, INTERVAL 25 DAY), NULL); -- Sanitizing Solution

-- 7. STOCK_TRANSACTION  (movement history, oldest first)
-- one STOCK_IN per batch + the STOCK_OUT rows that drew from that batch
INSERT INTO stock_transaction (item_id, batch_id, transaction_type, quantity, reason, transaction_date, remarks) VALUES
(1, 1, 'STOCK_IN', 10.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 45 DAY), '08:00:00'), 'Supplier delivery'),
(13, 20, 'STOCK_IN', 1000.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 45 DAY), '08:00:00'), 'Supplier delivery'),
(9, 16, 'STOCK_IN', 2500.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 40 DAY), '08:00:00'), 'Supplier delivery'),
(14, 21, 'STOCK_IN', 10.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 40 DAY), '08:00:00'), 'Supplier delivery'),
(20, 27, 'STOCK_IN', 1000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 40 DAY), '08:00:00'), 'Supplier delivery'),
(21, 28, 'STOCK_IN', 600, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 40 DAY), '08:00:00'), 'Supplier delivery'),
(23, 30, 'STOCK_IN', 1500, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 40 DAY), '08:00:00'), 'Supplier delivery'),
(15, 22, 'STOCK_IN', 5.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 38 DAY), '08:00:00'), 'Supplier delivery'),
(4, 8, 'STOCK_IN', 4.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 35 DAY), '08:00:00'), 'Supplier delivery'),
(5, 11, 'STOCK_IN', 6.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 35 DAY), '08:00:00'), 'Supplier delivery'),
(7, 14, 'STOCK_IN', 3000.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 35 DAY), '08:00:00'), 'Supplier delivery'),
(12, 19, 'STOCK_IN', 2000.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 35 DAY), '08:00:00'), 'Supplier delivery'),
(24, 31, 'STOCK_IN', 500, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 35 DAY), '08:00:00'), 'Supplier delivery'),
(2, 3, 'STOCK_IN', 5.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 30 DAY), '08:00:00'), 'Supplier delivery'),
(3, 4, 'STOCK_IN', 15.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 30 DAY), '08:00:00'), 'Supplier delivery'),
(6, 13, 'STOCK_IN', 3000.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 30 DAY), '08:00:00'), 'Supplier delivery'),
(8, 15, 'STOCK_IN', 3000.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 30 DAY), '08:00:00'), 'Supplier delivery'),
(11, 18, 'STOCK_IN', 1000.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 30 DAY), '08:00:00'), 'Supplier delivery'),
(16, 23, 'STOCK_IN', 400.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 30 DAY), '08:00:00'), 'Supplier delivery'),
(18, 25, 'STOCK_IN', 300, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 30 DAY), '08:00:00'), 'Supplier delivery'),
(22, 29, 'STOCK_IN', 500, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 30 DAY), '08:00:00'), 'Supplier delivery'),
(25, 32, 'STOCK_IN', 400, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 30 DAY), '08:00:00'), 'Supplier delivery'),
(26, 33, 'STOCK_IN', 10.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 30 DAY), '08:00:00'), 'Supplier delivery'),
(1, 1, 'STOCK_OUT', 5.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 30 DAY), '17:30:00'), 'Weekly usage'),
(3, 4, 'STOCK_OUT', 7.500, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 27 DAY), '17:30:00'), 'Weekly usage'),
(10, 17, 'STOCK_IN', 2500.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 25 DAY), '08:00:00'), 'Supplier delivery'),
(19, 26, 'STOCK_IN', 500.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 25 DAY), '08:00:00'), 'Supplier delivery'),
(27, 34, 'STOCK_IN', 5.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 25 DAY), '08:00:00'), 'Supplier delivery'),
(3, 4, 'STOCK_OUT', 7.500, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 22 DAY), '17:30:00'), 'Weekly usage'),
(4, 8, 'STOCK_OUT', 3.300, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 22 DAY), '17:30:00'), 'Usage for the period'),
(4, 8, 'STOCK_OUT', 0.700, 'EXPIRED', TIMESTAMP(DATE_SUB(@today, INTERVAL 21 DAY), '17:30:00'), 'Discarded: past expiration date'),
(3, 5, 'STOCK_IN', 15.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 20 DAY), '08:00:00'), 'Supplier delivery'),
(5, 11, 'STOCK_OUT', 4.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 20 DAY), '17:30:00'), 'Usage for the period'),
(3, 5, 'STOCK_OUT', 7.500, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 17 DAY), '17:30:00'), 'Weekly usage'),
(1, 1, 'STOCK_OUT', 5.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 15 DAY), '17:30:00'), 'Weekly usage'),
(2, 3, 'STOCK_OUT', 2.200, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 15 DAY), '17:30:00'), 'Weekly usage'),
(1, 2, 'STOCK_IN', 10.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 14 DAY), '08:00:00'), 'Supplier delivery'),
(5, 12, 'STOCK_IN', 6.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 14 DAY), '08:00:00'), 'Supplier delivery'),
(3, 6, 'STOCK_IN', 10.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 12 DAY), '08:00:00'), 'Supplier delivery'),
(4, 9, 'STOCK_IN', 3.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 12 DAY), '08:00:00'), 'Supplier delivery'),
(3, 5, 'STOCK_OUT', 7.500, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 12 DAY), '17:30:00'), 'Weekly usage'),
(13, 20, 'STOCK_OUT', 400.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 12 DAY), '17:30:00'), 'Usage for the period'),
(17, 24, 'STOCK_IN', 60.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 10 DAY), '08:00:00'), 'Supplier delivery'),
(7, 14, 'STOCK_OUT', 1500.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 10 DAY), '17:30:00'), 'Usage for the period'),
(20, 27, 'STOCK_OUT', 650, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 10 DAY), '17:30:00'), 'Usage for the period'),
(21, 28, 'STOCK_OUT', 288, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 10 DAY), '17:30:00'), 'Usage for the period'),
(23, 30, 'STOCK_OUT', 850, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 10 DAY), '17:30:00'), 'Usage for the period'),
(27, 34, 'STOCK_OUT', 1.500, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 10 DAY), '17:30:00'), 'Weekly usage'),
(1, 2, 'STOCK_OUT', 2.500, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 9 DAY), '17:30:00'), 'Weekly usage'),
(4, 9, 'STOCK_OUT', 1.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 9 DAY), '17:30:00'), 'Used for toppings'),
(8, 15, 'STOCK_OUT', 1600.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 9 DAY), '17:30:00'), 'Usage for the period'),
(3, 6, 'STOCK_OUT', 4.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 8 DAY), '17:30:00'), 'Weekly usage'),
(12, 19, 'STOCK_OUT', 900.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 8 DAY), '17:30:00'), 'Usage for the period'),
(22, 29, 'STOCK_OUT', 220, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 8 DAY), '17:30:00'), 'Usage for the period'),
(6, 13, 'STOCK_OUT', 1700.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 6 DAY), '17:30:00'), 'Usage for the period'),
(18, 25, 'STOCK_OUT', 150, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 6 DAY), '17:30:00'), 'Usage for the period'),
(21, 28, 'STOCK_OUT', 12, 'DAMAGED', TIMESTAMP(DATE_SUB(@today, INTERVAL 6 DAY), '17:30:00'), 'Crushed during delivery'),
(4, 10, 'STOCK_IN', 3.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 5 DAY), '08:00:00'), 'Supplier delivery'),
(4, 9, 'STOCK_OUT', 0.800, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 5 DAY), '17:30:00'), 'Used for toppings'),
(10, 17, 'STOCK_OUT', 1300.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 5 DAY), '17:30:00'), 'Usage for the period'),
(16, 23, 'STOCK_OUT', 150.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 5 DAY), '17:30:00'), 'Usage for the period'),
(26, 33, 'STOCK_OUT', 5.500, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 5 DAY), '17:30:00'), 'Usage for the period'),
(9, 16, 'STOCK_OUT', 1900.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 4 DAY), '17:30:00'), 'Usage for the period'),
(15, 22, 'STOCK_OUT', 3.300, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 4 DAY), '17:30:00'), 'Usage for the period'),
(19, 26, 'STOCK_OUT', 500.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 4 DAY), '17:30:00'), 'Usage for the period'),
(25, 32, 'STOCK_OUT', 150, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 4 DAY), '17:30:00'), 'Usage for the period'),
(3, 7, 'STOCK_IN', 12.000, 'PURCHASE', TIMESTAMP(DATE_SUB(@today, INTERVAL 3 DAY), '08:00:00'), 'Supplier delivery'),
(3, 6, 'STOCK_OUT', 3.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 3 DAY), '17:30:00'), 'Weekly usage'),
(14, 21, 'STOCK_OUT', 7.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 3 DAY), '17:30:00'), 'Usage for the period'),
(1, 2, 'STOCK_OUT', 2.200, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 2 DAY), '17:30:00'), 'Weekly usage'),
(5, 12, 'STOCK_OUT', 2.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 2 DAY), '17:30:00'), 'Usage for the period'),
(11, 18, 'STOCK_OUT', 700.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 2 DAY), '17:30:00'), 'Usage for the period'),
(15, 22, 'STOCK_OUT', 0.200, 'CORRECTION', TIMESTAMP(DATE_SUB(@today, INTERVAL 2 DAY), '17:30:00'), 'Count correction after stock check'),
(24, 31, 'STOCK_OUT', 400, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 2 DAY), '17:30:00'), 'Usage for the period'),
(4, 10, 'STOCK_OUT', 0.500, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 1 DAY), '17:30:00'), 'Used for toppings'),
(17, 24, 'STOCK_OUT', 34.000, 'USED', TIMESTAMP(DATE_SUB(@today, INTERVAL 1 DAY), '17:30:00'), 'Usage for the period');

-- =====================================================================
-- SELF-CHECKS (run these after the inserts)
-- =====================================================================
-- Row counts (expect: 8, 5, 27, 10, 47, 34, 76)
SELECT 'category' AS tbl, COUNT(*) AS total FROM category
UNION ALL SELECT 'unit', COUNT(*) FROM unit
UNION ALL SELECT 'inventory_item', COUNT(*) FROM inventory_item
UNION ALL SELECT 'product', COUNT(*) FROM product
UNION ALL SELECT 'recipe_ingredient', COUNT(*) FROM recipe_ingredient
UNION ALL SELECT 'stock_batch', COUNT(*) FROM stock_batch
UNION ALL SELECT 'stock_transaction', COUNT(*) FROM stock_transaction;

-- Check 1: item quantity must equal the sum of its batches (expect 0 rows)
SELECT i.item_id, i.item_name, i.quantity AS item_qty, SUM(b.quantity_remaining) AS batch_total
FROM inventory_item i
JOIN stock_batch b ON b.item_id = i.item_id
GROUP BY i.item_id, i.item_name, i.quantity
HAVING i.quantity <> SUM(b.quantity_remaining);

-- Check 2: batch remaining must equal received - total STOCK_OUT (expect 0 rows)
SELECT b.batch_id, b.quantity_remaining,
       b.quantity_received - COALESCE(SUM(CASE WHEN t.transaction_type = 'STOCK_OUT' THEN t.quantity END), 0) AS expected
FROM stock_batch b
LEFT JOIN stock_transaction t ON t.batch_id = b.batch_id
GROUP BY b.batch_id, b.quantity_remaining, b.quantity_received
HAVING b.quantity_remaining <> expected;

-- Check 3: every batch has exactly one PURCHASE stock-in equal to quantity_received (expect 0 rows)
SELECT b.batch_id
FROM stock_batch b
LEFT JOIN stock_transaction t
       ON t.batch_id = b.batch_id AND t.transaction_type = 'STOCK_IN' AND t.reason = 'PURCHASE'
GROUP BY b.batch_id, b.quantity_received
HAVING COUNT(t.transaction_id) <> 1 OR SUM(t.quantity) <> b.quantity_received;