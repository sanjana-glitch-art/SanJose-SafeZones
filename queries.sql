-- 1) Daily call volume

SELECT DATE(f.offense_at) AS day, COUNT(*) AS calls
FROM fact_calls_2025 f
WHERE f.offense_at IS NOT NULL
GROUP BY day
ORDER BY day ASC;

-- 2) Calls by call type (top 10)

SELECT
  dct.CALL_TYPE,
  COUNT(*) AS calls
FROM fact_calls_2025 f
LEFT JOIN dim_calltype dct USING (CALLTYPE_CODE)
GROUP BY dct.CALL_TYPE
ORDER BY calls DESC
LIMIT 10;

-- 3) Average priority by disposition
SELECT
  dd.FINAL_DISPO,
  COUNT(*) AS calls,
  ROUND(AVG(f.PRIORITY), 2) AS avg_priority
FROM fact_calls_2025 f
LEFT JOIN dim_disposition dd USING (FINAL_DISPO_CODE)
WHERE f.PRIORITY IS NOT NULL
GROUP BY dd.FINAL_DISPO
ORDER BY avg_priority ASC;   -- lower = more severe if 1 is highest priority

-- 4) Call Volume by Zip Code
SELECT 
  ADDRESS,
  COUNT(*) AS total_calls,
  SUM(CASE WHEN PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS severe_calls
FROM fact_calls_2025
WHERE offense_at >= CURRENT_DATE - INTERVAL 90 DAY
  AND ADDRESS IS NOT NULL
  AND ADDRESS <> ''
GROUP BY ADDRESS
ORDER BY total_calls DESC
LIMIT 1000;

-- 5) Average response time by priority
SELECT 
  PRIORITY,
  COUNT(*) AS total_calls,
  ROUND(AVG(PRIORITY), 2) AS avg_priority
FROM fact_calls_2025
WHERE offense_at >= CURRENT_DATE - INTERVAL 90 DAY
GROUP BY PRIORITY
ORDER BY PRIORITY;

-- 6) Hotspot addresses by severity (top 15)
SELECT
  f.ADDRESS,
  COUNT(*) AS total_calls,
  ROUND(SUM(CASE WHEN f.PRIORITY IN (1,2) THEN 1 ELSE 0 END) / COUNT(*), 4) AS severe_rate,
  ROUND(AVG(f.PRIORITY), 2) AS avg_priority
FROM fact_calls_2025 f
WHERE f.ADDRESS IS NOT NULL AND f.ADDRESS <> ''
GROUP BY f.ADDRESS
HAVING COUNT(*) >= 20
ORDER BY severe_rate DESC, total_calls DESC, avg_priority ASC
LIMIT 15;

-- 7) 7-day rolling trend of calls & severe share
WITH daily AS (
  SELECT
    DATE(f.offense_at) AS day,
    COUNT(*) AS calls,
    SUM(CASE WHEN f.PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS severe_calls
  FROM fact_calls_2025 f
  WHERE f.offense_at IS NOT NULL
  GROUP BY DATE(f.offense_at)
)
SELECT
  day,
  calls,
  severe_calls,
  ROUND(AVG(calls) OVER (ORDER BY day ROWS 6 PRECEDING), 2) AS calls_ma7,
  ROUND(AVG(severe_calls) OVER (ORDER BY day ROWS 6 PRECEDING), 2) AS severe_ma7,
  ROUND(
    (AVG(severe_calls) OVER (ORDER BY day ROWS 6 PRECEDING)) /
    NULLIF(AVG(calls) OVER (ORDER BY day ROWS 6 PRECEDING), 0),
    4
  ) AS severe_share_ma7
FROM daily
ORDER BY day;

-- 8) Show month-over-month call volume with running totals and percent change

WITH monthly_calls AS (
  SELECT
    DATE_FORMAT(offense_at, '%Y-%m') AS month,
    COUNT(*) AS calls,
    SUM(CASE WHEN PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS severe_calls
  FROM fact_calls_2025
  WHERE offense_at IS NOT NULL
  GROUP BY DATE_FORMAT(offense_at, '%Y-%m')
)
SELECT
  month,
  calls,
  severe_calls,
  SUM(calls) OVER (ORDER BY month) AS running_total_calls,
  LAG(calls) OVER (ORDER BY month) AS prev_month_calls,
  ROUND(100.0 * (calls - LAG(calls) OVER (ORDER BY month)) / 
    NULLIF(LAG(calls) OVER (ORDER BY month), 0), 2) AS pct_change_mom,
  ROUND(AVG(calls) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) AS ma3_calls
FROM monthly_calls
ORDER BY month;

-- 9) Create a reusable view for disposition performance analysis

