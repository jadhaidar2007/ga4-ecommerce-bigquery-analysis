-- =====================================================================
-- 04_top_products.sql
-- Purpose : Top 10 products by revenue, with quantity sold and quantity rank.
-- Grain   : one row per product (item_id + item_name), top 10 by revenue
-- Source  : bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
-- Notes   : * Built from the items array of 'purchase' events (UNNEST).
--           * Item revenue falls back to price * quantity when item_revenue
--             is NULL, so rows are not silently dropped.
--           * qty_rank shows where the product ranks by units sold; change the
--             ORDER BY / filter to rank by quantity instead.
-- =====================================================================
WITH purchased_items AS (
  SELECT
    item.item_id AS item_id,
    item.item_name AS item_name,
    IFNULL(item.item_category, '(not set)') AS item_category,
    IFNULL(item.quantity, 0) AS quantity,
    COALESCE(item.item_revenue, item.price * item.quantity, 0) AS item_revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(items) AS item
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
),
product_totals AS (
  SELECT
    item_id,
    item_name,
    item_category,
    COUNT(*) AS purchase_lines,
    SUM(quantity) AS units_sold,
    ROUND(SUM(item_revenue), 2) AS revenue_usd
  FROM purchased_items
  GROUP BY item_id, item_name, item_category
),
ranked AS (
  SELECT
    *,
    RANK() OVER (ORDER BY revenue_usd DESC) AS revenue_rank,
    RANK() OVER (ORDER BY units_sold DESC) AS qty_rank,
    ROUND(SAFE_DIVIDE(revenue_usd, SUM(revenue_usd) OVER ()) * 100, 2) AS pct_of_total_revenue
  FROM product_totals
)
SELECT
  revenue_rank,
  item_id,
  item_name,
  item_category,
  units_sold,
  qty_rank,
  revenue_usd,
  pct_of_total_revenue
FROM ranked
WHERE revenue_rank <= 10
ORDER BY revenue_rank;
