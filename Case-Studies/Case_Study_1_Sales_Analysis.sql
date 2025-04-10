-- ============================================
-- CASE STUDY 1: QUARTERLY SALES ANALYSIS
-- Amazon Data Analyst Prep — Days 12-14
-- ============================================
-- Scenario: You are a Data Analyst at Amazon.
-- Management wants a full quarterly sales performance
-- report to identify top products, revenue trends,
-- and growth opportunities across regions.
--
-- Dataset tables:
--   orders(order_id, customer_id, order_date, total_amount, status, region)
--   order_items(order_id, product_id, quantity, unit_price, discount)
--   products(product_id, product_name, category, cost_price)
--   customers(customer_id, customer_name, country, segment)

-- ============================================
-- QUESTION 1: Quarterly revenue summary for 2024
-- ============================================
SELECT
    EXTRACT(YEAR  FROM o.order_date)    AS year,
    EXTRACT(QUARTER FROM o.order_date)  AS quarter,
    COUNT(DISTINCT o.order_id)          AS total_orders,
    COUNT(DISTINCT o.customer_id)       AS unique_customers,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))), 2) AS net_revenue,
    ROUND(AVG(o.total_amount), 2)       AS avg_order_value
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
  AND EXTRACT(YEAR FROM o.order_date) = 2024
GROUP BY year, quarter
ORDER BY year, quarter;

-- ============================================
-- QUESTION 2: Top 10 products by revenue in 2024
-- ============================================
WITH product_revenue AS (
      SELECT
          p.product_id,
          p.product_name,
          p.category,
          SUM(oi.quantity)                                                AS units_sold,
          ROUND(SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))), 2) AS net_revenue,
          ROUND(SUM(oi.quantity * (oi.unit_price - p.cost_price)), 2)    AS gross_profit
      FROM products p
      INNER JOIN order_items oi ON p.product_id = oi.product_id
      INNER JOIN orders      o  ON oi.order_id  = o.order_id
      WHERE o.status = 'Completed'
        AND o.order_date BETWEEN '2024-01-01' AND '2024-12-31'
      GROUP BY p.product_id, p.product_name, p.category
  )
SELECT
    product_name,
    category,
    units_sold,
    net_revenue,
    gross_profit,
    ROUND(gross_profit / NULLIF(net_revenue, 0) * 100, 1) AS margin_pct,
    RANK() OVER (ORDER BY net_revenue DESC)                AS revenue_rank
FROM product_revenue
ORDER BY revenue_rank
LIMIT 10;

-- ============================================
-- QUESTION 3: Month-over-month revenue growth
-- ============================================
WITH monthly_revenue AS (
      SELECT
          DATE_TRUNC('month', o.order_date)  AS month,
          ROUND(SUM(o.total_amount), 2)      AS revenue
      FROM orders o
      WHERE o.status = 'Completed'
        AND o.order_date BETWEEN '2024-01-01' AND '2024-12-31'
      GROUP BY DATE_TRUNC('month', o.order_date)
  )
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month)  AS prev_month_revenue,
    ROUND(
          (revenue - LAG(revenue) OVER (ORDER BY month)) /
          NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 1
      ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;

-- ============================================
-- QUESTION 4: Revenue by region and product category
-- ============================================
SELECT
    o.region,
    p.category,
    COUNT(DISTINCT o.order_id)                                          AS orders,
    SUM(oi.quantity)                                                    AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)                         AS gross_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))), 2) AS net_revenue
FROM orders o
INNER JOIN order_items oi ON o.order_id  = oi.order_id
INNER JOIN products    p  ON oi.product_id = p.product_id
WHERE o.status = 'Completed'
GROUP BY o.region, p.category
ORDER BY o.region, net_revenue DESC;

-- ============================================
-- QUESTION 5: Customer segmentation by spend level
-- ============================================
WITH customer_spend AS (
      SELECT
          c.customer_id,
          c.customer_name,
          c.segment,
          c.country,
          COUNT(DISTINCT o.order_id)     AS order_count,
          ROUND(SUM(o.total_amount), 2)  AS total_spent,
          MAX(o.order_date)              AS last_order_date
      FROM customers c
      INNER JOIN orders o ON c.customer_id = o.customer_id
      WHERE o.status = 'Completed'
      GROUP BY c.customer_id, c.customer_name, c.segment, c.country
  )
SELECT
    customer_id,
    customer_name,
    segment,
    country,
    order_count,
    total_spent,
    last_order_date,
    CASE
        WHEN total_spent >= 10000 THEN 'Platinum'
        WHEN total_spent >= 5000  THEN 'Gold'
        WHEN total_spent >= 1000  THEN 'Silver'
        ELSE                           'Bronze'
    END AS spend_tier,
    RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
FROM customer_spend
ORDER BY spend_rank
LIMIT 20;

-- ============================================
-- QUESTION 6: Discount impact analysis
-- ============================================
SELECT
    CASE
        WHEN oi.discount = 0        THEN 'No Discount'
        WHEN oi.discount <= 0.10    THEN '1-10%'
        WHEN oi.discount <= 0.20    THEN '11-20%'
        WHEN oi.discount <= 0.30    THEN '21-30%'
        ELSE                             '30%+'
    END AS discount_bucket,
    COUNT(DISTINCT o.order_id)                                          AS orders,
    ROUND(AVG(o.total_amount), 2)                                       AS avg_order_value,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)                         AS gross_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))), 2) AS net_revenue,
    ROUND(
          (1 - SUM(oi.quantity * oi.unit_price * (1 - COALESCE(oi.discount, 0))) /
           NULLIF(SUM(oi.quantity * oi.unit_price), 0)) * 100, 1
      ) AS avg_effective_discount_pct
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY discount_bucket
ORDER BY discount_bucket;

-- ============================================
-- QUESTION 7: Weekly sales trend with 4-week rolling avg
-- ============================================
WITH weekly_sales AS (
      SELECT
          DATE_TRUNC('week', order_date)  AS week_start,
          ROUND(SUM(total_amount), 2)     AS weekly_revenue
      FROM orders
      WHERE status = 'Completed'
      GROUP BY DATE_TRUNC('week', order_date)
  )
SELECT
    week_start,
    weekly_revenue,
    ROUND(AVG(weekly_revenue) OVER (
          ORDER BY week_start
          ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
      ), 2) AS rolling_4wk_avg
FROM weekly_sales
ORDER BY week_start;

-- ============================================
-- QUESTION 8: Full executive summary (single query)
-- ============================================
SELECT
    'Total Revenue'     AS metric, ROUND(SUM(total_amount), 2)::TEXT AS value FROM orders WHERE status = 'Completed'
UNION ALL
SELECT 'Total Orders',        COUNT(*)::TEXT        FROM orders WHERE status = 'Completed'
UNION ALL
SELECT 'Unique Customers',    COUNT(DISTINCT customer_id)::TEXT FROM orders WHERE status = 'Completed'
UNION ALL
SELECT 'Avg Order Value',     ROUND(AVG(total_amount), 2)::TEXT FROM orders WHERE status = 'Completed'
UNION ALL
SELECT 'Cancellation Rate %', ROUND(
      SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
  )::TEXT FROM orders;
