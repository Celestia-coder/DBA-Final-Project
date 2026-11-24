# Brewlevard: Coffee Shop Inventory Management System

A MySQL database for a small coffee and pastry shop. It keeps track of the ingredients and supplies used every day, such as coffee beans, milk, syrups, and plastic cups, so the admin always knows what is in stock, what is running low, and what is about to expire.

**Course:** COMP 018: Database Administration (Final Project)

**Members:**
- Bernabe, Julliane Triselle
- Esperon, Trisha Mae
- Fortus, Ralph Wende
- Salazar, Clarisse Jem

---

## What the system does

Managing inventory by hand makes it hard to see what is left, what was used, and what needs restocking. Brewlevard stores all of this in one database and answers those questions with SQL.

### Features

| Feature | What it does |
|---|---|
| **Inventory monitoring** | View the current quantity of every ingredient and supply, grouped by category (coffee beans, dairy, syrups, packaging) |
| **Stock management (CRUD)** | Add, view, update, and remove inventory items |
| **Stock in** | Record a new delivery. It creates a batch, logs the transaction, and adds to the item quantity |
| **Stock out** | Record used, damaged, expired, or corrected stock. It deducts from the batch with the earliest expiration date first (FEFO) |
| **Low-stock alerts** | Lists items at or below their minimum stock level |
| **Stock movement history** | Keeps a record of every stock in and stock out, with the date and quantity |
| **Expiration monitoring** | Shows batches that are expired or expiring soon |
| **Recipes** | Links each product (e.g. Latte) to the ingredients it needs, so we can compute how many cups can still be made |

### Rules built into the database

- Stock changes are made only through the stored procedures `sp_stock_in` and `sp_stock_out`, so the batch quantity, the item quantity, and the history always update together.
- Items that already have records are never erased. They are marked `DISCONTINUED` so the history is kept.
- An item can be permanently deleted only if it has no batches, transactions, or recipes (for example, when it was added by mistake).
- A stock-out larger than one batch continues to the next batch, and one transaction is recorded per batch affected.
- Quantities cannot be negative, and a batch's remaining quantity cannot be more than what was received.

### Not included

No frontend or app, no customer-facing interface, no dashboards or charts, and no connection to POS, payment, or supplier systems. Everything is done with SQL commands.

---

## Database design

The database has 7 tables.

| Table | Purpose |
|---|---|
| `category` | Groups of items (coffee beans, dairy, syrups, packaging) |
| `unit` | Units of measure (L, ml, kg, g, pcs) |
| `inventory_item` | Every ingredient and supply, with its current quantity and minimum stock level |
| `stock_batch` | Each delivery of an item, with its remaining quantity and expiration date |
| `stock_transaction` | The stock movement history (stock in and stock out) |
| `product` | The drinks and food the shop makes |
| `recipe_ingredient` | The ingredients and amounts needed for each product |

The tables are normalized up to Third Normal Form (3NF). `inventory_item.quantity` and `stock_transaction.item_id` are kept as deliberate summary columns for simpler reads, and they are updated only through the stored procedures.

---

## Setup

### Steps (MySQL Workbench)

1. Clone or download this repository.

```terminal
git clone https://github.com/Celestia-coder/DBA-Final-Project.git
cd DBA-Final-Project
code .
```

2. Open MySQL Workbench and connect to your local server.
3. Run the files **in this order**. For each one, use File > Open SQL Script, then click the lightning bolt.

| Order | File | What it does |
|---|---|---|
| 1 | `01_schema.sql` | Creates the `brewlevard` database and the 7 tables |
| 2 | `02_data.sql` | Inserts the sample data |
| 3 | `03_views.sql` | Creates the views used for reports |
| 4 | `04_procedures.sql` | Creates `sp_stock_in` and `sp_stock_out` |
| 5 | `05_demo_script.sql` | The commands we run during the presentation |

4. Check that it worked:

```sql
USE brewlevard;
SHOW TABLES;
```

You should see 7 tables.

### Steps (command line)

```bash
mysql -u root -p < 01_schema.sql
mysql -u root -p < 02_data.sql
mysql -u root -p < 03_views.sql
mysql -u root -p < 04_procedures.sql
```

### Start over

`01_schema.sql` drops and recreates the whole `brewlevard` database. Run the files again from step 1 to reset everything to the original sample data.

---

## Example usage

The report scenarios are wrapped in views, so each one is a single command.

```sql
USE brewlevard;

-- How many liters of milk are left?
SELECT item_name, quantity FROM inventory_item WHERE item_name = 'Fresh Milk';

-- Which items need restocking?
SELECT * FROM v_low_stock;

-- Which batches are expiring or already expired?
SELECT * FROM v_expiring_batches;

-- How many cups of each product can we still make?
SELECT * FROM v_cups_remaining;

-- Stock movement history
SELECT * FROM v_stock_history;
```

The commands for adding items, stock in, and stock out, with example values, are in `05_demo_script.sql`.

---

## Repository contents

```
brewlevard/
├── 01_schema.sql        Database and tables
├── 02_data.sql          Sample data
├── 03_views.sql         Report views
├── 04_procedures.sql    Stock in and stock out procedures
├── 05_demo_script.sql   Commands for the presentation
└── README.md
```