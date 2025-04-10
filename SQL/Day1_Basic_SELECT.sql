-- ============================================
-- Day 1: BASIC SELECT QUERIES
-- Amazon Data Analyst Prep
-- ============================================
-- Covers: SELECT, FROM, WHERE, ORDER BY, LIMIT,
--         column aliases, DISTINCT, NULL handling

-- Sample schema:
-- products(product_id, product_name, category, price, stock_qty, created_at)
-- customers(customer_id, customer_name, email, country, segment, created_date)
-- orders(order_id, customer_id, order_date, total_amount, status)

-- ============================================
-- EXERCISE 1: Basic SELECT - All columns
-- ============================================
SELECT *
FROM products;

-- ============================================
-- EXERCISE 2: SELECT specific columns
-- ============================================
SELECT
    product_id,
        product_name,
            category,
                price
                FROM products;

                -- ============================================
                -- EXERCISE 3: Column Aliases - Readable output
                -- ============================================
                SELECT
                    product_id       AS id,
                        product_name     AS name,
                            category         AS product_category,
                                price            AS price_usd,
                                    stock_qty        AS units_in_stock
                                    FROM products;

                                    -- ============================================
                                    -- EXERCISE 4: WHERE - Filter rows by condition
                                    -- ============================================
                                    -- Products in the 'Electronics' category
                                    SELECT product_id, product_name, price
                                    FROM products
                                    WHERE category = 'Electronics';

                                    -- ============================================
                                    -- EXERCISE 5: WHERE with comparison operators
                                    -- ============================================
                                    -- Products priced between $50 and $500
                                    SELECT product_name, category, price
                                    FROM products
                                    WHERE price >= 50
                                      AND price <= 500
                                      ORDER BY price ASC;

                                      -- Equivalent using BETWEEN
                                      SELECT product_name, category, price
                                      FROM products
                                      WHERE price BETWEEN 50 AND 500
                                      ORDER BY price ASC;

                                      -- ============================================
                                      -- EXERCISE 6: WHERE with multiple conditions
                                      -- ============================================
                                      -- Electronics OR Apparel products with price < $100
                                      SELECT product_name, category, price
                                      FROM products
                                      WHERE (category = 'Electronics' OR category = 'Apparel')
                                        AND price < 100
                                        ORDER BY category, price;

                                        -- ============================================
                                        -- EXERCISE 7: IN operator - Match list of values
                                        -- ============================================
                                        SELECT product_name, category, price
                                        FROM products
                                        WHERE category IN ('Electronics', 'Apparel', 'Footwear')
                                        ORDER BY category, price DESC;

                                        -- ============================================
                                        -- EXERCISE 8: LIKE - Pattern matching
                                        -- ============================================
                                        -- Products whose name starts with 'Pro'
                                        SELECT product_name, price
                                        FROM products
                                        WHERE product_name LIKE 'Pro%';

                                        -- Products with 'wireless' anywhere in name (case-insensitive)
                                        SELECT product_name, price
                                        FROM products
                                        WHERE LOWER(product_name) LIKE '%wireless%';

                                        -- ============================================
                                        -- EXERCISE 9: NULL handling
                                        -- ============================================
                                        -- Customers with no email on file
                                        SELECT customer_id, customer_name
                                        FROM customers
                                        WHERE email IS NULL;

                                        -- Customers WITH email (NOT NULL)
                                        SELECT customer_id, customer_name, email
                                        FROM customers
                                        WHERE email IS NOT NULL;

                                        -- Replace NULL email with a default value using COALESCE
                                        SELECT
                                            customer_id,
                                                customer_name,
                                                    COALESCE(email, 'no-email@placeholder.com') AS email
                                                    FROM customers;

                                                    -- ============================================
                                                    -- EXERCISE 10: DISTINCT - Remove duplicates
                                                    -- ============================================
                                                    -- Unique categories in product catalog
                                                    SELECT DISTINCT category
                                                    FROM products
                                                    ORDER BY category;

                                                    -- Unique country-segment combinations in customers
                                                    SELECT DISTINCT country, segment
                                                    FROM customers
                                                    ORDER BY country, segment;

                                                    -- ============================================
                                                    -- EXERCISE 11: ORDER BY - Sort results
                                                    -- ============================================
                                                    -- Top 10 most expensive products
                                                    SELECT product_name, category, price
                                                    FROM products
                                                    ORDER BY price DESC
                                                    LIMIT 10;

                                                    -- Cheapest in-stock item per category (sorted asc)
                                                    SELECT product_name, category, price, stock_qty
                                                    FROM products
                                                    WHERE stock_qty > 0
                                                    ORDER BY category ASC, price ASC;

                                                    -- ============================================
                                                    -- EXERCISE 12: LIMIT / TOP - Restrict row count
                                                    -- ============================================
                                                    -- Latest 5 orders placed
                                                    SELECT order_id, customer_id, order_date, total_amount, status
                                                    FROM orders
                                                    ORDER BY order_date DESC
                                                    LIMIT 5;

                                                    -- ============================================
                                                    -- EXERCISE 13: Computed columns
                                                    -- ============================================
                                                    -- Total inventory value per product
                                                    SELECT
                                                        product_name,
                                                            price,
                                                                stock_qty,
                                                                    ROUND(price * stock_qty, 2) AS inventory_value
                                                                    FROM products
                                                                    ORDER BY inventory_value DESC;

                                                                    -- ============================================
                                                                    -- EXERCISE 14: Amazon-style interview scenario
                                                                    -- ============================================
                                                                    -- Find customers from the USA who signed up in 2024
                                                                    -- sorted by most recent signup
                                                                    SELECT
                                                                        customer_id,
                                                                            customer_name,
                                                                                email,
                                                                                    created_date
                                                                                    FROM customers
                                                                                    WHERE country = 'USA'
                                                                                      AND EXTRACT(YEAR FROM created_date) = 2024
                                                                                      ORDER BY created_date DESC;

                                                                                      -- ============================================
                                                                                      -- EXERCISE 15: Combine everything - Real-world query
                                                                                      -- ============================================
                                                                                      -- Active Electronics products priced $50-$999,
                                                                                      -- with non-null stock, sorted by price ascending
                                                                                      SELECT
                                                                                          product_id,
                                                                                              product_name,
                                                                                                  category,
                                                                                                      price                           AS price_usd,
                                                                                                          stock_qty                       AS units_in_stock,
                                                                                                              ROUND(price * stock_qty, 2)     AS inventory_value
                                                                                                              FROM products
                                                                                                              WHERE category    = 'Electronics'
                                                                                                                AND price       BETWEEN 50 AND 999
                                                                                                                  AND stock_qty   IS NOT NULL
                                                                                                                    AND stock_qty   > 0
                                                                                                                    ORDER BY price ASC;
