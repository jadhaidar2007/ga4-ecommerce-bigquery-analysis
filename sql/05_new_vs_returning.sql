-- =====================================================================
-- 05_new_vs_returning.sql
-- Purpose : Compare new vs returning users by month: users, sessions,
--           purchases, revenue, conversion rate, revenue per user.
-- Grain   : one row per month + user_type
-- Source  : bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
-- Method  : A session is 'New' when its ga_session_number = 1 (the user's
--           first ever session) and 'Returning' otherwise. A user can appear
--           in both groups if they started and came back inside the window.
-- =====================================================================
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
