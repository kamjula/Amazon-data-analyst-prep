-- ============================================
-- Day 2: FILTERING AND AGGREGATION
-- Amazon Data Analyst Prep
-- ============================================
-- Covers: WHERE (advanced), AND/OR/NOT, IN, BETWEEN,
--         LIKE, GROUP BY, HAVING, aggregate functions
--         (COUNT, SUM, AVG, MIN, MAX), ROLLUP

-- Schema reference:
-- products(product_id, product_name, category, price, stock_qty)
-- customers(customer_id, customer_name, country, segment, created_date)
-- orders(order_id, customer_id, order_date, total_amount, status)
-- order_items(order_id, product_id, quantity, unit_price)

-- ============================================
-- SECTION A: ADVANCED FILTERING
-- ============================================

-- EXERCISE 1: AND / OR / NOT operators
-- Active orders in 2024 from USA or Canada
SELECT order_id, customer_id, order_date, total_amount, status
FROM orders
WHERE status = 'Completed'
  AND EXTRACT(YEAR FROM order_date) = 2024
  AND customer_id IN (
        SELECT customer_id FROM customers
        WHERE country IN ('USA', 'Canada')
    )
ORDER BY order_date DESC;

-- EXERCISE 2: NOT IN - Exclude specific statuses
SELECT order_id, customer_id, order_date, total_amount, status
FROM orders
WHERE status NOT IN ('Cancelled', 'Refunded')
ORDER BY order_date DESC;

-- EXERCISE 3: BETWEEN for ranges
-- Orders with amounts between $100 and $1,000 placed in Q1 2024
SELECT order_id, customer_id, order_date, total_amount
FROM orders
WHERE total_amount BETWEEN 100 AND 1000
  AND order_date BETWEEN '2024-01-01' AND '2024-03-31'
ORDER BY total_amount DESC;

-- EXERCISE 4: LIKE patterns for string filtering
-- Products with 'Pro' in name or starting with 'Smart'
SELECT product_name, category, price
FROM products
WHERE product_name LIKE '%Pro%'
   OR product_name LIKE 'Smart%'
ORDER BY product_name;

-- EXERCISE 5: Compound filter - real-world scenario
-- Find premium customers (VIP segment) in USA who ordered > $500 in 2024
SELECT DISTINCT
    c.customer_id,
    c.customer_name,
    c.country,
    c.segment
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE c.country  = 'USA'
  AND c.segment  = 'VIP'
  AND o.total_amount > 500
  AND o.order_date >= '2024-01-01'
ORDER BY c.customer_name;

-- ============================================
-- SECTION B: AGGREGATE FUNCTIONS
-- ============================================

-- EXERCISE 6: COUNT - How many orders?
SELECT
    COUNT(*)                        AS total_orders,
    COUNT(DISTINCT customer_id)     AS unique_customers,
    COUNT(CASE WHEN status = 'Completed' THEN 1 END) AS completed_orders
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2024;

-- EXERCISE 7: SUM and AVG - Revenue metrics
SELECT
    SUM(total_amount)               AS total_revenue,
    ROUND(AVG(total_amount), 2)     AS avg_order_value,
    MIN(total_amount)               AS smallest_order,
    MAX(total_amount)               AS largest_order
FROM orders
WHERE status = 'Completed';

-- EXERCISE 8: GROUP BY - Revenue by category
SELECT
    p.category,
    COUNT(DISTINCT oi.order_id)         AS order_count,
    SUM(oi.quantity)                    AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)  AS total_revenue,
    ROUND(AVG(oi.unit_price), 2)        AS avg_unit_price
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id
INNER JOIN orders      o  ON oi.order_id  = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.category
ORDER BY total_revenue DESC;

-- EXERCISE 9: GROUP BY multiple columns
-- Revenue and order count by country and segment
SELECT
    c.country,
    c.segment,
    COUNT(DISTINCT o.order_id)      AS orders,
    COUNT(DISTINCT o.customer_id)   AS customers,
    ROUND(SUM(o.total_amount), 2)   AS revenue,
    ROUND(AVG(o.total_amount), 2)   AS avg_order_value
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY c.country, c.segment
ORDER BY c.country, revenue DESC;

-- EXERCISE 10: HAVING - Filter on aggregated results
-- Categories with more than 50 orders and avg order value > $200
SELECT
    p.category,
    COUNT(DISTINCT oi.order_id)         AS order_count,
    ROUND(AVG(oi.unit_price), 2)        AS avg_price,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category
HAVING COUNT(DISTINCT oi.order_id) > 50
   AND AVG(oi.unit_price) > 200
ORDER BY total_revenue DESC;

-- EXERCISE 11: HAVING vs WHERE (key difference)
-- WHERE filters BEFORE aggregation; HAVING filters AFTER
-- Wrong: cannot use aggregate in WHERE
-- SELECT category, AVG(price) FROM products WHERE AVG(price) > 100 -- ERROR

-- Correct: use HAVING for post-aggregation filter
SELECT category, ROUND(AVG(price), 2) AS avg_price, COUNT(*) AS product_count
FROM products
GROUP BY category
HAVING AVG(price) > 100
ORDER BY avg_price DESC;

-- EXERCISE 12: COUNT with conditional aggregation
-- Order status breakdown per customer
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN status = 'Completed'  THEN 1 END) AS completed,
    COUNT(CASE WHEN status = 'Pending'    THEN 1 END) AS pending,
    COUNT(CASE WHEN status = 'Cancelled'  THEN 1 END) AS cancelled,
    ROUND(
          COUNT(CASE WHEN status = 'Cancelled' THEN 1 END) * 100.0 / COUNT(*), 1
      ) AS cancel_rate_pct
FROM orders
GROUP BY customer_id
ORDER BY total_orders DESC
LIMIT 20;

-- EXERCISE 13: MIN / MAX with GROUP BY
-- Best and worst single order per customer
SELECT
    customer_id,
    MIN(total_amount)   AS smallest_order,
    MAX(total_amount)   AS largest_order,
    MAX(order_date)     AS most_recent_order,
    MIN(order_date)     AS first_order
FROM orders
GROUP BY customer_id
ORDER BY largest_order DESC;

-- EXERCISE 14: ROLLUP - Subtotals and grand total
-- Sales subtotals by country, then grand total
SELECT
    COALESCE(c.country, 'ALL COUNTRIES')    AS country,
    COALESCE(c.segment, 'ALL SEGMENTS')     AS segment,
    COUNT(DISTINCT o.order_id)              AS orders,
    ROUND(SUM(o.total_amount), 2)           AS total_revenue
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'Completed'
GROUP BY ROLLUP(c.country, c.segment)
ORDER BY country, segment;

-- EXERCISE 15: Amazon-style aggregation interview query
-- Monthly active customers and revenue trend for 2024
SELECT
    DATE_TRUNC('month', o.order_date)           AS month,
    COUNT(DISTINCT o.customer_id)               AS active_customers,
    COUNT(DISTINCT o.order_id)                  AS total_orders,
    ROUND(SUM(o.total_amount), 2)               AS monthly_revenue,
    ROUND(SUM(o.total_amount) /
            NULLIF(COUNT(DISTINCT o.customer_id), 0), 2) AS revenue_per_customer
FROM orders o
WHERE o.status = 'Completed'
  AND o.order_date BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month ASC;
