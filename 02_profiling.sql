-- ============================================================
-- S&P 500 Quality Score Project
-- Step 1: Sense Checks
-- Purpose: Validate raw data before any transformations
-- ============================================================


-- 1. Sample rows
SELECT *
FROM `projectspractice12.sp500dataAnalysis.sp500data`
LIMIT 5;


-- 2. Row count and distinct symbol count
SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT symbol) AS ticker_count
FROM `projectspractice12.sp500dataAnalysis.sp500data`;


-- 3. Null value check across all columns
SELECT
  SUM(CASE WHEN symbol IS NULL THEN 1 ELSE 0 END) AS null_symbol,
  SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS null_name,
  SUM(CASE WHEN sector IS NULL THEN 1 ELSE 0 END) AS null_sector,
  SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_price,
  SUM(CASE WHEN priceToEarnings IS NULL THEN 1 ELSE 0 END) AS null_pe,
  SUM(CASE WHEN dividendYield IS NULL THEN 1 ELSE 0 END) AS null_div_yield,
  SUM(CASE WHEN EarningPerShare IS NULL THEN 1 ELSE 0 END) AS null_eps,
  SUM(CASE WHEN WeekLow52 IS NULL THEN 1 ELSE 0 END) AS null_wk_low,
  SUM(CASE WHEN WeekHigh52 IS NULL THEN 1 ELSE 0 END) AS null_wk_high,
  SUM(CASE WHEN marketCap IS NULL THEN 1 ELSE 0 END) AS null_mktcap,
  SUM(CASE WHEN ebitda IS NULL THEN 1 ELSE 0 END) AS null_ebitda,
  SUM(CASE WHEN PriceToSales IS NULL THEN 1 ELSE 0 END) AS null_ps,
  SUM(CASE WHEN priceToBook IS NULL THEN 1 ELSE 0 END) AS null_pb
FROM `projectspractice12.sp500dataAnalysis.sp500data`;


-- 4. Range check across all key metrics
SELECT
  MIN(price) AS min_price,
  MAX(price) AS max_price,
  MIN(priceToEarnings) AS min_pe,
  MAX(priceToEarnings) AS max_pe,
  MIN(dividendYield) AS min_div_yield,
  MAX(dividendYield) AS max_div_yield,
  MIN(EarningPerShare) AS min_eps,
  MAX(EarningPerShare) AS max_eps,
  MIN(WeekLow52) AS min_wk_low,
  MAX(WeekHigh52) AS max_wk_high,
  MIN(marketCap) AS min_mktcap,
  MAX(marketCap) AS max_mktcap,
  MIN(ebitda) AS min_ebitda,
  MAX(ebitda) AS max_ebitda,
  MIN(PriceToSales) AS min_ps,
  MAX(PriceToSales) AS max_ps,
  MIN(priceToBook) AS min_pb,
  MAX(priceToBook) AS max_pb
FROM `projectspractice12.sp500dataAnalysis.sp500data`;
