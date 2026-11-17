# C. Looker Studio dashboard build guide

Report name: **GA4 Ecommerce Performance (Nov 2020 – Jan 2021)**

## 1. Connect the data (6 sources)

1. Go to https://lookerstudio.google.com → **Create** → **Report**.
2. Choose connector **BigQuery** → **My Projects** → `ga4-ecommerce-portfolio` → dataset `ga4_portfolio`.
3. Pick `dash_daily` → **Add** → **Add to report**.
4. Repeat via **Add data** → **BigQuery** for the other five tables:

| Table | Rename data source to |
|---|---|
| `dash_daily` | `ga4_daily` |
| `dash_source_medium` | `ga4_source_medium` |
| `dash_funnel` | `ga4_funnel` |
| `dash_top_products` | `ga4_top_products` |
| `dash_new_vs_returning` | `ga4_new_vs_returning` |
| `dash_device_country` | `ga4_device_country` |

(Resource → **Manage added data sources** → Edit → click the name at top to rename.)

5. In `ga4_device_country` set field **country** type to **Geo → Country** (edit the data source, click the type icon next to `country`).
6. In `ga4_daily` confirm `event_date` is type **Date**; in `ga4_new_vs_returning` confirm `month` is **Date (Year Month)**.
7. Make the conversion rate fields type **Number**, not percent (values are already ×100). Format them in each chart as `0.00"%"` or add "%" in the title.

## 2. Theme and conventions

