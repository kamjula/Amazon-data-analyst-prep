-- ============================================
-- Day 4: SUBQUERIES AND CTEs
-- ============================================

-- EXERCISE 1: Scalar Subquery - Find products with above-average price
SELECT product_id, product_name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- EXERCISE 2: Subquery in FROM - Customer purchase frequency
SELECT customer_id, purchase_count
FROM (
    SELECT customer_id, COUNT(*) as purchase_count
    FROM orders
    GROUP BY customer_id
) customer_purchases
WHERE purchase_count > 5;

-- EXERCISE 3: Subquery in WHERE - Find customers who purchased specific product
SELECT DISTINCT c.customer_id, c.customer_name
FROM customers c
WHERE c.customer_id IN (
    SELECT customer_id FROM orders
    WHERE product_id = 101
);

-- EXERCISE 4: Correlated Subquery - Compare employee salary to department average
SELECT employee_id, employee_name, salary
FROM employees e1
WHERE salary > (
    SELECT AVG(salary) 
    FROM employees e2 
    WHERE e2.department_id = e1.department_id
);

-- EXERCISE 5: Multiple Subqueries - Complex business logic
SELECT o.order_id, o.customer_id, o.order_date, o.total_amount
FROM orders o
WHERE o.customer_id IN (
    SELECT customer_id FROM customers
    WHERE country = 'USA'
)
AND o.total_amount > (SELECT AVG(total_amount) FROM orders);

-- EXERCISE 6: CTE (WITH clause) - Multi-step analysis
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) as month,
        SUM(total_amount) as monthly_revenue
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT month, monthly_revenue,
       LAG(monthly_revenue) OVER (ORDER BY month) as prev_month_revenue
FROM monthly_sales;

-- EXERCISE 7: Multiple CTEs - Customer lifetime value
WITH customer_purchases AS (
    SELECT customer_id, COUNT(*) as purchase_count, SUM(total_amount) as total_spent
    FROM orders
    GROUP BY customer_id
),
purchase_metrics AS (
    SELECT 
        customer_id,
        purchase_count,
        total_spent,
        total_spent / purchase_count as avg_order_value
    FROM customer_purchases
)
SELECT customer_id, purchase_count, total_spent, avg_order_value
FROM purchase_metrics
WHERE total_spent > 1000;

-- EXERCISE 8: Recursive CTE - Organizational hierarchy
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: CEO (employee_id = 1)
    SELECT employee_id, employee_name, manager_id, 0 as level
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: employees and their reports
    SELECT e.employee_id, e.employee_name, e.manager_id, eh.level + 1
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT employee_id, employee_name, manager_id, level
FROM employee_hierarchy
ORDER BY level, employee_id;

-- EXERCISE 9: Subquery vs CTE - Readability improvement
-- Poor readability (nested subqueries)
SELECT customer_id, order_count
FROM (
    SELECT customer_id, COUNT(*) as order_count
    FROM (
        SELECT customer_id FROM orders
        WHERE order_date >= CURRENT_DATE - INTERVAL 30 DAY
    ) recent_orders
    GROUP BY customer_id
) order_summary;

-- Better readability (CTE)
WITH recent_orders AS (
    SELECT customer_id
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL 30 DAY
),
order_summary AS (
    SELECT customer_id, COUNT(*) as order_count
    FROM recent_orders
    GROUP BY customer_id
)
SELECT customer_id, order_count
FROM order_summary;

-- EXERCISE 10: Complex CTE - Sales analysis with multiple layers
WITH sales_data AS (
    SELECT 
        o.order_date,
        o.product_id,
        p.category,
        o.quantity,
        o.unit_price,
        (o.quantity * o.unit_price) as total_sale
    FROM orders o
    JOIN products p ON o.product_id = p.product_id
),
daily_summary AS (
    SELECT 
        DATE_TRUNC('day', order_date) as sale_date,
        category,
        SUM(total_sale) as daily_category_sales,
        COUNT(*) as transaction_count
    FROM sales_data
    GROUP BY DATE_TRUNC('day', order_date), category
)
SELECT 
    sale_date, 
    category, 
    daily_category_sales,
    SUM(daily_category_sales) OVER (PARTITION BY category ORDER BY sale_date) as cumulative_sales
