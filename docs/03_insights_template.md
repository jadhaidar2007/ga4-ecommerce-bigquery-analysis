# F. Turning results into 3–5 recommendations

## Template (one block per recommendation)

**Observation:** What the data shows, with the exact number and where you saw it (dashboard page / query file).
**Why it matters:** The business impact in one sentence (revenue, cost, conversion).
**Recommendation:** One specific action, with an owner-type and a measurable goal.
**How to test it:** The experiment or metric that proves it worked.
**Caveat:** What the sample cannot tell you.

## Example phrasing (replace brackets with your verified numbers)

### 1. Funnel (query 03)
**Observation:** [X%] of sessions that added to cart did not start checkout, the largest drop in the funnel.
**Why it matters:** Each recovered cart is revenue the store already paid to acquire.
**Recommendation:** Add a persistent cart summary and a visible shipping/returns message on the cart page, aiming to lift add-to-cart → checkout by [Y] percentage points.
**How to test it:** A/B test the cart page; track `pct_of_previous_step` for the begin_checkout step.
**Caveat:** The funnel is session-based and does not enforce event order.

### 2. Acquisition (query 02)
**Observation:** [SOURCE / MEDIUM] produced [X%] of revenue but [SOURCE / MEDIUM] converted at [X%], more than [N]x higher.
**Why it matters:** Budget on low-converting sources is inefficient.
**Recommendation:** Shift a share of effort from [LOW SOURCE] to [HIGH SOURCE] and track revenue per user for 4 weeks.
**How to test it:** Compare `revenue_per_user_usd` per source before/after.
**Caveat:** Source is first-touch user-level in this dataset.

### 3. Products (query 04)
**Observation:** The top 10 products account for [X%] of revenue, led by [PRODUCT].
**Why it matters:** Revenue is concentrated, so stock-outs or weak pages on a few items hit hard.
**Recommendation:** Feature the top 3 products on the home page and in cart cross-sells; keep inventory buffers on them.
**How to test it:** Track add-to-cart rate for featured items versus a control group.
**Caveat:** One holiday season of data.

### 4. Audience (queries 05 and 06)
**Observation:** Returning users converted at [X%] versus [X%] for new users; [DEVICE] converted at [X%] versus [X%] on [DEVICE].
**Why it matters:** It shows whether the gap is a loyalty problem or a device-experience problem.
**Recommendation:** If mobile lags, prioritise mobile checkout simplification; if new users lag, add first-purchase incentives and email capture.
**How to test it:** Split the funnel by device and run the checkout test on the weaker device first.
**Caveat:** Device split uses the device recorded on each event.

### 5. Geography (query 06)
**Observation:** [COUNTRY] drove [X%] of revenue; [COUNTRY] had many users but a low conversion rate of [X%].
**Why it matters:** High traffic with low conversion points to a localisation, pricing or shipping barrier.
**Recommendation:** Investigate currency, shipping cost and language for [COUNTRY] before spending on more acquisition there.
**How to test it:** Compare funnel steps for that country against the top country.
**Caveat:** Small countries have small samples; require a minimum number of sessions.

## Rules for writing yours

- Use only numbers you can read off your dashboard.
- One observation → one action → one metric.
- Start recommendations with a verb; avoid "should consider".
- Always include a caveat; it shows analytical maturity.
