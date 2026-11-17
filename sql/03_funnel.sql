-- =====================================================================
-- 03_funnel.sql
-- Purpose : Ecommerce funnel  view_item -> add_to_cart -> begin_checkout
--           -> purchase, with step-to-step drop-off percentages.
-- Grain   : one row per funnel step (4 rows)
-- Source  : bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*
-- Method  : Session-based. A session counts at step N only if it also
--           reached every earlier step (strict gating). Event ORDER inside
--           the session is not enforced; this keeps the funnel monotonic.
-- Columns : pct_of_previous_step = step-to-step conversion
--           dropoff_pct          = 100 - pct_of_previous_step
--           pct_of_first_step    = overall conversion from view_item
-- =====================================================================
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
