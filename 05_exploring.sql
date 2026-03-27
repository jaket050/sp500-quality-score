-- ============================================================
-- S&P 500 Quality Score Project
-- Step 4: Logical Tests
-- Purpose: Verify data integrity and internal consistency
-- ============================================================


-- 1. Price should fall within 52-week low and high range
-- Also checks for inverted 52-week ranges (low > high)
SELECT
  COUNTIF(
    WeekLow52 IS NOT NULL AND WeekHigh52 IS NOT NULL
    AND (price < WeekLow52 OR price > WeekHigh52)
  ) AS price_outside_52w,
  COUNTIF(
    WeekLow52 IS NOT NULL AND WeekHigh52 IS NOT NULL
    AND WeekLow52 > WeekHigh52
  ) AS inverted_52w_range
FROM `projectspractice12.sp500dataAnalysis.sp500data`;


-- 2. Verify reported P/E matches calculated P/E (price / EPS)
-- Flags any rows where the difference is greater than 2
SELECT
  COUNT(*) AS rows_checked,
  COUNTIF(ABS((price / NULLIF(EarningPerShare, 0)) - priceToEarnings) > 2) AS pe_mismatch_gt2
FROM `projectspractice12.sp500dataAnalysis.sp500data`;
