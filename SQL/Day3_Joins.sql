-- See Day-3-joinss/day3_joins.sql for the complete Day 3 Joins exercises.
-- This file links to the full content for consistency with the SQL/ folder structure.

-- ============================================
-- Day 3: SQL JOINS - Quick Reference
-- Amazon Data Analyst Prep
-- ============================================
-- Full exercises: Day-3-joinss/day3_joins.sql
-- Covers: INNER JOIN, LEFT JOIN, RIGHT JOIN,
--         FULL OUTER JOIN, CROSS JOIN, Self-Join,
--         Multi-table JOINs, Anti-Joins

-- QUICK SYNTAX REFERENCE:

-- INNER JOIN: Only matching rows
SELECT c.customer_name, o.order_id, o.total_amount
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;

-- LEFT JOIN: All left rows + matching right rows (NULLs for non-matches)
SELECT c.customer_name, COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name;

-- RIGHT JOIN: All right rows + matching left rows
SELECT c.customer_name, o.order_id
FROM customers c
RIGHT JOIN orders o ON c.customer_id = o.customer_id;

-- FULL OUTER JOIN: All rows from both tables
SELECT c.customer_id, o.order_id
FROM customers c
FULL OUTER JOIN orders o ON c.customer_id = o.customer_id;

-- CROSS JOIN: Every row x every row (Cartesian product)
SELECT p.product_name, r.region_name
FROM products p
CROSS JOIN regions r;

-- SELF JOIN: Table joined to itself
SELECT e.employee_name AS employee, m.employee_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;

-- ANTI-JOIN: Rows in left with NO match in right
SELECT c.customer_id, c.customer_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;  -- Never ordered

-- For full 10-exercise practice set, see: Day-3-joinss/day3_joins.sql
