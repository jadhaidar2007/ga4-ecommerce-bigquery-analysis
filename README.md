# GA4 Ecommerce Analytics: BigQuery + Looker Studio

> End-to-end analysis of 92 days of Google Merchandise Store GA4 event data: SQL in BigQuery, a four-page Looker Studio dashboard, and business recommendations.

**Live dashboard:** [PASTE LOOKER STUDIO LINK HERE]

![Dashboard overview](screenshots/01_overview.png)

## Business problem

An online store wants to know where its revenue comes from and where it leaks. Specifically:

1. How are traffic, sessions, purchases and revenue trending day to day?
2. Which acquisition channels bring users who actually buy?
3. Where in the funnel (`view_item` → `add_to_cart` → `begin_checkout` → `purchase`) do most sessions drop off?
4. Which products drive revenue, and how do new and returning users differ?
5. Do device and country change conversion?

## Dataset

[`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`](https://developers.google.com/analytics/bigquery/web-ecommerce-demo-dataset): obfuscated GA4 export from the Google Merchandise Store, **1 Nov 2020 to 31 Jan 2021** (92 daily tables). Event-level rows with nested `event_params` and `items` arrays.

Known limits of the sample (stated up front so results are read correctly):
- `traffic_source.*` is the user's first-touch source, not per-session attribution.
- Some fields are obfuscated (`<Other>`, `(not set)`).
- It is a sample from one store, so findings illustrate method, not a general benchmark.

## Tools

BigQuery (sandbox, no billing) · BigQuery Standard SQL · Looker Studio · Git/GitHub

## Method

1. Queried the public dataset with date-sharded wildcard tables and a `_TABLE_SUFFIX` filter to keep every query inside sandbox limits.
2. Flattened nested data with `UNNEST` (event parameters for `ga_session_id` / `ga_session_number`, and `items` for product revenue).
3. Defined a session as `user_pseudo_id` + `ga_session_id`, and built a session-based funnel where a session counts at a step only if it reached all earlier steps.
4. Materialised six small summary tables (`sql/07_dashboard_summary.sql`) so Looker Studio reads kilobytes instead of rescanning raw events.
5. Built the dashboard on those tables and wrote recommendations from the results.

| File | What it answers |
|---|---|
| [`sql/01_daily_kpis.sql`](sql/01_daily_kpis.sql) | Daily users, new users, sessions, purchases, revenue |
| [`sql/02_traffic_source_medium.sql`](sql/02_traffic_source_medium.sql) | Source / medium performance and conversion |
| [`sql/03_funnel.sql`](sql/03_funnel.sql) | Four-step funnel with step-to-step drop-off |
| [`sql/04_top_products.sql`](sql/04_top_products.sql) | Top 10 products by revenue and units |
| [`sql/05_new_vs_returning.sql`](sql/05_new_vs_returning.sql) | New vs returning users by month |
| [`sql/06_device_country.sql`](sql/06_device_country.sql) | Device and country breakdown |
| [`sql/07_dashboard_summary.sql`](sql/07_dashboard_summary.sql) | Builds all dashboard tables in one run |

## Key findings

> Replace every bracket with your own numbers from the dashboard. Do not publish a finding you did not verify.

- **Overall:** [X] users generated [X] sessions, [X] purchases and $[X] revenue between 1 Nov 2020 and 31 Jan 2021 (session conversion rate [X%]).
- **Funnel:** [X%] of product-view sessions reached add-to-cart; the largest drop-off was between [STEP A] and [STEP B] ([X%] lost).
- **Acquisition:** [SOURCE / MEDIUM] brought the most revenue ($[X]); [SOURCE / MEDIUM] converted best at [X%] user conversion.
- **Products:** the top 10 products made up [X%] of revenue; [PRODUCT NAME] ranked #1 with $[X].
- **Audience:** returning users converted at [X%] vs [X%] for new users; [DEVICE] converted at [X%] vs [X%] for [DEVICE].
- **Geography:** [COUNTRY] led revenue with $[X] ([X%] of total).

## Dashboard

Four pages: **Overview**, **Funnel & Acquisition**, **Products**, **Audience**. Build guide: [`docs/02_looker_studio_build.md`](docs/02_looker_studio_build.md).

## Screenshots

| Overview | Funnel & Acquisition |
|---|---|
| ![Overview](screenshots/01_overview.png) | ![Funnel](screenshots/02_funnel_acquisition.png) |

| Products | Audience |
|---|---|
| ![Products](screenshots/03_products.png) | ![Audience](screenshots/04_audience.png) |

## Skills demonstrated

- BigQuery Standard SQL: CTEs, window functions (`LAG`, `FIRST_VALUE`, `RANK`), `UNNEST` of nested/repeated fields, wildcard tables with `_TABLE_SUFFIX`, scripting (`CREATE SCHEMA`, `CREATE OR REPLACE TABLE`)
- GA4 event data model: sessions, events, parameters, ecommerce items
- Cost-aware querying in the BigQuery sandbox
- Funnel and cohort-style analysis, KPI definition
- Dashboard design in Looker Studio and turning data into recommendations

## Reproduce it

1. Enable the BigQuery sandbox: [`docs/01_bigquery_setup.md`](docs/01_bigquery_setup.md)
2. Run `sql/07_dashboard_summary.sql` in the BigQuery editor (creates dataset `ga4_portfolio`).
3. Follow [`docs/02_looker_studio_build.md`](docs/02_looker_studio_build.md).

Sandbox tables expire after 60 days; re-run step 2 to refresh them.

## Next steps

- Add per-session attribution using `collected_traffic_source` on newer GA4 exports.
- Add a product-category view and a basket-size analysis.
- Add a cohort retention view (week-of-first-visit vs return weeks).
- Schedule `07_dashboard_summary.sql` as a BigQuery scheduled query.
- Test funnel drop-off by device and recommend an A/B test for the weakest step.

## Author

Jad Haidar · Industrial Engineering & Management (Data Science minor), Constructor University · [GitHub](https://github.com/jadhaidar2007)