CREATE OR REPLACE VIEW vw_disposition_performance AS
SELECT
  dd.FINAL_DISPO,
  dd.FINAL_DISPO_CODE,
  COUNT(*) AS total_calls,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM fact_calls_2025), 2) AS pct_of_total,
  ROUND(AVG(f.PRIORITY), 2) AS avg_priority,
  SUM(CASE WHEN f.PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS severe_count,
  COUNT(DISTINCT DATE(f.offense_at)) AS active_days,
  ROUND(COUNT(*) / NULLIF(COUNT(DISTINCT DATE(f.offense_at)), 0), 1) AS avg_per_day
FROM fact_calls_2025 f
LEFT JOIN dim_disposition dd USING (FINAL_DISPO_CODE)
WHERE f.PRIORITY IS NOT NULL
GROUP BY dd.FINAL_DISPO, dd.FINAL_DISPO_CODE;

  -- Query the view:
  SELECT * FROM vw_disposition_performance
  ORDER BY total_calls DESC
  LIMIT 10;

-- 10) Indexing Optimization Analysis

  -- First, analyze existing index coverage:
SELECT
  'Current Index Analysis' AS analysis_type,
  INDEX_NAME,
  COLUMN_NAME,
  SEQ_IN_INDEX,
  CARDINALITY,
  CASE 
    WHEN CARDINALITY IS NULL THEN '⚠️ No statistics'
    WHEN CARDINALITY < 100 THEN '⚠️ Low cardinality'
    WHEN CARDINALITY > 10000 THEN '✓ Good selectivity'
    ELSE '✓ Moderate'
  END AS index_quality
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'sanjose_police_calls'
  AND TABLE_NAME = 'fact_calls_2025'
ORDER BY INDEX_NAME, SEQ_IN_INDEX;

  -- Recommend new indexes based on query patterns:
SELECT
  'Index Recommendations' AS recommendation_type,
  'CREATE INDEX idx_priority_offense_at ON fact_calls_2025(PRIORITY, offense_at);' AS suggested_index,
  'Optimize queries filtering by priority and date range' AS rationale
UNION ALL
SELECT
  'Index Recommendations',
  'CREATE INDEX idx_address_priority ON fact_calls_2025(ADDRESS(100), PRIORITY);',
  'Speed up hotspot analysis queries'
UNION ALL
SELECT
  'Index Recommendations',
  'CREATE INDEX idx_offense_at_calltype ON fact_calls_2025(offense_at, CALLTYPE_CODE);',
  'Improve time-series analysis by call type';

  -- Test query performance impact (example):
EXPLAIN FORMAT=JSON
SELECT
  dct.CALL_TYPE,
  COUNT(*) AS calls,
  AVG(f.PRIORITY) AS avg_priority
FROM fact_calls_2025 f
JOIN dim_calltype dct USING (CALLTYPE_CODE)
WHERE f.offense_at >= '2025-01-01'
  AND f.PRIORITY IN (1,2)
GROUP BY dct.CALL_TYPE
ORDER BY calls DESC;

-- 11) Predictive pattern analysis

