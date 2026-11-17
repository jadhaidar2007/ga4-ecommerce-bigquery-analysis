-- =====================================================================
-- 06_device_country.sql
-- Purpose : Device category and country breakdown of users, sessions,
--           purchases, revenue and conversion.
-- Grain   : one row per device_category + country
-- Source  : bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
-- Notes   : * Country is the dimension for the Looker Studio geo chart.
--           * Users are distinct within each device + country row, so rows
--             should not be summed to get a global user count (use query 01).
-- =====================================================================
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
