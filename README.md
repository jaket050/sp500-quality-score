-- ============================================================
-- S&P 500 Quality Score Project
-- Step 2: Profiling
-- Purpose: Understand data distributions, nulls, and outliers
-- ============================================================


-- 1. Missing value distribution across all metric columns
SELECT 'price' AS metric, COUNTIF(price IS NULL) AS missing
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'priceToEarnings', COUNTIF(priceToEarnings IS NULL)
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'dividendYield', COUNTIF(dividendYield IS NULL)
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'EarningPerShare', COUNTIF(EarningPerShare IS NULL)
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'ebitda', COUNTIF(ebitda IS NULL)
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'PriceToSales', COUNTIF(PriceToSales IS NULL)
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'priceToBook', COUNTIF(priceToBook IS NULL)
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`;


-- 2. Outlier detection using IQR method for P/E and P/S
-- Upper bound = Q3 + 1.5 * (Q3 - Q1)
WITH bounds AS (
  SELECT
    metric,
    Q1,
    Q3,
    (Q3 - Q1) AS iqr,
    Q1 - 1.5 * (Q3 - Q1) AS lower_bound,
    Q3 + 1.5 * (Q3 - Q1) AS upper_bound
  FROM (
    SELECT
      'priceToEarnings' AS metric,
      APPROX_QUANTILES(priceToEarnings, 4)[OFFSET(1)] AS Q1,
      APPROX_QUANTILES(priceToEarnings, 4)[OFFSET(3)] AS Q3
    FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
    UNION ALL
    SELECT
      'PriceToSales',
      APPROX_QUANTILES(PriceToSales, 4)[OFFSET(1)],
      APPROX_QUANTILES(PriceToSales, 4)[OFFSET(3)]
    FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
  )
)
SELECT
  metric,
  lower_bound,
  upper_bound
FROM bounds;


-- 3. Sector-level null counts
SELECT
  sector,
  COUNT(*) AS n,
  COUNTIF(priceToEarnings IS NULL) AS null_pe,
  COUNTIF(dividendYield IS NULL) AS null_div,
  COUNTIF(ebitda IS NULL) AS null_ebitda
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
GROUP BY sector
ORDER BY n DESC;


-- 4. Decile distribution across all key metrics
SELECT
  APPROX_QUANTILES(priceToEarnings, 10) AS pe_deciles,
  APPROX_QUANTILES(ebitda, 10) AS ebitda_deciles,
  APPROX_QUANTILES(dividendYield, 10) AS divy_deciles,
  APPROX_QUANTILES(PriceToSales, 10) AS ps_deciles,
  APPROX_QUANTILES(priceToBook, 10) AS pb_deciles,
  APPROX_QUANTILES(marketCap, 10) AS mktcap_deciles
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`;