WITH location_history AS (
  SELECT
    ADDRESS,
    DATE(offense_at) AS call_date,
    COUNT(*) AS daily_calls,
    SUM(CASE WHEN PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS severe_calls,
    AVG(PRIORITY) AS avg_priority
  FROM fact_calls_2025
  WHERE offense_at >= CURRENT_DATE - INTERVAL 180 DAY
    AND ADDRESS IS NOT NULL
    AND ADDRESS <> ''
    AND PRIORITY IS NOT NULL
  GROUP BY ADDRESS, DATE(offense_at)
),
location_trends AS (
  SELECT
    ADDRESS,
    COUNT(DISTINCT call_date) AS active_days,
    SUM(daily_calls) AS total_calls,
    SUM(severe_calls) AS total_severe,
    ROUND(AVG(daily_calls), 2) AS avg_daily_calls,
    ROUND(AVG(severe_calls), 2) AS avg_daily_severe,
    ROUND(STDDEV(daily_calls), 2) AS stddev_calls,
    MAX(call_date) AS last_incident,
    DATEDIFF(CURRENT_DATE, MAX(call_date)) AS days_since_last
  FROM location_history
  GROUP BY ADDRESS
  HAVING COUNT(DISTINCT call_date) >= 10
),
risk_scoring AS (
  SELECT
    ADDRESS,
    total_calls,
    total_severe,
    avg_daily_calls,
    avg_daily_severe,
    days_since_last,
    -- Risk score calculation
    ROUND(
      (avg_daily_severe * 10) +                    -- Severity weight
      (avg_daily_calls * 2) +                      -- Volume weight
      (total_severe / NULLIF(total_calls, 0) * 20) + -- Severe rate weight
      (CASE 
        WHEN days_since_last <= 7 THEN 10          -- Recent activity bonus
        WHEN days_since_last <= 14 THEN 5
        ELSE 0
      END)
    , 2) AS risk_score,
    NTILE(5) OVER (ORDER BY 
      (avg_daily_severe * 10) + (avg_daily_calls * 2) + 
      (total_severe / NULLIF(total_calls, 0) * 20)
    DESC) AS risk_quintile
  FROM location_trends
)
SELECT
  ADDRESS,
  total_calls AS historical_calls_180d,
  total_severe AS historical_severe_180d,
  ROUND(avg_daily_severe, 2) AS expected_severe_per_day,
  days_since_last,
  risk_score,
  CASE
    WHEN risk_quintile = 1 THEN '🔴 Critical - Top 20%'
    WHEN risk_quintile = 2 THEN '🟠 High Risk'
    WHEN risk_quintile = 3 THEN '🟡 Moderate Risk'
    ELSE '🟢 Lower Risk'
  END AS risk_category
FROM risk_scoring
WHERE risk_quintile <= 2  -- Focus on top 40%
ORDER BY risk_score DESC
LIMIT 25;

-- 12) Percentile analysis

WITH response_times AS (
  SELECT
    dct.CALL_TYPE,
    f.PRIORITY,
    TIMESTAMPDIFF(MINUTE, f.offense_at, f.offense_at) AS response_minutes,  -- Using offense_at as proxy
    COUNT(*) OVER (PARTITION BY dct.CALL_TYPE) AS type_call_count
  FROM fact_calls_2025 f
  JOIN dim_calltype dct USING (CALLTYPE_CODE)
  WHERE f.offense_at >= CURRENT_DATE - INTERVAL 90 DAY
    AND f.PRIORITY IS NOT NULL
),
ranked_times AS (
  SELECT
    CALL_TYPE,
    PRIORITY,
    response_minutes,
    type_call_count,
    PERCENT_RANK() OVER (PARTITION BY CALL_TYPE ORDER BY response_minutes) AS percentile_rank
  FROM response_times
)
SELECT
  CALL_TYPE,
  type_call_count AS total_calls,
  ROUND(AVG(PRIORITY), 2) AS avg_priority,
  
  -- Percentile calculations
  MAX(CASE WHEN percentile_rank <= 0.50 THEN response_minutes END) AS p50_minutes,
  MAX(CASE WHEN percentile_rank <= 0.75 THEN response_minutes END) AS p75_minutes,
  MAX(CASE WHEN percentile_rank <= 0.90 THEN response_minutes END) AS p90_minutes,
  MAX(CASE WHEN percentile_rank <= 0.95 THEN response_minutes END) AS p95_minutes,
  MAX(CASE WHEN percentile_rank <= 0.99 THEN response_minutes END) AS p99_minutes
FROM ranked_times
GROUP BY CALL_TYPE, type_call_count
HAVING type_call_count >= 50
ORDER BY type_call_count DESC
LIMIT 20;

-- 13) Cross-Tabulation

