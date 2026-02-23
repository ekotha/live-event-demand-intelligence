CREATE OR REPLACE VIEW mart_artist_market_recommendation AS
WITH latest AS (
  SELECT
    artist_key,
    market_key,
    MAX(snapshot_date) AS as_of_date
  FROM fact_artist_market_snapshot
  GROUP BY artist_key, market_key
),

-- Latest snapshot row for each artist/market pair
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

-- Join dims and define genre + momentum off the current snapshot
base AS (
  SELECT
    a.artist_key,
    a.artist_name,
    a.primary_super_genre AS super_genre,
    m.market_key,
    m.market_name,
    cs.as_of_date,
    cs.demand_level
  FROM current_snapshot cs
  JOIN dim_artist a
    ON a.artist_key = cs.artist_key
  JOIN dim_market m
    ON m.market_key = cs.market_key
),

-- Robust velocity: use closest snapshot at or before (as_of_date - 28 days)
velocity AS (
  SELECT
    b.artist_key,
    b.market_key,
    (b.demand_level - prev.spotify_followers) AS demand_velocity_30d
  FROM base b
  JOIN LATERAL (
    SELECT s2.spotify_followers
    FROM fact_artist_market_snapshot s2
    WHERE s2.artist_key = b.artist_key
      AND s2.market_key = b.market_key
      AND s2.snapshot_date <= (b.as_of_date - INTERVAL '28 days')
    ORDER BY s2.snapshot_date DESC
    LIMIT 1
  ) prev ON TRUE
),

-- Competition in next 60 days, same market and same super genre
competition AS (
  SELECT
    b.artist_key,
    b.market_key,
    COUNT(e.ticketmaster_event_id)::INT AS competing_events_next_60d
  FROM base b
  LEFT JOIN fact_market_event e
    ON e.market_key = b.market_key
   AND e.event_datetime >= b.as_of_date
   AND e.event_datetime <  (b.as_of_date + INTERVAL '60 days')
   AND LOWER(TRIM(e.super_genre)) = LOWER(TRIM(b.super_genre))
  GROUP BY b.artist_key, b.market_key
)

SELECT
  -- Canonical / stable column order for BI use
  b.artist_name,
  b.market_name,
  b.super_genre,
  b.as_of_date,
  b.demand_level,
  v.demand_velocity_30d,
  c.competing_events_next_60d,
  ROUND(
    (v.demand_velocity_30d::NUMERIC) / (1 + c.competing_events_next_60d),
    4
  ) AS tension_score,
  CASE
    WHEN v.demand_velocity_30d > 0 THEN 'Growing'
    WHEN v.demand_velocity_30d < 0 THEN 'Declining'
    ELSE 'Flat'
  END AS momentum_flag
FROM base b
JOIN velocity v
  ON v.artist_key = b.artist_key
 AND v.market_key = b.market_key
JOIN competition c
  ON c.artist_key = b.artist_key
 AND c.market_key = b.market_key;