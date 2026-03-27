-- ============================================================
-- S&P 500 Quality Score Project
-- Step 7: Quality Score and Ranking
-- Purpose: Calculate composite Quality Score as equally
--          weighted mean of all five normalized metrics.
--          Rank overall and within each sector.
-- ============================================================


-- Quality Score view with overall and sector rankings
CREATE OR REPLACE VIEW `projectspractice12.sp500dataAnalysis.sp500data_qualityScore` AS
SELECT
  symbol,
  name,
  sector,
  price,
  marketCap,
  priceToEarnings,
  Pe_norm,
  ebitda,
  ebitda_norm,
  dividendYield,
  divy_norm,
  PriceToSales,
  ps_norm,
  priceToBook,
  pb_norm,

  -- Composite Quality Score: equally weighted average of all five normalized metrics
  ROUND((pe_norm + ebitda_norm + divy_norm + ps_norm + pb_norm) / 5, 2) AS quality_score,

  -- Overall rank across all S&P 500 companies
  ROW_NUMBER() OVER (
    ORDER BY (pe_norm + ebitda_norm + divy_norm + ps_norm + pb_norm) DESC
  ) AS rank_overall,

  -- Rank within each sector
  DENSE_RANK() OVER (
    PARTITION BY sector
    ORDER BY (pe_norm + ebitda_norm + ps_norm + pb_norm + divy_norm) DESC
  ) AS rank_in_sector

FROM `projectspractice12.sp500dataAnalysis.sp500data_norm`;


-- Sector summary table
-- Average, min, and max Quality Score per sector with company counts
CREATE OR REPLACE TABLE `projectspractice12.sp500dataAnalysis.sp500data_qualityScore_sector` AS
SELECT
  sector,
  ROUND(AVG(quality_score), 2) AS avg_quality_score,
  MIN(quality_score) AS min_quality_score,
  MAX(quality_score) AS max_quality_score,
  COUNT(*) AS n_symbols
FROM `projectspractice12.sp500dataAnalysis.sp500data_qualityScore`
GROUP BY sector
ORDER BY avg_quality_score DESC;


-- Full ranked list ordered by overall rank
SELECT
  symbol,
  name,
  sector,
  quality_score,
  rank_overall,
  rank_in_sector
FROM `projectspractice12.sp500dataAnalysis.sp500data_qualityScore`
ORDER BY rank_overall ASC;
