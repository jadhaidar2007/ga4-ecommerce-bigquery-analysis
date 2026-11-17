# H. Final checklist (finish today, Nov 17; deadline Nov 20)

## BigQuery
- [ ] Open BigQuery in the sandbox, project `ga4-ecommerce-portfolio` created
- [ ] `bigquery-public-data` starred; `events_(92)` visible
- [ ] Run `sql/01` to `sql/06` one by one; each returns rows and shows a small "will process" estimate
- [ ] Run `sql/07_dashboard_summary.sql`; six `dash_*` tables exist in `ga4_portfolio`
- [ ] Sanity check: funnel steps decrease; daily rows = 92; revenue is positive
- [ ] If any query errors, copy the exact error message and fix that field name (schema tab) before moving on

## Dashboard
- [ ] Connect 6 data sources and rename them
- [ ] Set `country` to Geo → Country; `event_date` to Date
- [ ] Build pages 1–4 as in `docs/02_looker_studio_build.md`
- [ ] Apply theme: background, colours, Roboto, header band, date control
- [ ] Share as "Anyone with the link: Viewer"; test in a private window
- [ ] Take 4 screenshots in View mode → `screenshots/01_overview.png`, `02_funnel_acquisition.png`, `03_products.png`, `04_audience.png`

## Numbers and write-up
- [ ] Copy real numbers into README "Key findings" (replace every `[X]`)
- [ ] Write 3–5 recommendations using `docs/03_insights_template.md`
- [ ] Paste the dashboard link into the README
- [ ] Remove any placeholder you did not fill (search for `[` in README)

## GitHub
- [ ] Create repo and push (commands below)
- [ ] Open the repo on github.com and check that images render
- [ ] Pin the repo on your GitHub profile
- [ ] Add repo description and topics: `bigquery`, `ga4`, `looker-studio`, `sql`, `analytics`

## Application
- [ ] Add the 3 CV bullets to your CV (fill the `[N]`)
- [ ] Paste the project description into the application form
- [ ] Add repo link and dashboard link to the form/CV
- [ ] Submit before Nov 20

## Git commands

```bash
cd ga4-ecommerce-bigquery-analysis
git init -b main
git add .
git commit -m "Add GA4 BigQuery analysis: SQL, dashboard guide, docs"

# Option A: GitHub CLI
gh repo create jadhaidar2007/ga4-ecommerce-bigquery-analysis --public --source=. --remote=origin --push

# Option B: create an empty repo on github.com first, then
git remote add origin https://github.com/jadhaidar2007/ga4-ecommerce-bigquery-analysis.git
git push -u origin main
```

After adding screenshots and numbers:

```bash
git add screenshots README.md
git commit -m "Add dashboard screenshots and findings"
git push
```
