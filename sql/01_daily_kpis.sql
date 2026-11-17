-- =====================================================================
-- 01_daily_kpis.sql
-- Purpose : Daily users, new users, sessions, purchases and revenue.
-- Grain   : one row per calendar day (92 days, 2020-11-01 .. 2021-01-31)
-- Source  : bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
-- Notes   : * _TABLE_SUFFIX filter limits the scan to the sample window.
--           * Session = user_pseudo_id + ga_session_id (GA4 definition).
--           * Purchases = count of 'purchase' events; revenue is in USD.
--           * Feeds the KPI scorecards and the trend line in Looker Studio.
-- =====================================================================
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
