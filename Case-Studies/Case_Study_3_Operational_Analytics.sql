-- ============================================
-- CASE STUDY 3: OPERATIONAL ANALYTICS
-- Amazon Data Analyst Prep — Days 18-20
-- ============================================
-- Scenario: The operations team needs SQL-driven
-- analytics to optimize warehouse efficiency,
-- inventory levels, fulfillment SLAs, and costs.
--
-- Dataset tables:
--   orders(order_id, customer_id, order_date, ship_date, delivery_date,
--          total_amount, status, warehouse_id, region)
--   order_items(order_id, product_id, quantity, unit_price)
--   products(product_id, product_name, category, cost_price, reorder_level)
--   warehouses(warehouse_id, warehouse_name, location, capacity)
--   inventory(product_id, warehouse_id, stock_qty, last_replenished_date)

-- ============================================
-- QUESTION 1: Order fulfillment SLA compliance
-- ============================================
-- SLA target: delivered within 5 business days
SELECT
    warehouse_id,
    COUNT(*)                                                        AS total_orders,
    COUNT(CASE WHEN delivery_date - order_date <= 5 THEN 1 END)    AS on_time_orders,
    COUNT(CASE WHEN delivery_date - order_date > 5 THEN 1 END)     AS late_orders,
    ROUND(
          COUNT(CASE WHEN delivery_date - order_date <= 5 THEN 1 END) * 100.0 / COUNT(*), 1
      )                                                               AS on_time_rate_pct,
    ROUND(AVG(delivery_date - order_date), 1)                      AS avg_fulfillment_days,
    MAX(delivery_date - order_date)                                 AS max_fulfillment_days
FROM orders
WHERE status = 'Delivered'
  AND order_date >= '2024-01-01'
GROUP BY warehouse_id
ORDER BY on_time_rate_pct DESC;

-- ============================================
-- QUESTION 2: Warehouse throughput by month
-- ============================================
SELECT
    w.warehouse_name,
    DATE_TRUNC('month', o.order_date)       AS month,
    COUNT(DISTINCT o.order_id)              AS orders_processed,
    SUM(oi.quantity)                        AS units_shipped,
    ROUND(SUM(o.total_amount), 2)           AS revenue_processed,
    ROUND(
          COUNT(DISTINCT o.order_id) * 1.0 / w.capacity, 4
      )                                       AS capacity_utilization
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN warehouses  w  ON o.warehouse_id = w.warehouse_id
WHERE o.status = 'Delivered'
GROUP BY w.warehouse_name, DATE_TRUNC('month', o.order_date), w.capacity
ORDER BY w.warehouse_name, month;

-- ============================================
-- QUESTION 3: Inventory stock vs reorder threshold
-- ============================================
SELECT
    p.product_id,
    p.product_name,
    p.category,
    w.warehouse_name,
    i.stock_qty,
    p.reorder_level,
    i.stock_qty - p.reorder_level           AS stock_above_reorder,
    CASE
        WHEN i.stock_qty = 0                THEN 'OUT OF STOCK'
        WHEN i.stock_qty < p.reorder_level  THEN 'REORDER NEEDED'
        WHEN i.stock_qty < p.reorder_level * 1.25 THEN 'LOW STOCK'
        ELSE                                     'ADEQUATE'
    END AS stock_status,
    i.last_replenished_date,
    CURRENT_DATE - i.last_replenished_date  AS days_since_replenished
FROM inventory i
INNER JOIN products    p ON i.product_id   = p.product_id
INNER JOIN warehouses  w ON i.warehouse_id = w.warehouse_id
ORDER BY stock_status, days_since_replenished DESC;

-- ============================================
-- QUESTION 4: Inventory turnover rate by product
-- ============================================
-- Turnover = Units Sold / Average Inventory
WITH units_sold AS (
      SELECT
          oi.product_id,
          SUM(oi.quantity) AS total_units_sold
      FROM order_items oi
      INNER JOIN orders o ON oi.order_id = o.order_id
      WHERE o.status = 'Delivered'
        AND o.order_date >= CURRENT_DATE - INTERVAL '365 days'
      GROUP BY oi.product_id
  ),
avg_inventory AS (
      SELECT product_id, AVG(stock_qty) AS avg_stock
      FROM inventory
      GROUP BY product_id
  )
SELECT
    p.product_name,
    p.category,
    COALESCE(us.total_units_sold, 0)                AS units_sold_12mo,
    ROUND(ai.avg_stock, 0)                          AS avg_inventory,
    ROUND(
          COALESCE(us.total_units_sold, 0) /
          NULLIF(ai.avg_stock, 0), 2
      )                                               AS inventory_turnover_ratio,
    CASE
        WHEN COALESCE(us.total_units_sold, 0) / NULLIF(ai.avg_stock, 0) > 12 THEN 'Fast Moving'
        WHEN COALESCE(us.total_units_sold, 0) / NULLIF(ai.avg_stock, 0) > 4  THEN 'Normal'
        ELSE 'Slow Moving'
    END AS velocity_class
FROM products p
LEFT JOIN units_sold   us ON p.product_id = us.product_id
INNER JOIN avg_inventory ai ON p.product_id = ai.product_id
ORDER BY inventory_turnover_ratio DESC;

-- ============================================
-- QUESTION 5: Cost efficiency by warehouse
-- ============================================
WITH warehouse_stats AS (
      SELECT
          o.warehouse_id,
          COUNT(DISTINCT o.order_id)              AS total_orders,
          SUM(oi.quantity)                        AS total_units,
          ROUND(SUM(o.total_amount), 2)           AS total_revenue,
          ROUND(SUM(oi.quantity * p.cost_price), 2) AS total_cogs
      FROM orders o
      INNER JOIN order_items oi ON o.order_id   = oi.order_id
      INNER JOIN products    p  ON oi.product_id = p.product_id
      WHERE o.status = 'Delivered'
      GROUP BY o.warehouse_id
  )
SELECT
    ws.warehouse_id,
    w.warehouse_name,
    ws.total_orders,
    ws.total_units,
    ws.total_revenue,
    ws.total_cogs,
    ROUND(ws.total_revenue - ws.total_cogs, 2)          AS gross_profit,
    ROUND((ws.total_revenue - ws.total_cogs) /
            NULLIF(ws.total_revenue, 0) * 100, 1)         AS margin_pct,
    ROUND(ws.total_revenue / NULLIF(ws.total_orders, 0), 2) AS revenue_per_order
FROM warehouse_stats ws
INNER JOIN warehouses w ON ws.warehouse_id = w.warehouse_id
ORDER BY margin_pct DESC;

-- ============================================
-- QUESTION 6: Shipping delay root cause analysis
-- ============================================
SELECT
    warehouse_id,
    region,
    EXTRACT(MONTH FROM order_date)              AS order_month,
    COUNT(*)                                    AS total_orders,
    COUNT(CASE WHEN delivery_date - ship_date > 3 THEN 1 END) AS shipping_delays,
    ROUND(
          COUNT(CASE WHEN delivery_date - ship_date > 3 THEN 1 END) * 100.0 / COUNT(*), 1
      )                                           AS delay_rate_pct,
    ROUND(AVG(delivery_date - ship_date), 1)    AS avg_transit_days,
    ROUND(AVG(order_date - ship_date) * -1, 1)  AS avg_processing_days
FROM orders
WHERE status = 'Delivered'
GROUP BY warehouse_id, region, EXTRACT(MONTH FROM order_date)
HAVING COUNT(CASE WHEN delivery_date - ship_date > 3 THEN 1 END) > 0
ORDER BY delay_rate_pct DESC;
