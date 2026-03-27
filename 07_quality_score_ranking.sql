-- ============================================================
-- S&P 500 Quality Score Project
-- Step 8: Analysis
-- Purpose: Identify top and bottom performers, sector leaders,
--          sector aggregates, and metric correlation drivers
-- ============================================================


-- 1. Top 10 companies by Quality Score
SELECT
  symbol,
  name,
  sector,
  quality_score,
  pe_norm,
  ebitda_norm,
  divy_norm,
  ps_norm,
  pb_norm
FROM `projectspractice12.sp500dataAnalysis.sp500data_qualityScore`
ORDER BY quality_score DESC
LIMIT 10;


-- 2. Bottom 10 companies by Quality Score
SELECT
  symbol,
  name,
  sector,
  quality_score,
  pe_norm,
  ebitda_norm,
  divy_norm,
  ps_norm,
  pb_norm
FROM `projectspractice12.sp500dataAnalysis.sp500data_qualityScore`
ORDER BY quality_score ASC
LIMIT 10;


-- 3. Sector leaders (rank 1 per sector)
SELECT
  sector,
  symbol,
  name,
  quality_score,
  rank_in_sector
FROM `projectspractice12.sp500dataAnalysis.sp500data_qualityScore`
WHERE rank_in_sector = 1
ORDER BY quality_score DESC;


-- 4. Sector aggregates
-- Average, min, max Quality Score and company count per sector
SELECT
  sector,
  ROUND(AVG(quality_score), 2) AS avg_quality_score,
  MIN(quality_score) AS min_quality_score,
  MAX(quality_score) AS max_quality_score,
  COUNT(*) AS n_symbols
FROM `projectspractice12.sp500dataAnalysis.sp500data_qualityScore`
GROUP BY sector
ORDER BY avg_quality_score DESC;


-- 5. Metric correlation analysis
-- Identifies which metrics drive Quality Score variation the most
SELECT
  CORR(quality_score, pe_norm) AS corr_pe,
  CORR(quality_score, ebitda_norm) AS corr_ebitda,
  CORR(quality_score, divy_norm) AS corr_divy,
  CORR(quality_score, ps_norm) AS corr_ps,
  CORR(quality_score, pb_norm) AS corr_pb
FROM `projectspractice12.sp500dataAnalysis.sp500data_qualityScore`;
