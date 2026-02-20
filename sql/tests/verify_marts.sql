-- Verify view exists
SELECT table_schema, table_name
FROM information_schema.views
WHERE table_name = 'mart_artist_market_recommendation';

-- Inspect output
SELECT *
FROM mart_artist_market_recommendation
ORDER BY demand_velocity_30d DESC;

-- Sanity check row count equals number of artist-market pairs in latest snapshots
WITH latest_pairs AS (
  SELECT artist_key, market_key
  FROM fact_artist_market_snapshot
  GROUP BY artist_key, market_key
)
SELECT
  (SELECT COUNT(*) FROM latest_pairs) AS expected_rows,
  (SELECT COUNT(*) FROM mart_artist_market_recommendation) AS actual_rows;
