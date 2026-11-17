# A. BigQuery sandbox setup (no credit card)

Use your personal Google account (jadhaidar76@gmail.com). Menu labels move around a little; the names below are the current ones.

1. Open https://console.cloud.google.com/bigquery and sign in.
2. If you see a welcome or terms dialog, tick the box, choose your country, click **Agree and continue**.
3. If asked to create a project, click **Create project**, name it `ga4-ecommerce-portfolio`, leave Organization blank, click **Create**. Otherwise: top bar project picker → **New project** → same name → **Create** → select it in the picker.
4. Do **not** click "Activate", "Upgrade" or "Free trial" anywhere. Without billing you stay in the **sandbox**; look for the **Sandbox** label at the top. Nothing asks for a card.
5. Open the public dataset: in the left **Explorer** panel click **+ Add** → **Star a project by name** → type `bigquery-public-data` → **Star**.
6. In Explorer expand `bigquery-public-data` → `ga4_obfuscated_sample_ecommerce` → click `events_(92)` (the date-sharded tables). Open the **Schema** tab to see the nested fields (`event_params`, `items`, `ecommerce`).
7. Click **Compose a new query** (or **+** for a new tab). Paste `sql/01_daily_kpis.sql`.
8. Before running, check the top-right of the editor: it says "This query will process X MB when run". That is the dry-run estimate; it must be far below the sandbox limit of 1 TB per month.
9. Click **Run**. Results appear at the bottom.
10. Check the location: **More** → **Query settings** → **Data location** must be **Auto-select** or **US** (the public dataset is in the US).
11. Run `sql/07_dashboard_summary.sql` once. It creates dataset `ga4_portfolio` and six `dash_*` tables in your project.

Sandbox limits to remember: 10 GB storage, 1 TB queries per month, and tables expire after 60 days (re-run script 07 to rebuild).
