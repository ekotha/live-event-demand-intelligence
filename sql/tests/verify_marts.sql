-- ============================================================
-- verify_marts.sql
-- Purpose:
--   Smoke tests + sanity checks for mart views.
--   These tests should be fast, readable, and re-runnable.
-- ============================================================

-- 0) View exists
SELECT table_schema, table_name
FROM information_schema.views
WHERE table_name = 'mart_artist_market_recommendation';

-- 1) Basic shape check (columns exist via quick select)
-- If this errors, the mart signature changed unexpectedly.
SELECT
  artist_name,
  market_name,
  demand_level,
  demand_velocity_30d,
  momentum_flag,
  super_genre,
  as_of_date,
  competing_events_next_60d,
  tension_score
FROM mart_artist_market_recommendation
LIMIT 5;

-- 2) Grain sanity: no duplicate artist+market rows in the mart
SELECT
  artist_name,
  market_name,
  COUNT(*) AS row_count
FROM mart_artist_market_recommendation
GROUP BY artist_name, market_name
HAVING COUNT(*) > 1;

-- 3) Row-count sanity: mart rows should equal count of artist-market pairs in latest snapshots
WITH latest_pairs AS (
  SELECT artist_key, market_key
  FROM fact_artist_market_snapshot
  GROUP BY artist_key, market_key
)
SELECT
  (SELECT COUNT(*) FROM latest_pairs) AS expected_rows,
  (SELECT COUNT(*) FROM mart_artist_market_recommendation) AS actual_rows;

-- 4) Null checks for required fields
SELECT COUNT(*) AS null_artist_name
FROM mart_artist_market_recommendation
WHERE artist_name IS NULL;

SELECT COUNT(*) AS null_market_name
FROM mart_artist_market_recommendation
WHERE market_name IS NULL;

SELECT COUNT(*) AS null_as_of_date
FROM mart_artist_market_recommendation
WHERE as_of_date IS NULL;

SELECT COUNT(*) AS null_demand_level
FROM mart_artist_market_recommendation
WHERE demand_level IS NULL;

SELECT COUNT(*) AS null_super_genre
FROM mart_artist_market_recommendation
WHERE super_genre IS NULL;

-- 5) Competition should be non-negative
SELECT COUNT(*) AS negative_competition_rows
FROM mart_artist_market_recommendation
WHERE competing_events_next_60d < 0;

-- 6) Tension score behavior sanity:
-- If demand_velocity_30d is NULL, tension_score should be NULL.
SELECT COUNT(*) AS tension_should_be_null
FROM mart_artist_market_recommendation
WHERE demand_velocity_30d IS NULL
  AND tension_score IS NOT NULL;

-- If demand_velocity_30d is NOT NULL, tension_score should be NOT NULL.
SELECT COUNT(*) AS tension_unexpectedly_null
FROM mart_artist_market_recommendation
WHERE demand_velocity_30d IS NOT NULL
  AND tension_score IS NULL;

-- 7) Optional: show the mart ordered by highest tension (useful for quick inspection)
SELECT
  artist_name,
  market_name,
  super_genre,
  demand_velocity_30d,
  competing_events_next_60d,
  tension_score,
  momentum_flag
FROM mart_artist_market_recommendation
ORDER BY tension_score DESC NULLS LAST
LIMIT 20;