SELECT
  HOUR(offense_at) AS hour,
  
  -- Days of week as columns
  SUM(CASE WHEN DAYNAME(offense_at) = 'Sunday' THEN 1 ELSE 0 END) AS Sun,
  SUM(CASE WHEN DAYNAME(offense_at) = 'Monday' THEN 1 ELSE 0 END) AS Mon,
  SUM(CASE WHEN DAYNAME(offense_at) = 'Tuesday' THEN 1 ELSE 0 END) AS Tue,
  SUM(CASE WHEN DAYNAME(offense_at) = 'Wednesday' THEN 1 ELSE 0 END) AS Wed,
  SUM(CASE WHEN DAYNAME(offense_at) = 'Thursday' THEN 1 ELSE 0 END) AS Thu,
  SUM(CASE WHEN DAYNAME(offense_at) = 'Friday' THEN 1 ELSE 0 END) AS Fri,
  SUM(CASE WHEN DAYNAME(offense_at) = 'Saturday' THEN 1 ELSE 0 END) AS Sat,
  
  COUNT(*) AS total_calls,
  ROUND(AVG(PRIORITY), 2) AS avg_priority
FROM fact_calls_2025
WHERE offense_at >= CURRENT_DATE - INTERVAL 90 DAY
  AND PRIORITY IS NOT NULL
GROUP BY HOUR(offense_at)
ORDER BY hour;

  -- Create severity heat map (high-priority incidents)
SELECT
  HOUR(offense_at) AS hour,
  
  SUM(CASE WHEN DAYNAME(offense_at) = 'Sunday' AND PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS Sun_severe,
  SUM(CASE WHEN DAYNAME(offense_at) = 'Monday' AND PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS Mon_severe,
  SUM(CASE WHEN DAYNAME(offense_at) = 'Tuesday' AND PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS Tue_severe,
  SUM(CASE WHEN DAYNAME(offense_at) = 'Wednesday' AND PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS Wed_severe,
  SUM(CASE WHEN DAYNAME(offense_at) = 'Thursday' AND PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS Thu_severe,
  SUM(CASE WHEN DAYNAME(offense_at) = 'Friday' AND PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS Fri_severe,
  SUM(CASE WHEN DAYNAME(offense_at) = 'Saturday' AND PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS Sat_severe,
  
  SUM(CASE WHEN PRIORITY IN (1,2) THEN 1 ELSE 0 END) AS total_severe
FROM fact_calls_2025
WHERE offense_at >= CURRENT_DATE - INTERVAL 90 DAY
GROUP BY HOUR(offense_at)
ORDER BY hour;

-- 14) Pareto analysis

WITH weekly_calls AS (
  SELECT
    ADDRESS,
    WEEK(offense_at) AS week_num,
    COUNT(*) AS weekly_total
  FROM fact_calls_2025
  WHERE offense_at >= CURRENT_DATE - INTERVAL 100 DAY
    AND ADDRESS IS NOT NULL
  GROUP BY ADDRESS, WEEK(offense_at)
  ),
  trent_variability AS(
  SELECT
    ADDRESS,
    ROUND(AVG (weekly_total),2) AS avg_weekly_calls,
  FROM weekly_Calls
  GROUP BY ADDRESS
  )
  SELECT
    ADDRESS,
    avg_weekly_calls,
    volatility,
    CASE
      WHEN volatility < 2 THEN 'Stable Hotspot'
      ELSE 'Volatile Hotspot'
    END AS hotspot_type
  FROM trend_variability
  ORDER BY avg_weekly_calls DESC
  LIMIT 25;

-- 15) Incident Co-Occurance Analysis

WITH grouped AS(
  SELECT
    ADDRESS,
    DATE(offense_at) AS call_date,
    GROUP_CONCAT(DISTINCT CALLTYPE_CODE ORDER BY CALLTYPE_CODE) AS types
  FROM fact_calls_2025
  WHERE offense_at >= CURRENT_DATE -INTERVAL 90 DAY
    AND ADDRESS IS NOT NULL
  GROUP BY ADDRESS, DATE (offense_at)
  ),
  paris AS(
    SELECT
      SUBSTRING_INDEX(types,',',1) AS type1,
      SUBSTRING_INDEX(types,',',-1) AS type2
    FROM grouped
    WHERE types LIKE '%,%'
  )
  SELECT
    type1,type2, COUNT(*) AS co_occurence_count
  FROM paris
  GROUP BY type1, type2
  ORDER BY co_occurence_count DESC
  LIMIT 20;