FROM daily_summary
ORDER BY sale_date, category;


-- ============================================
-- Day 5: WINDOW FUNCTIONS
-- ============================================

-- EXERCISE 1: ROW_NUMBER() - Rank customers by spending
SELECT 
    customer_id,
    total_spent,
    ROW_NUMBER() OVER (ORDER BY total_spent DESC) as spending_rank
FROM (
    SELECT customer_id, SUM(total_amount) as total_spent
    FROM orders
    GROUP BY customer_id
) customer_spending;

-- EXERCISE 2: RANK() vs DENSE_RANK() - Handle ties properly
SELECT 
    employee_id,
    salary,
    RANK() OVER (ORDER BY salary DESC) as rank_with_gaps,
    DENSE_RANK() OVER (ORDER BY salary DESC) as rank_without_gaps
FROM employees;

-- EXERCISE 3: PARTITION BY - Sales ranking within each region
SELECT 
    region,
    salesperson_name,
    sales_amount,
    RANK() OVER (PARTITION BY region ORDER BY sales_amount DESC) as region_rank
FROM sales_team;

-- EXERCISE 4: LAG() and LEAD() - Month-over-month growth
SELECT 
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) as prev_month_revenue,
    LEAD(revenue) OVER (ORDER BY month) as next_month_revenue,
    ROUND(((revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month) * 100), 2) as mom_growth_pct
FROM monthly_sales
ORDER BY month;

-- EXERCISE 5: Running Total - Cumulative revenue by date
SELECT 
    order_date,
    daily_revenue,
    SUM(daily_revenue) OVER (ORDER BY order_date) as cumulative_revenue,
    AVG(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as moving_avg_7day
FROM (
    SELECT DATE_TRUNC('day', order_date) as order_date, SUM(total_amount) as daily_revenue
    FROM orders
    GROUP BY DATE_TRUNC('day', order_date)
) daily_sales;

-- EXERCISE 6: NTILE() - Segment customers into quartiles by spending
SELECT 
    customer_id,
    total_spent,
    NTILE(4) OVER (ORDER BY total_spent) as spending_quartile
FROM (
    SELECT customer_id, SUM(total_amount) as total_spent
    FROM orders
    GROUP BY customer_id
) customer_spending;

-- EXERCISE 7: FIRST_VALUE() and LAST_VALUE() - Compare to best/worst
SELECT 
    salesperson_id,
    month,
    sales,
    FIRST_VALUE(sales) OVER (PARTITION BY salesperson_id ORDER BY month) as first_month_sales,
    LAST_VALUE(sales) OVER (PARTITION BY salesperson_id ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as best_month_sales
FROM sales_performance;

-- EXERCISE 8: Multiple Window Functions - Comprehensive customer analysis
SELECT 
    customer_id,
    order_date,
    order_amount,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) as order_sequence,
    LAG(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date) as previous_order_amount,
    SUM(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date) as running_customer_total,
    RANK() OVER (ORDER BY order_amount DESC) as global_order_rank
FROM orders
ORDER BY customer_id, order_date;

-- EXERCISE 9: Window with ROWS clause - Sliding window analysis
SELECT 
    trade_date,
    closing_price,
    AVG(closing_price) OVER (ORDER BY trade_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) as ma_5day,
    AVG(closing_price) OVER (ORDER BY trade_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) as ma_20day
FROM stock_prices
ORDER BY trade_date;

-- EXERCISE 10: Complex Analysis - Customer lifetime value with trend
WITH customer_orders AS (
    SELECT 
        customer_id,
        order_date,
        total_amount,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) as order_num,
        SUM(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) as lifetime_value_to_date
    FROM orders
)
SELECT 
    customer_id,
    order_num,
    order_date,
    total_amount,
    lifetime_value_to_date,
    LAG(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) as prev_order_amount,
    CASE 
        WHEN total_amount > LAG(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) THEN 'Increased'
        WHEN total_amount < LAG(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) THEN 'Decreased'
        ELSE 'Same'
    END as trend
FROM customer_orders
WHERE order_num <= 5; -- First 5 orders


