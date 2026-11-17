-- =====================================================================
-- 02_traffic_source_medium.sql
-- Purpose : Acquisition performance by traffic source / medium:
--           users, purchasers, transactions, revenue, conversion rate.
-- Grain   : one row per source + medium
-- Source  : bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
-- Notes   : * In this sample dataset traffic_source.* is the USER-LEVEL
--             first-touch acquisition source (not per-session attribution).
--           * User conversion rate = purchasers / users.
--           * Some values are obfuscated as '<Other>' in the public sample.
-- =====================================================================
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
