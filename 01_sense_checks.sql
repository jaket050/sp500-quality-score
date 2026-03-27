-- ============================================================
-- S&P 500 Quality Score Project
-- Step 5: Exploring
-- Purpose: Understand data structure, sector distribution,
--          and summary statistics before scoring
-- ============================================================


-- 1. Row count, distinct symbols, distinct sectors
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT symbol) AS unique_symbols,
  COUNT(DISTINCT sector) AS sectors
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`;


-- 2. Sector distribution with percentage of total
SELECT
  sector,
  COUNT(*) AS n,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
GROUP BY sector
ORDER BY n DESC;


-- 3. Sector coverage and bad price rows
SELECT
  sector,
  COUNT(*) AS n,
  COUNTIF(price IS NULL OR price <= 0) AS bad_price_rows
FROM `projectspractice12.sp500dataAnalysis.sp500data`
GROUP BY sector
ORDER BY n DESC;


-- 4. Summary statistics across all key metrics
SELECT 'price' AS metrics, MIN(price) AS min, MAX(price) AS max, AVG(price) AS avg
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'priceToEarnings', MIN(priceToEarnings), MAX(priceToEarnings), AVG(priceToEarnings)
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'dividendYield', MIN(dividendYield), MAX(dividendYield), AVG(dividendYield)
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'ebitda', MIN(ebitda), MAX(ebitda), AVG(ebitda)
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'PriceToSales', MIN(PriceToSales), MAX(PriceToSales), AVG(PriceToSales)
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`
UNION ALL
SELECT 'priceToBook', MIN(priceToBook), MAX(priceToBook), AVG(priceToBook)
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`;
