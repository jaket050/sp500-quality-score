-- ============================================================
-- S&P 500 Quality Score Project
-- Step 3: Cleaning
-- Purpose: Standardize sectors, handle nulls, remove outliers
-- ============================================================


-- Step 3a: Clean step 1
-- Trim whitespace, capitalize sector names, replace nulls with 0
CREATE OR REPLACE VIEW `projectspractice12.sp500dataAnalysis.sp500data_clean_step1` AS
SELECT
  symbol,
  name,
  INITCAP(TRIM(sector)) AS sector,
  price,
  priceToEarnings,
  IFNULL(dividendYield, 0) AS dividendYield,
  EarningPerShare,
  WeekLow52,
  WeekHigh52,
  marketCap,
  IFNULL(ebitda, 0) AS ebitda,
  PriceToSales,
  priceToBook
FROM `projectspractice12.sp500dataAnalysis.sp500data_clean`;


-- Step 3b: Clean step 2
-- Consolidate 127 sector labels down to 36 standardized categories
-- Remove outliers above IQR upper bound for P/E and P/S
CREATE OR REPLACE VIEW `projectspractice12.sp500dataAnalysis.sp500data_clean_step2` AS
WITH mapped AS (
  SELECT
    symbol,
    name,
    CASE
      WHEN sector IS NULL OR TRIM(sector) = '' THEN 'Unclassified'
      WHEN UPPER(sector) LIKE '%REIT%' OR UPPER(sector) LIKE '%REAL ESTATE%' THEN 'Real Estate'
      WHEN UPPER(sector) LIKE '%BANK%' OR UPPER(sector) LIKE '%INSUR%'
        OR UPPER(sector) LIKE '%CAPITAL MARKET%' OR UPPER(sector) LIKE '%FINAN%'
        OR UPPER(sector) LIKE '%ASSET MANAGE%' OR UPPER(sector) LIKE '%BROKER%' THEN 'Financials'
      WHEN UPPER(sector) LIKE '%SOFTWARE%' OR UPPER(sector) LIKE '%SEMICON%'
        OR UPPER(sector) LIKE '%TECH%' OR UPPER(sector) LIKE '%HARDWARE%'
        OR UPPER(sector) LIKE '%IT %' OR UPPER(sector) = 'IT'
        OR UPPER(sector) LIKE '%DATA%' OR UPPER(sector) LIKE '%ELECTRONIC%' THEN 'Information Technology'
      WHEN UPPER(sector) LIKE '%TELECOM%' OR UPPER(sector) LIKE '%COMMUNICAT%'
        OR UPPER(sector) LIKE '%MEDIA%' OR UPPER(sector) LIKE '%ENTERTAIN%'
        OR UPPER(sector) LIKE '%INTERACTIVE%' THEN 'Communication Services'
      WHEN UPPER(sector) LIKE '%HEALTH%' OR UPPER(sector) LIKE '%PHARM%'
        OR UPPER(sector) LIKE '%BIOTECH%' OR UPPER(sector) LIKE '%MEDICAL%'
        OR UPPER(sector) LIKE '%LIFE SCIENCE%' THEN 'Health Care'
      WHEN UPPER(sector) LIKE '%CONSUMER STAPLES%' OR UPPER(sector) LIKE '%CONSUMER DEFENSIVE%'
        OR UPPER(sector) LIKE '%FOOD%' OR UPPER(sector) LIKE '%BEVERAGE%'
        OR UPPER(sector) LIKE '%TOBACCO%' OR UPPER(sector) LIKE '%HOUSEHOLD%'
        OR UPPER(sector) LIKE '%PERSONAL PRODUCT%' OR UPPER(sector) LIKE '%STAPLES RETAIL%' THEN 'Consumer Staples'
      WHEN UPPER(sector) LIKE '%CONSUMER DISCRETIONARY%' OR UPPER(sector) LIKE '%AUTOM%'
        OR UPPER(sector) LIKE '%RETAIL%' OR UPPER(sector) LIKE '%TEXTILE%'
        OR UPPER(sector) LIKE '%APPAREL%' OR UPPER(sector) LIKE '%LUXURY%'
        OR UPPER(sector) LIKE '%HOTEL%' OR UPPER(sector) LIKE '%RESTAURANT%'
        OR UPPER(sector) LIKE '%LEISURE%' OR UPPER(sector) LIKE '%E-COMMERCE%' THEN 'Consumer'
      WHEN UPPER(sector) LIKE '%INDUSTR%' OR UPPER(sector) LIKE '%AEROSPACE%'
        OR UPPER(sector) LIKE '%DEFENSE%' OR UPPER(sector) LIKE '%MACHIN%'
        OR UPPER(sector) LIKE '%CONSTRUCTION%' OR UPPER(sector) LIKE '%ENGINEER%'
        OR UPPER(sector) LIKE '%TRANSPORT%' OR UPPER(sector) LIKE '%LOGISTIC%'
        OR UPPER(sector) LIKE '%COMMERCIAL SERVICES%' THEN 'Industrials'
      WHEN UPPER(sector) LIKE '%MATERIAL%' OR UPPER(sector) LIKE '%CHEMIC%'
        OR UPPER(sector) LIKE '%METAL%' OR UPPER(sector) LIKE '%MINING%'
        OR UPPER(sector) LIKE '%PAPER%' OR UPPER(sector) LIKE '%FOREST%' THEN 'Materials'
      WHEN UPPER(sector) LIKE '%ENERGY%' OR UPPER(sector) LIKE '%OIL%'
        OR UPPER(sector) LIKE '%GAS%' OR UPPER(sector) LIKE '%COAL%'
        OR UPPER(sector) LIKE '%RENEWABLE%' OR UPPER(sector) LIKE '%SOLAR%' THEN 'Energy'
      WHEN UPPER(sector) LIKE '%UTILITY%' OR UPPER(sector) LIKE '%ELECTRIC%'
        OR UPPER(sector) LIKE '%WATER%' OR UPPER(sector) LIKE '%POWER%'
        OR UPPER(sector) LIKE '%GAS UTIL%' THEN 'Utilities'
      ELSE sector
    END AS sector_std,
    price,
    priceToEarnings,
    dividendYield,
    EarningPerShare,
    WeekLow52,
    WeekHigh52,
    marketCap,
    ebitda,
    PriceToSales,
    priceToBook
  FROM `projectspractice12.sp500dataAnalysis.sp500data_clean_step1`
)
SELECT
  symbol,
  name,
  sector_std AS sector,
  price,
  priceToEarnings,
  dividendYield,
  EarningPerShare,
  WeekLow52,
  WeekHigh52,
  marketCap,
  ebitda,
  PriceToSales,
  priceToBook
FROM mapped
WHERE PriceToSales >= 0
  AND PriceToSales <= 12.78       -- IQR upper bound
  AND priceToEarnings >= 0
  AND priceToEarnings <= 69.185;  -- IQR upper bound
