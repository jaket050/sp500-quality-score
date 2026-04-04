# Not All Blue Chips Are Equal: S&P 500 Multi-Factor Quality Score

**An end-to-end SQL and Tableau project that unifies five fundamental financial metrics — P/E, EBITDA, Dividend Yield, Price/Sales, Price/Book — into a single composite Quality Score to rank S&P 500 companies, reveal sector-level trends, and support investment decision-making.**

---

## Dashboard Preview
**[View Live Interactive Dashboard](https://public.tableau.com/app/profile/jake.tangonan/viz/SP500qualityScore/ExecutiveView)**

### Page 1 — Executive View: S&P 500 Quality Score Analysis
![Executive Dashboard](visuals/Screenshot%202026-02-03%20123325.png)

> Controls: Pick a Metric dropdown, N Companies slider, N Sectors slider, Click for Drilldown button
> Visuals: Top 7 / Bottom 7 Sectors by Quality Score (side-by-side bar charts), Top 7 / Bottom 7 Companies by Quality Score, Variability Across Top Sectors box plot

### Page 2 — Drilldown: Contribution Metrics & Company Detail
![Drilldown Dashboard](visuals/Screenshot%202026-02-03%20123556.png)

> Controls: Symbol, Name, Sector filters, Back to Executive View button
> Visuals: Contribution Metrics bar chart (% of total signal per metric), Company Information table sorted by Avg Quality Score

---

## Project Overview

Investment research teams need a consistent, repeatable way to compare company quality across the S&P 500. Individual metrics like P/E or Dividend Yield tell part of the story — but no single ratio captures the full picture. This project builds a composite Quality Score that normalizes five fundamentals onto a common 0–100 scale and ranks every company overall and within its sector.

> **Business Question:** How can we standardize multiple fundamental financial metrics into a single Quality Score that ranks S&P 500 companies, reveals sector-level trends, and supports both investment decision-making and technical equity research?

---

## Stakeholders

| Role | Need |
|---|---|
| Research Analysts / Equity Analysts | Ranked stock lists and sector insights showing which metrics drive quality differences |
| Portfolio Managers / Investment Strategists | A consistent, comparable view of company quality across the S&P 500 to guide allocation decisions |

---

## Tools & Stack

![BigQuery](https://img.shields.io/badge/GCP-BigQuery-4285F4?logo=google-cloud&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Advanced-336791?logo=postgresql&logoColor=white)
![Tableau](https://img.shields.io/badge/Tableau-Dashboard-E97627?logo=tableau&logoColor=white)

| Tool | Role in Project |
|---|---|
| **BigQuery** | Cloud data warehouse; all tables, views, and SQL analysis |
| **SQL** | EDA, profiling, cleaning, normalization, Quality Score calculation, ranking |
| **Tableau** | Final dashboards for sector benchmarking and company-level drill down |

---

## Dataset

| Table | Description |
|---|---|
| `sp500data` | Raw S&P 500 company financials |
| `sp500data_clean` | Initial cleaned table (sense-checked, null-handled) |
| `sp500data_clean_step1` | View: whitespace trimmed, sector names standardized, nulls filled |
| `sp500data_clean_step2` | View: sector consolidation via CASE/LIKE mapping, IQR outlier removal |
| `sp500data_norm` | View: all five metrics normalized to 0–100 scale |
| `sp500data_qualityScore` | View: composite Quality Score + overall and sector rankings |
| `sp500data_qualityScore_sector` | Table: sector-level aggregates (avg score, company count) |

---

## KPI & Field Dictionary

| Field | Domain Name | Type | Definition |
|---|---|---|---|
| `symbol` | Ticker Symbol | STRING | Primary company identifier (e.g. AAPL) |
| `name` | Company Name | STRING | Official company name |
| `sector` | Sector | STRING | Industry group for grouping and filtering |
| `price` | Stock Price | FLOAT | Current share price |
| `priceToEarnings` | P/E Ratio | FLOAT | How expensive the stock is relative to earnings; null when earnings are negative |
| `dividendYield` | Dividend Yield | FLOAT | % of stock price paid as dividends annually |
| `EarningPerShare` | EPS | FLOAT | Profit per share; can be negative |
| `WeekLow52` | 52-Week Low | FLOAT | Lowest price in the past year |
| `WeekHigh52` | 52-Week High | FLOAT | Highest price in the past year |
| `marketCap` | Market Cap | INTEGER | Total company value (price × shares) |
| `ebitda` | EBITDA | INTEGER | Operating performance before interest, taxes, depreciation |
| `PriceToSales` | P/S Ratio | FLOAT | Stock price vs. revenue; useful for low-profit companies |
| `priceToBook` | P/B Ratio | FLOAT | Stock price vs. net assets |
| `SecFillings` | SEC Filings | STRING | Link to official regulatory filings |

---

## SQL Analysis — Step by Step

### Step 1 — Sense Checks

```sql
-- Row and symbol counts
SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT symbol) AS ticker_count
FROM `sp500dataAnalysis.sp500data`;

-- Null check across all key fields
SELECT
  SUM(CASE WHEN symbol IS NULL THEN 1 ELSE 0 END) AS null_symbol,
  SUM(CASE WHEN priceToEarnings IS NULL THEN 1 ELSE 0 END) AS null_pe,
  SUM(CASE WHEN dividendYield IS NULL THEN 1 ELSE 0 END) AS null_div_yield,
  SUM(CASE WHEN ebitda IS NULL THEN 1 ELSE 0 END) AS null_ebitda,
  SUM(CASE WHEN PriceToSales IS NULL THEN 1 ELSE 0 END) AS null_ps,
  SUM(CASE WHEN priceToBook IS NULL THEN 1 ELSE 0 END) AS null_pb
FROM `sp500dataAnalysis.sp500data`;

-- Value ranges
SELECT
  MIN(price) AS min_price, MAX(price) AS max_price,
  MIN(priceToEarnings) AS min_pe, MAX(priceToEarnings) AS max_pe,
  MIN(dividendYield) AS min_div, MAX(dividendYield) AS max_div
FROM `sp500dataAnalysis.sp500data`;
```

---

### Step 2 — Logical Tests

```sql
-- Price should fall between 52-week low and high
SELECT
  COUNTIF(WeekLow52 IS NOT NULL AND WeekHigh52 IS NOT NULL
    AND (price < WeekLow52 OR price > WeekHigh52)) AS price_outside_52w,
  COUNTIF(WeekLow52 IS NOT NULL AND WeekHigh52 IS NOT NULL
    AND WeekLow52 > WeekHigh52) AS inverted_52w_range
FROM `sp500dataAnalysis.sp500data`;

-- P/E cross-check: price / EPS should approximately equal reported P/E
SELECT
  COUNT(*) AS rows_checked,
  COUNTIF(ABS((price / NULLIF(EarningPerShare, 0)) - priceToEarnings) > 2)
    AS pe_mismatch_gt2
FROM `sp500dataAnalysis.sp500data`;
```

---

### Step 3 — Exploring Data

```sql
-- Total rows, unique symbols, distinct sectors
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT symbol) AS unique_symbols,
  COUNT(DISTINCT sector) AS sectors
FROM `sp500dataAnalysis.sp500data_clean`;

-- Sector distribution with percentage share
SELECT
  sector,
  COUNT(*) AS n,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM `sp500dataAnalysis.sp500data_clean`
GROUP BY sector
ORDER BY n DESC;
```

---

### Step 4 — Profiling Data

```sql
-- Missing value count per metric using UNION ALL
SELECT 'priceToEarnings' AS metric, COUNTIF(priceToEarnings IS NULL) AS missing
FROM `sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'dividendYield', COUNTIF(dividendYield IS NULL)
FROM `sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'ebitda', COUNTIF(ebitda IS NULL)
FROM `sp500dataAnalysis.sp500data_clean`;

-- IQR-based outlier bounds for P/E and P/S
WITH bounds AS (
  SELECT metric, Q1, Q3,
    Q1 - 1.5 * (Q3 - Q1) AS lower_bound,
    Q3 + 1.5 * (Q3 - Q1) AS upper_bound
  FROM (
    SELECT 'priceToEarnings' AS metric,
      APPROX_QUANTILES(priceToEarnings, 4)[OFFSET(1)] AS Q1,
      APPROX_QUANTILES(priceToEarnings, 4)[OFFSET(3)] AS Q3
    FROM `sp500dataAnalysis.sp500data_clean`
    UNION ALL
    SELECT 'PriceToSales',
      APPROX_QUANTILES(PriceToSales, 4)[OFFSET(1)],
      APPROX_QUANTILES(PriceToSales, 4)[OFFSET(3)]
    FROM `sp500dataAnalysis.sp500data_clean`
  )
)
SELECT metric, lower_bound, upper_bound FROM bounds;
-- P/E upper bound: 69.185 | P/S upper bound: 12.78

-- Sector-level null concentration
SELECT sector, COUNT(*) AS n,
  COUNTIF(priceToEarnings IS NULL) AS null_pe,
  COUNTIF(dividendYield IS NULL) AS null_div,
  COUNTIF(ebitda IS NULL) AS null_ebitda
FROM `sp500dataAnalysis.sp500data_clean`
GROUP BY sector
ORDER BY n DESC;
```

---

### Step 5 — Cleaning Data

```sql
-- Step 1: Trim whitespace, standardize sector casing, fill nulls with 0
CREATE OR REPLACE VIEW `sp500dataAnalysis.sp500data_clean_step1` AS
SELECT
  symbol, name,
  INITCAP(TRIM(sector)) AS sector,
  price, priceToEarnings,
  IFNULL(dividendYield, 0) AS dividendYield,
  EarningPerShare, WeekLow52, WeekHigh52, marketCap,
  IFNULL(ebitda, 0) AS ebitda,
  PriceToSales, priceToBook
FROM `sp500dataAnalysis.sp500data_clean`;

-- Step 2: Consolidate 127 raw sectors → 11 standard sectors using CASE/LIKE
-- Then drop outliers above IQR upper bounds (P/E > 69.185, P/S > 12.78)
CREATE OR REPLACE VIEW `sp500dataAnalysis.sp500data_clean_step2` AS
WITH mapped AS (
  SELECT symbol, name,
    CASE
      WHEN UPPER(sector) LIKE '%REIT%' OR UPPER(sector) LIKE '%REAL ESTATE%'
        THEN 'Real Estate'
      WHEN UPPER(sector) LIKE '%BANK%' OR UPPER(sector) LIKE '%FINAN%'
        THEN 'Financials'
      WHEN UPPER(sector) LIKE '%SOFTWARE%' OR UPPER(sector) LIKE '%TECH%'
        THEN 'Information Technology'
      WHEN UPPER(sector) LIKE '%HEALTH%' OR UPPER(sector) LIKE '%PHARM%'
        THEN 'Health Care'
      WHEN UPPER(sector) LIKE '%ENERGY%' OR UPPER(sector) LIKE '%OIL%'
        THEN 'Energy'
      -- ... (11 total sector mappings)
      ELSE sector
    END AS sector_std,
    price, priceToEarnings, dividendYield, EarningPerShare,
    WeekLow52, WeekHigh52, marketCap, ebitda, PriceToSales, priceToBook
  FROM `sp500dataAnalysis.sp500data_clean_step1`
)
SELECT * FROM mapped
WHERE PriceToSales >= 0 AND PriceToSales <= 12.78
  AND priceToEarnings >= 0 AND priceToEarnings <= 69.185;
```

---

### Step 6 — Normalization (Shaping Data)

All five metrics normalized to 0–100. Valuation ratios (P/E, P/S, P/B) are **inverted** so that lower = better (higher score).

```sql
CREATE OR REPLACE VIEW `sp500dataAnalysis.sp500data_norm` AS
SELECT
  symbol, name, sector, price, marketCap,
  priceToEarnings, dividendYield, ebitda, PriceToSales, priceToBook,

  -- P/E: inverted — lower P/E = higher score
  ROUND(100 * (MAX(priceToEarnings) OVER() - priceToEarnings)
    / NULLIF(MAX(priceToEarnings) OVER() - MIN(priceToEarnings) OVER(), 0), 2)
    AS pe_norm,

  -- EBITDA: higher = better
  ROUND(100 * (ebitda - MIN(ebitda) OVER())
    / NULLIF(MAX(ebitda) OVER() - MIN(ebitda) OVER(), 0), 2)
    AS ebitda_norm,

  -- Dividend Yield: higher = better
  ROUND(100 * (dividendYield - MIN(dividendYield) OVER())
    / NULLIF(MAX(dividendYield) OVER() - MIN(dividendYield) OVER(), 0), 2)
    AS divy_norm,

  -- P/S: inverted — lower P/S = higher score
  ROUND(100 * (MAX(PriceToSales) OVER() - PriceToSales)
    / NULLIF(MAX(PriceToSales) OVER() - MIN(PriceToSales) OVER(), 0), 2)
    AS ps_norm,

  -- P/B: inverted — lower P/B = higher score
  ROUND(100 * (MAX(priceToBook) OVER() - priceToBook)
    / NULLIF(MAX(priceToBook) OVER() - MIN(priceToBook) OVER(), 0), 2)
    AS pb_norm

FROM `sp500dataAnalysis.sp500data_clean_step2`;
```

---

### Step 7 — Quality Score & Rankings

```sql
CREATE OR REPLACE VIEW `sp500dataAnalysis.sp500data_qualityScore` AS
SELECT
  symbol, name, sector, price, marketCap,
  priceToEarnings, pe_norm, ebitda, ebitda_norm,
  dividendYield, divy_norm, PriceToSales, ps_norm, priceToBook, pb_norm,

  -- Composite Quality Score: equally weighted average of 5 normalized metrics
  ROUND((pe_norm + ebitda_norm + divy_norm + ps_norm + pb_norm) / 5, 2)
    AS quality_score,

  -- Overall rank across all companies
  ROW_NUMBER() OVER (ORDER BY (pe_norm + ebitda_norm + divy_norm + ps_norm + pb_norm) DESC)
    AS rank_overall,

  -- Rank within each sector
  DENSE_RANK() OVER (PARTITION BY sector
    ORDER BY (pe_norm + ebitda_norm + ps_norm + pb_norm + divy_norm) DESC)
    AS rank_in_sector

FROM `sp500dataAnalysis.sp500data_norm`;
```

---

### Step 8 — Analysis

```sql
-- Top 10 by Quality Score
SELECT symbol, name, sector, quality_score,
  pe_norm, ebitda_norm, divy_norm, ps_norm, pb_norm
FROM `sp500dataAnalysis.sp500data_qualityScore`
ORDER BY quality_score DESC LIMIT 10;

-- Bottom 10 by Quality Score
SELECT symbol, name, sector, quality_score
FROM `sp500dataAnalysis.sp500data_qualityScore`
ORDER BY quality_score ASC LIMIT 10;

-- Sector leaders (#1 ranked company per sector)
SELECT sector, symbol, name, quality_score, rank_in_sector
FROM `sp500dataAnalysis.sp500data_qualityScore`
WHERE rank_in_sector = 1
ORDER BY quality_score DESC;

-- Sector aggregates
SELECT sector,
  ROUND(AVG(quality_score), 2) AS avg_quality_score,
  MIN(quality_score) AS min_quality_score,
  MAX(quality_score) AS max_quality_score,
  COUNT(*) AS n_symbols
FROM `sp500dataAnalysis.sp500data_qualityScore`
GROUP BY sector
ORDER BY avg_quality_score DESC;

-- Metric correlation with Quality Score (what drives the score?)
SELECT
  CORR(quality_score, pe_norm) AS corr_pe,
  CORR(quality_score, ebitda_norm) AS corr_ebitda,
  CORR(quality_score, divy_norm) AS corr_divy,
  CORR(quality_score, ps_norm) AS corr_ps,
  CORR(quality_score, pb_norm) AS corr_pb
FROM `sp500dataAnalysis.sp500data_qualityScore`;
```

---

## Key Findings

### Top & Bottom Companies

![Top and Bottom Companies](visuals/Screenshot%202026-02-03%20121705.png)

| Rank | Company | Quality Score |
|---|---|---|
| #1 | Verizon | 83.01 |
| #2 | LyondellBasell | 77.33 |
| #3 | AES Corporation | 75.72 |
| #4 | Ford Motor Company | 75.52 |
| #5 | ExxonMobil | 75.47 |
| #6 | AT&T | 74.11 |
| Last | Autodesk | 21.66 |
| Last-1 | Synopsys | 23.29 |
| Last-2 | Ansys | 24.53 |

### Top & Bottom Sectors

![Top and Bottom Sectors](visuals/Screenshot%202026-02-03%20121649.png)

- **Top sectors:** Agricultural Products (67.99), Advertising (66.80), Cable & Satellite (65.69), Brewers (65.31), Energy (63.25)
- **Bottom sectors:** Research & Consulting (34.24), Footwear (37.83), Internet Services & Infrastructure (43.17)
- Small sectors like Agricultural Products and Advertising rank near the top but represent only 1–2 companies — results should not be over-generalized

### Sector Variability

![Sector Variability Box Plot](visuals/Screenshot%202026-02-03%20122159.png)

The box plot reveals that sectors with high average scores can still contain wide-ranging individual results. Energy in particular shows significant spread — some companies score well above the sector average while others fall near the bottom.

### Score Drivers (Contribution Metrics)

![Contribution Metrics](visuals/Screenshot%202026-02-03%20122422.png)

| Metric | Contribution to Overall Score |
|---|---|
| P/B | 36.80% |
| P/S | 26.72% |
| P/E | 24.24% |
| Dividend Yield | 10.37% |
| EBITDA | 1.87% |

Valuation ratios (P/B, P/S, P/E) account for nearly 88% of the total signal. EBITDA contributes almost nothing to score differentiation — an important limitation to consider when interpreting results.

### Company Detail View

![Company Detail Table](visuals/Screenshot%202026-02-03%20121206.png)

The drilldown table shows every company's Quality Score alongside the raw metrics (Dividend Yield, EBITDA, Market Cap, P/E, Price) that feed into it — making it easy to trace why a company scored where it did.

---

## Recommendations

1. **Overweight Communication Services** — Verizon and AT&T offer high yields and low P/E, strong signals in this model
2. **Be cautious with growth tech** — high-P/E growth companies score poorly here; consider a sector-relative normalization for a fairer comparison
3. **Avoid anchoring to thin sectors** — Advertising and Agricultural Products are too small to drive allocation decisions
4. **Iterate on the model** — split no-dividend vs. missing-dividend data; cap ratios by sector rather than globally; test sector-relative normalization to reduce bias against growth

---

## View Architecture

```
sp500data (raw)
    ↓
sp500data_clean (initial cleaning)
    ↓
sp500data_clean_step1 (nulls filled, sector names standardized)
    ↓
sp500data_clean_step2 (sector consolidation: 127 → 11, IQR outlier removal)
    ↓
sp500data_norm (5 metrics normalized 0–100, valuation ratios inverted)
    ↓
sp500data_qualityScore (composite score + ROW_NUMBER + DENSE_RANK)
    ↓
sp500data_qualityScore_sector (sector aggregates table)
```

---

## Repository Structure

```
sp500-quality-score/
│
├── sql/
│   ├── 01_sense_checks.sql
│   ├── 02_logical_tests.sql
│   ├── 03_exploring_data.sql
│   ├── 04_profiling_data.sql
│   ├── 05_cleaning_data.sql
│   ├── 06_shaping_data.sql
│   └── 07_analyzing_data.sql
│
├── visuals/
│   ├── Screenshot 2026-02-03 123325.png   # Tableau Page 1 — Executive View
│   ├── Screenshot 2026-02-03 123556.png   # Tableau Page 2 — Drilldown
│   ├── Screenshot 2026-02-03 121206.png   # Company detail table
│   ├── Screenshot 2026-02-03 121649.png   # Top/Bottom sectors
│   ├── Screenshot 2026-02-03 121705.png   # Top/Bottom companies
│   ├── Screenshot 2026-02-03 122159.png   # Sector variability box plot
│   └── Screenshot 2026-02-03 122422.png   # Contribution metrics
│
├── docs/
│   ├── Finance_-_Project_Name_and_Scenario.docx
│   ├── Finance_-_KPI_Definitions.docx
│   ├── Finance_-_KPI_Dictionary_and_Field_Mapping.xlsx
│   ├── Finance_-_Insights_and_Recommendations.docx
│   └── Finance_-_Working_Notes.docx
│
└── README.md
```

---

## How to Explore This Project

1. **Start with the docs** — `Finance_-_Project_Name_and_Scenario.docx` frames the business problem and stakeholder context
2. **Review the KPI dictionary** — `Finance_-_KPI_Dictionary_and_Field_Mapping.xlsx` defines every field and transformation
3. **Follow the SQL files in order** — sense checks → logical tests → EDA → profiling → cleaning → normalization → scoring → analysis
4. **Read the findings** — `Finance_-_Insights_and_Recommendations.docx` covers the full output

---

## About

Built as a portfolio project demonstrating equity analytics: multi-step SQL view architecture in BigQuery, IQR-based outlier detection, min-max normalization with directional inversion, composite scoring with window functions (`ROW_NUMBER`, `DENSE_RANK`, `PARTITION BY`), and sector-level benchmarking — using S&P 500 fundamental financial data.
