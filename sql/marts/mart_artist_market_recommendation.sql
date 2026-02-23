CREATE OR REPLACE VIEW mart_artist_market_recommendation AS
WITH latest AS (
  SELECT
    artist_key,
    market_key,
    MAX(snapshot_date) AS as_of_date
  FROM fact_artist_market_snapshot
  GROUP BY artist_key, market_key
),
current_snapshot AS (
  SELECT
    s.artist_key,
    s.market_key,
    s.snapshot_date AS as_of_date,
    s.spotify_followers AS demand_level
  FROM latest l
  JOIN fact_artist_market_snapshot s
    ON s.artist_key = l.artist_key
   AND s.market_key = l.market_key
   AND s.snapshot_date = l.as_of_date
),
velocity AS (
  SELECT
    cs.artist_key,
    cs.market_key,
    CASE
      WHEN prev.spotify_followers IS NULL THEN NULL
      ELSE (cs.demand_level - prev.spotify_followers)
    END AS demand_velocity_30d
  FROM current_snapshot cs
  LEFT JOIN LATERAL (
    SELECT s2.spotify_followers
    FROM fact_artist_market_snapshot s2
    WHERE s2.artist_key = cs.artist_key
      AND s2.market_key = cs.market_key
      AND s2.snapshot_date <= cs.as_of_date - INTERVAL '28 days'
    ORDER BY s2.snapshot_date DESC
    LIMIT 1
  ) prev ON TRUE
),
base AS (
  SELECT
    a.artist_key,
    a.artist_name,
    m.market_key,
    m.market_name,
    cs.as_of_date,
    cs.demand_level,
    v.demand_velocity_30d,
    a.primary_super_genre AS super_genre,
    CASE
      WHEN v.demand_velocity_30d IS NULL THEN 'Insufficient history'
      WHEN v.demand_velocity_30d > 0 THEN 'Growing'
      WHEN v.demand_velocity_30d < 0 THEN 'Declining'
      ELSE 'Flat'
    END AS momentum_flag
  FROM current_snapshot cs
  JOIN dim_artist a ON a.artist_key = cs.artist_key
  JOIN dim_market m ON m.market_key = cs.market_key
  LEFT JOIN velocity v
    ON v.artist_key = cs.artist_key
   AND v.market_key = cs.market_key
),
competition AS (
  SELECT
    b.artist_key,
    b.market_key,
    COUNT(*)::INT AS competing_events_next_60d
  FROM base b
  LEFT JOIN fact_market_event e
    ON e.market_key = b.market_key
   AND e.event_datetime >= b.as_of_date
   AND e.event_datetime <  b.as_of_date + INTERVAL '60 days'
   AND e.super_genre = b.super_genre
  GROUP BY b.artist_key, b.market_key
)
SELECT
  -- Keep these in a stable order going forward:
  b.artist_name,
  b.market_name,
  b.demand_level,
  b.demand_velocity_30d,
  b.momentum_flag,

  -- Append new columns below (safe evolution):
  b.super_genre,
  b.as_of_date,
  c.competing_events_next_60d,
  CASE
    WHEN b.demand_velocity_30d IS NULL THEN NULL
    ELSE ROUND((b.demand_velocity_30d::NUMERIC) / (1 + c.competing_events_next_60d), 4)
  END AS tension_score
FROM base b
JOIN competition c
  ON c.artist_key = b.artist_key
 AND c.market_key = b.market_key;