- **Theme and layout → Customize**: canvas size **1280 × 900** (Custom), background `#F8F9FA`.
- Colours: primary blue `#1A73E8`, teal `#12B5CB`, amber (highlight) `#F9AB00`, red (drop-off / warning) `#D93025`, text dark `#202124`, text grey `#5F6368`, cards white `#FFFFFF` with 1 px `#DADCE0` border, 8 px radius.
- Font: **Roboto**. Page title 24 pt bold; chart titles 14 pt bold; labels 11 pt.
- Always: currency fields formatted as USD with no decimals on scorecards; percentages with 1–2 decimals; thousands separators on.
- Naming: pages `1 Overview`, `2 Funnel & Acquisition`, `3 Products`, `4 Audience`. Every chart has a title in the form `<Metric> by <Dimension>` and a subtitle with the definition if non-obvious.
- Header band on each page: a rectangle (full width, 60 px high, `#1A73E8`) with white text `GA4 Ecommerce Performance | <page name>` and a small caption `Source: Google Merchandise Store GA4 sample (BigQuery public dataset)`.
- Add a **Date range control** top-right on each page (data source `ga4_daily` on page 1; on other pages the control just filters that page's source if it has a date field). Default range: **Custom 1 Nov 2020 – 31 Jan 2021**.
- Grid: 24 px outer margin, 16 px gap between cards. Align edges; same card height per row.

## 3. Pages

### Page 1: Overview (data source `ga4_daily`)

Layout (1280 px wide):
- **Row 1 (y=80, height 110)**: five scorecards, each ~232 px wide.
  1. **Users**: metric `SUM(users)`. Note: sum of daily distinct users overcounts people who return on several days, so title it **Daily Active Users (sum)** or use *Average* and name it **Avg Daily Users**. Prefer **Avg Daily Users**.
  2. **Sessions**: `SUM(sessions)`.
  3. **Purchases**: `SUM(purchases)`.
  4. **Revenue**: `SUM(revenue_usd)`, USD format.
  5. **Conversion rate**: calculated field `SUM(purchases) / SUM(sessions)` named `Purchase rate (purchases ÷ sessions)`, percentage format.
  - Enable **Comparison date range → Previous period** only if you narrow the range; otherwise leave off.
- **Row 2 (y=210, height 300, full width)**: **Time series chart** "Daily Revenue and Sessions". Dimension `event_date`; metrics `revenue_usd` (left axis, blue) and `sessions` (right axis, teal, line). Smoothing off, show data labels off, show legend top.
- **Row 3 (y=530, height 300)**: left half **Time series** "Daily Purchases" (`purchases`, amber); right half **Bar chart** "Revenue by Month" with calculated dimension `event_date` → Year Month, metric `revenue_usd`.
- Filters: date range control only.

### Page 2: Funnel & Acquisition (`ga4_funnel`, `ga4_source_medium`)

- **Funnel chart (use a horizontal bar chart)**, left, 600 × 330: title "Ecommerce Funnel (sessions)". Source `ga4_funnel`; dimension `step_name`; metric `sessions`; sort by `step_order` ascending; bar colour blue; data labels on.
- **Table**, right of it, 600 × 330: title "Step-to-step Drop-off". Dimensions `step_order`, `step_name`; metrics `sessions`, `pct_of_previous_step`, `dropoff_pct`, `pct_of_first_step`. Sort by `step_order`. Conditional formatting: `dropoff_pct` red `#D93025` text when > the highest of the others (use rule "greater than [your biggest acceptable drop]").
- **Table with bars**, full width, 1232 × 330: title "Source / Medium Performance". Source `ga4_source_medium`. Dimension `source_medium`; metrics `users`, `purchasers`, `transactions`, `revenue_usd`, `user_conversion_rate_pct`, `revenue_per_user_usd`. Sort by `revenue_usd` descending. Rows per page 10. Turn on **Show bars** (compact numbers) on `revenue_usd`.
- Filter control: drop-down on `medium` (source `ga4_source_medium`), placed above the table.

### Page 3: Products (`ga4_top_products`)

- **Bar chart (horizontal)**, left 700 × 420: "Top 10 Products by Revenue". Dimension `item_name`; metric `revenue_usd`; sort by `revenue_usd` descending; limit 10; blue bars; data labels on.
- **Bar chart (horizontal)**, right 500 × 420: "Units Sold (same products)". Dimension `item_name`; metric `units_sold`; same sort as left; teal.
- **Table**, bottom full width: "Product Detail". Columns `revenue_rank`, `item_name`, `item_category`, `units_sold`, `qty_rank`, `revenue_usd`, `pct_of_total_revenue`.
- Scorecard (top right): "Top-10 share of revenue" = `SUM(pct_of_total_revenue)`.

### Page 4: Audience (`ga4_device_country`, `ga4_new_vs_returning`)

- **Geo chart (filled map)**, left 700 × 400: "Revenue by Country". Dimension `country`; metric `revenue_usd`; map colour gradient white → blue `#1A73E8`; zoom world.
- **Donut chart**, top right 500 × 190: "Sessions by Device". Dimension `device_category`; metric `sessions`; colours blue/teal/amber.
- **Table**, below donut, 500 × 190: "Device Conversion". Dimension `device_category`; metrics `users`, `purchases`, `user_conversion_rate_pct`, `revenue_per_user_usd`. Source `ga4_device_country` (this table is at device × country grain; Looker will sum rows, so for `users` use SUM and label the column "Users (sum across countries)", or drop `users` and keep `purchases` and `revenue_usd`).
- **Stacked column chart**, bottom left 600 × 300: "Sessions: New vs Returning by Month". Source `ga4_new_vs_returning`; dimension `month`; breakdown dimension `user_type`; metric `sessions`; colours New = teal, Returning = blue.
- **Table**, bottom right 600 × 300: "New vs Returning KPIs". Dimension `user_type`; metrics `sessions`, `purchases`, `revenue_usd`, `session_conversion_rate_pct`, `revenue_per_user_usd`.
- Filter control: drop-down on `country` (source `ga4_device_country`) and on `device_category`.

## 4. Publish and share

1. Click **Share** → **Manage access** → **Anyone with the link** → **Viewer** → Done.
2. Copy the link into `README.md` (`[PASTE LOOKER STUDIO LINK HERE]`).
3. Use **View** mode for screenshots (Edit mode shows grid and handles).
4. Optional: **File → Download as PDF** for the application.

## 5. Quality checks before you screenshot

- Scorecard Sessions equals the sum of the daily series in the table view.
- Funnel counts never increase from one step to the next.
- No chart shows "No data" or the default title "Chart".
- Every title is specific, every axis has readable units, colours follow the palette, and nothing overlaps.
