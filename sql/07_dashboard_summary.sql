-- =====================================================================
-- 07_dashboard_summary.sql
-- Purpose : ONE script that builds every table behind the Looker Studio
--           dashboard. Run it once; then connect Looker Studio to the
--           small ga4_portfolio.dash_* tables (cheap + fast) instead of
--           the raw events_* tables.
-- Output  : dataset ga4_portfolio (US) with 6 tables:
--           dash_daily, dash_source_medium, dash_funnel, dash_top_products,
--           dash_new_vs_returning, dash_device_country
-- How     : paste the whole file into the BigQuery editor and press Run.
--           The dataset is created in your currently selected project.
-- Sandbox : tables expire after 60 days; re-run this script to refresh
--           them, and export dashboard PDF/screenshots before then.
-- Note    : the SELECT bodies below are identical to sql/01 ... sql/06.
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS ga4_portfolio OPTIONS (location = 'US');

-- ---- dash_daily (from 01_daily_kpis.sql) ----
CREATE OR REPLACE TABLE ga4_portfolio.dash_daily AS
WITH base AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    event_name,
    IFNULL(ecommerce.purchase_revenue, 0) AS purchase_revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT
  event_date,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT IF(event_name = 'first_visit', user_pseudo_id, NULL)) AS new_users,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))) AS sessions,
  COUNTIF(event_name = 'purchase') AS purchases,
  ROUND(SUM(IF(event_name = 'purchase', purchase_revenue, 0)), 2) AS revenue_usd,
  ROUND(SAFE_DIVIDE(
    COUNT(DISTINCT IF(event_name = 'purchase', CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING)), NULL)),
    COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING)))
  ) * 100, 2) AS session_conversion_rate_pct
FROM base
GROUP BY event_date
ORDER BY event_date;

-- ---- dash_source_medium (from 02_traffic_source_medium.sql) ----
CREATE OR REPLACE TABLE ga4_portfolio.dash_source_medium AS
WITH events AS (
  SELECT
    user_pseudo_id,
    IFNULL(traffic_source.source, '(not set)') AS source,
    IFNULL(traffic_source.medium, '(not set)') AS medium,
    event_name,
    IFNULL(ecommerce.purchase_revenue, 0) AS purchase_revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT
  source,
  medium,
  CONCAT(source, ' / ', medium) AS source_medium,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)) AS purchasers,
  COUNTIF(event_name = 'purchase') AS transactions,
  ROUND(SUM(IF(event_name = 'purchase', purchase_revenue, 0)), 2) AS revenue_usd,
  ROUND(SAFE_DIVIDE(
    COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)),
    COUNT(DISTINCT user_pseudo_id)
  ) * 100, 2) AS user_conversion_rate_pct,
  ROUND(SAFE_DIVIDE(
    SUM(IF(event_name = 'purchase', purchase_revenue, 0)),
    COUNT(DISTINCT user_pseudo_id)
  ), 2) AS revenue_per_user_usd
FROM events
GROUP BY source, medium
ORDER BY revenue_usd DESC, users DESC;