-- ============================================
-- Day 6: ADVANCED QUERIES
-- ============================================

-- EXERCISE 1: UNION - Combine two datasets with different structures
SELECT customer_id, 'Premium' as membership_type FROM premium_members
UNION
SELECT customer_id, 'Standard' as membership_type FROM standard_members;

-- EXERCISE 2: UNION ALL - Keep duplicates
SELECT product_id, sales_amount, 'Q1' as quarter FROM q1_sales
UNION ALL
SELECT product_id, sales_amount, 'Q2' as quarter FROM q2_sales;

-- EXERCISE 3: Complex JOIN with multiple conditions
SELECT 
    o.order_id,
    c.customer_name,
    p.product_name,
    od.quantity,
    od.unit_price,
    (od.quantity * od.unit_price) as line_total
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_details od ON o.order_id = od.order_id
INNER JOIN products p ON od.product_id = p.product_id
WHERE o.order_date >= '2024-01-01'
ORDER BY o.order_id;

-- EXERCISE 4: Case When - Segment analysis
SELECT 
    customer_id,
    total_spent,
    CASE 
        WHEN total_spent >= 10000 THEN 'VIP'
        WHEN total_spent >= 5000 THEN 'Gold'
        WHEN total_spent >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END as customer_segment
FROM (
    SELECT customer_id, SUM(total_amount) as total_spent
    FROM orders
    GROUP BY customer_id
) customer_spending;

-- EXERCISE 5: Self-Join - Find products with similar pricing
SELECT 
    p1.product_id,
    p1.product_name,
    p2.product_id,
    p2.product_name,
    p1.price
FROM products p1
INNER JOIN products p2 ON p1.price = p2.price AND p1.product_id < p2.product_id
ORDER BY p1.price DESC;

-- EXERCISE 6: LEFT JOIN to find missing relationships
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) as order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(o.order_id) = 0; -- Customers with no orders

-- EXERCISE 7: Pivoting data - Product sales by month
SELECT 
    product_id,
    SUM(CASE WHEN MONTH(order_date) = 1 THEN quantity ELSE 0 END) as jan_sales,
    SUM(CASE WHEN MONTH(order_date) = 2 THEN quantity ELSE 0 END) as feb_sales,
    SUM(CASE WHEN MONTH(order_date) = 3 THEN quantity ELSE 0 END) as mar_sales,
    SUM(CASE WHEN MONTH(order_date) = 4 THEN quantity ELSE 0 END) as apr_sales
FROM orders
WHERE YEAR(order_date) = 2024
GROUP BY product_id;

-- EXERCISE 8: String operations - Customer data cleaning
SELECT 
    UPPER(customer_name) as name_upper,
    LOWER(email) as email_lower,
    LENGTH(phone) as phone_length,
    SUBSTRING(phone, 1, 3) as area_code
FROM customers
WHERE phone IS NOT NULL;

-- EXERCISE 9: Date functions - Customer anniversary and retention
SELECT 
    customer_id,
    first_order_date,
    DATEDIFF(CURRENT_DATE, first_order_date) as days_as_customer,
    YEAR(CURRENT_DATE) - YEAR(first_order_date) as years_as_customer,
    CASE 
        WHEN DATEDIFF(CURRENT_DATE, last_order_date) <= 30 THEN 'Active'
        WHEN DATEDIFF(CURRENT_DATE, last_order_date) <= 90 THEN 'At Risk'
        ELSE 'Inactive'
    END as customer_status
FROM (
    SELECT 
        customer_id,
        MIN(order_date) as first_order_date,
        MAX(order_date) as last_order_date
    FROM orders
    GROUP BY customer_id
) customer_dates;

-- EXERCISE 10: Complex Real-World Scenario - Product Performance Report
WITH product_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        COUNT(DISTINCT od.order_id) as order_count,
        SUM(od.quantity) as total_units_sold,
        SUM(od.quantity * od.unit_price) as total_revenue,
        AVG(od.quantity * od.unit_price) as avg_order_value
    FROM products p
    LEFT JOIN order_details od ON p.product_id = od.product_id
    LEFT JOIN orders o ON od.order_id = o.order_id
    WHERE o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY p.product_id, p.product_name, p.category
)
SELECT 
    product_id,
    product_name,
    category,
    order_count,
    total_units_sold,
    total_revenue,
    RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) as revenue_rank_in_category,
    total_revenue / SUM(total_revenue) OVER (PARTITION BY category) * 100 as pct_of_category_revenue
