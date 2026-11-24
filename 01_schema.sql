CREATE DATABASE brewlevard
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE brewlevard;

-- ---------------------------------------------------------------------
-- 1. CATEGORY: groups of items (coffee beans, dairy, syrups, packaging)
-- ---------------------------------------------------------------------

CREATE TABLE category (
    category_id   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(100)  NOT NULL,
    description   VARCHAR(255)  NULL,
    PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name UNIQUE (category_name)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 2. UNIT: unit of measure (L, ml, kg, g, pcs)
-- ---------------------------------------------------------------------
CREATE TABLE unit (
    unit_id      INT UNSIGNED                      NOT NULL AUTO_INCREMENT,
    unit_name    VARCHAR(50)                       NOT NULL,
    abbreviation VARCHAR(10)                       NOT NULL,
    unit_type    ENUM('WEIGHT','VOLUME','COUNT')   NOT NULL,
    PRIMARY KEY (unit_id),
    CONSTRAINT uq_unit_name   UNIQUE (unit_name),
    CONSTRAINT uq_unit_abbrev UNIQUE (abbreviation)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 3. INVENTORY_ITEM: every ingredient and supply
--    quantity = summary of the item's batches, updated only by
--    sp_stock_in and sp_stock_out.
-- ---------------------------------------------------------------------
CREATE TABLE inventory_item (
    item_id             INT UNSIGNED                    NOT NULL AUTO_INCREMENT,
    category_id         INT UNSIGNED                    NOT NULL,
    unit_id             INT UNSIGNED                    NOT NULL,
    item_name           VARCHAR(100)                    NOT NULL,
    description         VARCHAR(255)                    NULL,
    quantity            DECIMAL(10,3)                   NOT NULL DEFAULT 0,
    status              ENUM('ACTIVE','DISCONTINUED')   NOT NULL DEFAULT 'ACTIVE',
    minimum_stock_level DECIMAL(10,3)                   NOT NULL DEFAULT 0,
    PRIMARY KEY (item_id),
    CONSTRAINT uq_item_name UNIQUE (item_name),
    CONSTRAINT fk_item_category FOREIGN KEY (category_id)
        REFERENCES category (category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_item_unit FOREIGN KEY (unit_id)
        REFERENCES unit (unit_id) ON DELETE RESTRICT,
    CONSTRAINT chk_item_quantity CHECK (quantity >= 0),
    CONSTRAINT chk_item_min_stock CHECK (minimum_stock_level >= 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 4. STOCK_BATCH: each delivery of an item (source of truth for stock)
-- ---------------------------------------------------------------------
CREATE TABLE stock_batch (
    batch_id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    item_id            INT UNSIGNED  NOT NULL,
    quantity_received  DECIMAL(10,3) NOT NULL,
    quantity_remaining DECIMAL(10,3) NOT NULL,
    date_received      DATE          NOT NULL,
    expiration_date    DATE          NULL,
    PRIMARY KEY (batch_id),
    CONSTRAINT fk_batch_item FOREIGN KEY (item_id)
        REFERENCES inventory_item (item_id) ON DELETE RESTRICT,
    CONSTRAINT chk_batch_received CHECK (quantity_received > 0),
    CONSTRAINT chk_batch_remaining CHECK (
        quantity_remaining >= 0 AND quantity_remaining <= quantity_received
    ),
    CONSTRAINT chk_batch_expiry CHECK (
        expiration_date IS NULL OR expiration_date >= date_received
    )
) ENGINE = InnoDB;

CREATE INDEX idx_batch_expiration ON stock_batch (expiration_date);

-- ---------------------------------------------------------------------
-- 5. STOCK_TRANSACTION: stock movement history (stock in / stock out)
--    One row per batch affected.
-- ---------------------------------------------------------------------
CREATE TABLE stock_transaction (
    transaction_id   INT UNSIGNED                                                   NOT NULL AUTO_INCREMENT,
    item_id          INT UNSIGNED                                                   NOT NULL,
    batch_id         INT UNSIGNED                                                   NOT NULL,
    transaction_type ENUM('STOCK_IN','STOCK_OUT')                                   NOT NULL,
    quantity         DECIMAL(10,3)                                                  NOT NULL,
    reason           ENUM('USED','DAMAGED','EXPIRED','PURCHASE','CORRECTION')       NOT NULL,
    transaction_date DATETIME                                                       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remarks          VARCHAR(255)                                                   NULL,
    PRIMARY KEY (transaction_id),
    CONSTRAINT fk_trans_item FOREIGN KEY (item_id)
        REFERENCES inventory_item (item_id) ON DELETE RESTRICT,
    CONSTRAINT fk_trans_batch FOREIGN KEY (batch_id)
        REFERENCES stock_batch (batch_id) ON DELETE RESTRICT,
    CONSTRAINT chk_trans_quantity CHECK (quantity > 0),
    -- STOCK_IN: PURCHASE, CORRECTION | STOCK_OUT: USED, DAMAGED, EXPIRED, CORRECTION
    CONSTRAINT chk_trans_reason CHECK (
        (transaction_type = 'STOCK_IN'  AND reason IN ('PURCHASE','CORRECTION'))
        OR
        (transaction_type = 'STOCK_OUT' AND reason IN ('USED','DAMAGED','EXPIRED','CORRECTION'))
    )
) ENGINE = InnoDB;

CREATE INDEX idx_trans_date ON stock_transaction (transaction_date);

-- ---------------------------------------------------------------------
-- 6. PRODUCT: drinks and food the shop makes
-- ---------------------------------------------------------------------
CREATE TABLE product (
    product_id   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    product_name VARCHAR(100)  NOT NULL,
    description  VARCHAR(255)  NULL,
    PRIMARY KEY (product_id),
    CONSTRAINT uq_product_name UNIQUE (product_name)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 7. RECIPE_INGREDIENT: ingredients needed per product (per 1 serving).
--    quantity_required uses the same unit as the item's unit.
-- ---------------------------------------------------------------------
CREATE TABLE recipe_ingredient (
    recipe_id         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    product_id        INT UNSIGNED  NOT NULL,
    item_id           INT UNSIGNED  NOT NULL,
    quantity_required DECIMAL(10,3) NOT NULL,
    PRIMARY KEY (recipe_id),
    CONSTRAINT uq_recipe_product_item UNIQUE (product_id, item_id),
    CONSTRAINT fk_recipe_product FOREIGN KEY (product_id)
        REFERENCES product (product_id) ON DELETE RESTRICT,
    CONSTRAINT fk_recipe_item FOREIGN KEY (item_id)
        REFERENCES inventory_item (item_id) ON DELETE RESTRICT,
    CONSTRAINT chk_recipe_quantity CHECK (quantity_required > 0)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Quick check after running: should list 7 tables
-- ---------------------------------------------------------------------
SHOW TABLES;