-- ---- dash_funnel (from 03_funnel.sql) ----
CREATE OR REPLACE TABLE ga4_portfolio.dash_funnel AS
WITH session_flags AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    COUNTIF(event_name = 'view_item') > 0 AS has_view_item,
    COUNTIF(event_name = 'add_to_cart') > 0 AS has_add_to_cart,
    COUNTIF(event_name = 'begin_checkout') > 0 AS has_begin_checkout,
    COUNTIF(event_name = 'purchase') > 0 AS has_purchase
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
  GROUP BY user_pseudo_id, ga_session_id
  HAVING ga_session_id IS NOT NULL
),
funnel AS (
  SELECT
    COUNTIF(has_view_item) AS s1_view_item,
    COUNTIF(has_view_item AND has_add_to_cart) AS s2_add_to_cart,
    COUNTIF(has_view_item AND has_add_to_cart AND has_begin_checkout) AS s3_begin_checkout,
    COUNTIF(has_view_item AND has_add_to_cart AND has_begin_checkout AND has_purchase) AS s4_purchase
  FROM session_flags
),
steps AS (
  SELECT step_order, step_name, sessions
  FROM funnel,
  UNNEST([
    STRUCT(1 AS step_order, 'view_item' AS step_name, s1_view_item AS sessions),
    STRUCT(2, 'add_to_cart', s2_add_to_cart),
    STRUCT(3, 'begin_checkout', s3_begin_checkout),
    STRUCT(4, 'purchase', s4_purchase)
  ])
)
SELECT
  step_order,
  step_name,
  sessions,
  ROUND(SAFE_DIVIDE(sessions, LAG(sessions) OVER (ORDER BY step_order)) * 100, 2) AS pct_of_previous_step,
  ROUND(100 - SAFE_DIVIDE(sessions, LAG(sessions) OVER (ORDER BY step_order)) * 100, 2) AS dropoff_pct,
  ROUND(SAFE_DIVIDE(sessions, FIRST_VALUE(sessions) OVER (ORDER BY step_order)) * 100, 2) AS pct_of_first_step
FROM steps
ORDER BY step_order;

-- ---- dash_top_products (from 04_top_products.sql) ----
CREATE OR REPLACE TABLE ga4_portfolio.dash_top_products AS
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

-- ---- dash_new_vs_returning (from 05_new_vs_returning.sql) ----
CREATE OR REPLACE TABLE ga4_portfolio.dash_new_vs_returning AS
WITH session_level AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    MAX((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_number')) AS ga_session_number,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS session_date,
    COUNTIF(event_name = 'purchase') AS purchases,
    SUM(IF(event_name = 'purchase', IFNULL(ecommerce.purchase_revenue, 0), 0)) AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  GROUP BY user_pseudo_id, ga_session_id
  HAVING ga_session_id IS NOT NULL
)
SELECT
  DATE_TRUNC(session_date, MONTH) AS month,
  IF(ga_session_number = 1, 'New', 'Returning') AS user_type,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(*) AS sessions,
  SUM(purchases) AS purchases,
  ROUND(SUM(revenue), 2) AS revenue_usd,
  ROUND(SAFE_DIVIDE(COUNTIF(purchases > 0), COUNT(*)) * 100, 2) AS session_conversion_rate_pct,
  ROUND(SAFE_DIVIDE(SUM(revenue), COUNT(DISTINCT user_pseudo_id)), 2) AS revenue_per_user_usd
FROM session_level
GROUP BY month, user_type
ORDER BY month, user_type;

-- ---- dash_device_country (from 06_device_country.sql) ----
CREATE OR REPLACE TABLE ga4_portfolio.dash_device_country AS
WITH events AS (
  SELECT
    user_pseudo_id,
    IFNULL(device.category, '(not set)') AS device_category,
    IFNULL(geo.country, '(not set)') AS country,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS ga_session_id,
    event_name,
    IFNULL(ecommerce.purchase_revenue, 0) AS purchase_revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT
  device_category,
  country,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))) AS sessions,
  COUNTIF(event_name = 'purchase') AS purchases,
  ROUND(SUM(IF(event_name = 'purchase', purchase_revenue, 0)), 2) AS revenue_usd,
  ROUND(SAFE_DIVIDE(
    COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)),
    COUNT(DISTINCT user_pseudo_id)
  ) * 100, 2) AS user_conversion_rate_pct,
  ROUND(SAFE_DIVIDE(
    SUM(IF(event_name = 'purchase', purchase_revenue, 0)),
    COUNT(DISTINCT user_pseudo_id)
  ), 2) AS revenue_per_user_usd
FROM events
GROUP BY device_category, country
ORDER BY revenue_usd DESC, users DESC;
