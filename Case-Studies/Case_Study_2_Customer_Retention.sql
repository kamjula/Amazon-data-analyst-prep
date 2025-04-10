-- ============================================
-- CASE STUDY 2: CUSTOMER RETENTION ANALYSIS
-- Amazon Data Analyst Prep — Days 15-17
-- ============================================
-- Scenario: The growth team wants to understand
-- customer retention and churn patterns to improve
-- repeat purchase rates and reduce churn.
--
-- Key metrics to deliver:
--   1. Monthly cohort retention rates
--   2. Churn identification (inactive customers)
--   3. Repeat vs one-time buyer breakdown
--   4. Average time between purchases
--   5. At-risk customer alerts

-- ============================================
-- QUESTION 1: Monthly cohort retention table
-- ============================================
WITH cohort_base AS (
      SELECT
          customer_id,
          DATE_TRUNC('month', MIN(order_date))    AS cohort_month,
          DATE_TRUNC('month', order_date)         AS order_month
      FROM orders
      WHERE status = 'Completed'
      GROUP BY customer_id, DATE_TRUNC('month', order_date)
  ),
cohort_size AS (
      SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_customers
      FROM cohort_base
      GROUP BY cohort_month
  ),
cohort_data AS (
      SELECT
          cb.cohort_month,
          cb.order_month,
          COUNT(DISTINCT cb.customer_id) AS retained_customers,
          EXTRACT(MONTH FROM AGE(cb.order_month, cb.cohort_month)) AS months_since_acquisition
      FROM cohort_base cb
      GROUP BY cb.cohort_month, cb.order_month
  )
SELECT
    cd.cohort_month,
    cd.months_since_acquisition,
    cd.retained_customers,
    cs.cohort_customers,
    ROUND(cd.retained_customers * 100.0 / cs.cohort_customers, 1) AS retention_rate_pct
FROM cohort_data cd
JOIN cohort_size cs ON cd.cohort_month = cs.cohort_month
ORDER BY cd.cohort_month, cd.months_since_acquisition;

-- ============================================
-- QUESTION 2: Churn identification
-- ============================================
-- Define churn: no purchase in the last 90 days
WITH last_purchase AS (
      SELECT
          c.customer_id,
          c.customer_name,
          c.segment,
          c.country,
          MAX(o.order_date)                           AS last_order_date,
          COUNT(DISTINCT o.order_id)                  AS total_orders,
          ROUND(SUM(o.total_amount), 2)               AS lifetime_value
      FROM customers c
      LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'Completed'
      GROUP BY c.customer_id, c.customer_name, c.segment, c.country
  )
SELECT
    customer_id,
    customer_name,
    segment,
    country,
    last_order_date,
    total_orders,
    lifetime_value,
    CURRENT_DATE - last_order_date      AS days_since_last_order,
    CASE
        WHEN last_order_date IS NULL                                    THEN 'Never Ordered'
        WHEN CURRENT_DATE - last_order_date > 180                       THEN 'Churned (180+ days)'
        WHEN CURRENT_DATE - last_order_date BETWEEN 91 AND 180          THEN 'At Risk (91-180 days)'
        WHEN CURRENT_DATE - last_order_date BETWEEN 31 AND 90           THEN 'Cooling Off (31-90 days)'
        ELSE                                                             'Active (0-30 days)'
    END AS churn_status
FROM last_purchase
ORDER BY days_since_last_order DESC NULLS FIRST;

-- ============================================
-- QUESTION 3: Repeat vs one-time buyers
-- ============================================
WITH purchase_counts AS (
      SELECT
          customer_id,
          COUNT(DISTINCT order_id) AS order_count
      FROM orders
      WHERE status = 'Completed'
      GROUP BY customer_id
  )
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-Time Buyer'
        WHEN order_count BETWEEN 2 AND 3 THEN 'Occasional (2-3x)'
        WHEN order_count BETWEEN 4 AND 7 THEN 'Regular (4-7x)'
        ELSE 'Loyal (8+x)'
    END AS buyer_type,
    COUNT(*)                AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers
FROM purchase_counts
GROUP BY buyer_type
ORDER BY customer_count DESC;

-- ============================================
-- QUESTION 4: Avg days between purchases
-- ============================================
WITH order_gaps AS (
      SELECT
          customer_id,
          order_date,
          LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date
      FROM orders
      WHERE status = 'Completed'
  ),
gaps_calculated AS (
      SELECT
          customer_id,
          order_date - prev_order_date AS days_between_orders
      FROM order_gaps
      WHERE prev_order_date IS NOT NULL
  )
SELECT
    customer_id,
    COUNT(*)                            AS repeat_purchases,
    ROUND(AVG(days_between_orders), 1)  AS avg_days_between_orders,
    MIN(days_between_orders)            AS min_days,
    MAX(days_between_orders)            AS max_days
FROM gaps_calculated
GROUP BY customer_id
HAVING COUNT(*) >= 2
ORDER BY avg_days_between_orders ASC
LIMIT 20;

-- ============================================
-- QUESTION 5: Win-back target list
-- ============================================
-- High-value customers who churned (90-180 days inactive)
WITH customer_metrics AS (
      SELECT
          c.customer_id,
          c.customer_name,
          c.segment,
          c.country,
          COUNT(DISTINCT o.order_id)      AS total_orders,
          ROUND(SUM(o.total_amount), 2)   AS lifetime_value,
          MAX(o.order_date)               AS last_order_date,
          CURRENT_DATE - MAX(o.order_date) AS days_inactive
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
    total_orders,
    lifetime_value,
    last_order_date,
    days_inactive,
    'Win-Back Campaign Target' AS action
FROM customer_metrics
WHERE days_inactive BETWEEN 90 AND 180
  AND lifetime_value > 500
ORDER BY lifetime_value DESC;

-- ============================================
-- QUESTION 6: Month-over-month new vs returning customers
-- ============================================
WITH first_orders AS (
      SELECT customer_id, MIN(order_date) AS first_order_date
      FROM orders WHERE status = 'Completed'
      GROUP BY customer_id
  ),
monthly_orders AS (
      SELECT
          DATE_TRUNC('month', o.order_date)   AS month,
          o.customer_id,
          CASE WHEN DATE_TRUNC('month', o.order_date) = DATE_TRUNC('month', fo.first_order_date)
               THEN 'New' ELSE 'Returning'
          END AS customer_type
      FROM orders o
      INNER JOIN first_orders fo ON o.customer_id = fo.customer_id
      WHERE o.status = 'Completed'
  )
SELECT
    month,
    COUNT(DISTINCT CASE WHEN customer_type = 'New'       THEN customer_id END) AS new_customers,
    COUNT(DISTINCT CASE WHEN customer_type = 'Returning' THEN customer_id END) AS returning_customers,
    COUNT(DISTINCT customer_id) AS total_active_customers
FROM monthly_orders
GROUP BY month
ORDER BY month;