FROM product_sales
ORDER BY category, revenue_rank_in_category;


-- ============================================
-- Day 7: PERFORMANCE TUNING & OPTIMIZATION
-- ============================================

-- EXERCISE 1: Index impact - Before and after
-- SLOW: Full table scan
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 100;

-- FAST: With index on customer_id
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 100;

-- EXERCISE 2: Query optimization - Reduce unnecessary columns
-- INEFFICIENT
SELECT * FROM customers c
WHERE c.customer_id IN (
    SELECT o.customer_id FROM orders o
);

-- OPTIMIZED
SELECT c.customer_id
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id
);

-- EXERCISE 3: Avoid N+1 queries - Use JOINs
-- INEFFICIENT (multiple queries)
-- SELECT * FROM customers WHERE country = 'USA'
-- Then for each customer, query: SELECT * FROM orders WHERE customer_id = ?

-- OPTIMIZED (single query)
SELECT c.customer_id, c.customer_name, COUNT(o.order_id) as order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.country = 'USA'
GROUP BY c.customer_id, c.customer_name;

-- EXERCISE 4: Use aggregates early - Reduce data size
-- INEFFICIENT
SELECT o.customer_id, o.order_id, o.total_amount
FROM orders o
INNER JOIN (
    SELECT * FROM order_details
) od ON o.order_id = od.order_id
WHERE o.total_amount > 1000;

-- OPTIMIZED
SELECT DISTINCT o.customer_id, o.order_id, o.total_amount
FROM orders o
WHERE o.total_amount > 1000;

-- EXERCISE 5: Selective JOINs - Only necessary tables
-- INEFFICIENT
SELECT c.customer_name, COUNT(*) as purchases
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_details od ON o.order_id = od.order_id
LEFT JOIN products p ON od.product_id = p.product_id
WHERE o.order_date >= '2024-01-01'
GROUP BY c.customer_id, c.customer_name;

-- OPTIMIZED
SELECT c.customer_name, COUNT(DISTINCT o.order_id) as purchases
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= '2024-01-01'
GROUP BY c.customer_id, c.customer_name;

-- EXERCISE 6: Composite indexes - Multiple column filtering
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);

-- Now this query uses the index efficiently
SELECT * FROM orders 
WHERE customer_id = 100 AND order_date >= '2024-01-01';

-- EXERCISE 7: Covering indexes - Include columns to avoid table lookup
CREATE INDEX idx_orders_covering ON orders(customer_id, order_date) INCLUDE (total_amount);

-- EXERCISE 8: Partition strategy - Large table optimization
-- Monthly partitioned table (if using PostgreSQL or other DBMS)
-- SELECT * FROM orders WHERE order_date >= '2024-01-01' AND order_date < '2024-02-01'
-- Only scans January partition

-- EXERCISE 9: Materialized view - Pre-compute expensive queries
CREATE MATERIALIZED VIEW customer_summary_mv AS
SELECT 
    customer_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent,
    AVG(total_amount) as avg_order_value,
    MAX(order_date) as last_order_date
FROM orders
GROUP BY customer_id;

-- Use the materialized view (much faster)
SELECT * FROM customer_summary_mv WHERE order_count > 5;

-- EXERCISE 10: Query optimization checklist - Real-world example
-- SLOW QUERY (multiple issues)
SELECT *
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_details od ON o.order_id = od.order_id
LEFT JOIN products p ON od.product_id = p.product_id
WHERE YEAR(o.order_date) = 2024;

-- OPTIMIZED QUERY
CREATE INDEX idx_orders_date ON orders(order_date);

SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT o.order_id) as order_count,
    SUM(od.quantity) as total_items
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_details od ON o.order_id = od.order_id
WHERE o.order_date >= '2024-01-01' AND o.order_date < '2025-01-01'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.order_id) > 0;
