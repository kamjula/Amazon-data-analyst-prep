-- ============================================
-- Day 3: SQL JOINS - Amazon Data Analyst Prep
-- ============================================
-- Covers: INNER, LEFT, RIGHT, FULL OUTER, CROSS,
--         Self-Join, Multi-table joins, anti-joins

-- Sample schema used throughout Day 3
-- customers(customer_id, customer_name, country, email, segment)
-- orders(order_id, customer_id, order_date, total_amount, status)
-- products(product_id, product_name, category, price)
-- order_items(order_id, product_id, quantity, unit_price)
-- employees(employee_id, employee_name, manager_id, department_id, salary)

-- ============================================
-- EXERCISE 1: INNER JOIN - Basic customer orders
-- ============================================
-- Returns only rows with matches in BOTH tables
SELECT
    c.customer_id,
    c.customer_name,
    o.order_id,
    o.order_date,
    o.total_amount
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-01'
ORDER BY o.order_date DESC;

-- ============================================
-- EXERCISE 2: LEFT JOIN - All customers, with or without orders
-- ============================================
-- Returns ALL rows from left table; NULL for non-matching right rows
SELECT
    c.customer_id,
    c.customer_name,
    c.country,
    COUNT(o.order_id)      AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS lifetime_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.country
ORDER BY lifetime_value DESC;

-- ============================================
-- EXERCISE 3: RIGHT JOIN - All orders, even if customer deleted
-- ============================================
SELECT
    o.order_id,
    o.order_date,
    o.total_amount,
    c.customer_name,
    c.country
FROM customers c
RIGHT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL  -- orphaned orders (no matching customer)
ORDER BY o.order_date DESC;

-- ============================================
-- EXERCISE 4: FULL OUTER JOIN - All customers AND all orders
-- ============================================
SELECT
    c.customer_id,
    c.customer_name,
    o.order_id,
    o.total_amount,
    CASE
        WHEN c.customer_id IS NULL THEN 'Orphaned Order'
        WHEN o.order_id    IS NULL THEN 'No Orders Yet'
        ELSE 'Matched'
    END AS match_status
FROM customers c
FULL OUTER JOIN orders o ON c.customer_id = o.customer_id
ORDER BY match_status, c.customer_id;

-- ============================================
-- EXERCISE 5: CROSS JOIN - Cartesian product
-- ============================================
-- Use case: generate all possible product-region combinations
SELECT
    p.product_name,
    r.region_name,
    p.price AS list_price
FROM products p
CROSS JOIN (
      VALUES ('North'), ('South'), ('East'), ('West')
  ) AS r(region_name)
ORDER BY p.product_name, r.region_name;

-- ============================================
-- EXERCISE 6: Self-Join - Employee / Manager hierarchy
-- ============================================
SELECT
    e.employee_name  AS employee,
    m.employee_name  AS manager,
    e.department_id
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
ORDER BY e.department_id, e.employee_name;

-- ============================================
-- EXERCISE 7: Multi-table JOIN (4 tables)
-- ============================================
-- Full order line-item detail with customer and product names
SELECT
    c.customer_name,
    o.order_date,
    p.product_name,
    p.category,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price)       AS line_total,
    SUM(oi.quantity * oi.unit_price)
        OVER (PARTITION BY o.order_id)  AS order_total
FROM orders o
INNER JOIN customers   c  ON o.customer_id  = c.customer_id
INNER JOIN order_items oi ON o.order_id     = oi.order_id
INNER JOIN products    p  ON oi.product_id  = p.product_id
WHERE o.status = 'Completed'
ORDER BY o.order_date DESC, line_total DESC;

-- ============================================
-- EXERCISE 8: Anti-Join - Customers who NEVER ordered
-- ============================================
-- Method 1: LEFT JOIN + IS NULL
SELECT c.customer_id, c.customer_name, c.email
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Method 2: NOT EXISTS (often faster on large tables)
SELECT c.customer_id, c.customer_name, c.email
FROM customers c
WHERE NOT EXISTS (
      SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
  );

-- ============================================
-- EXERCISE 9: JOIN with aggregation + HAVING
-- ============================================
-- High-value customers (lifetime spend > $1,000) in each country
SELECT
    c.country,
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id)   AS order_count,
    SUM(o.total_amount)          AS total_spent,
    AVG(o.total_amount)          AS avg_order_value,
    MAX(o.order_date)            AS last_order_date
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.country, c.customer_id, c.customer_name
HAVING SUM(o.total_amount) > 1000
ORDER BY c.country, total_spent DESC;

-- ============================================
-- EXERCISE 10: Complex business scenario
-- ============================================
-- Top product per category by revenue (last 90 days)
WITH category_revenue AS (
      SELECT
          p.category,
          p.product_id,
          p.product_name,
          SUM(oi.quantity * oi.unit_price) AS revenue,
          COUNT(DISTINCT o.order_id)       AS orders
      FROM products    p
      INNER JOIN order_items oi ON p.product_id  = oi.product_id
      INNER JOIN orders      o  ON oi.order_id   = o.order_id
      WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
      GROUP BY p.category, p.product_id, p.product_name
  ),
ranked AS (
      SELECT *,
          RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
      FROM category_revenue
  )
SELECT category, product_name, revenue, orders
FROM ranked
WHERE rnk = 1
ORDER BY revenue DESC;
