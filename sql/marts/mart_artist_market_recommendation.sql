CREATE OR REPLACE VIEW mart_artist_market_recommendation AS
WITH latest AS (
    SELECT
        artist_key,
        market_key,
        MAX(snapshot_date) AS latest_date
    FROM fact_artist_market_snapshot
    GROUP BY artist_key, market_key
),
snapshots AS (
    SELECT
        s.artist_key,
        s.market_key,
        s.snapshot_date,
        s.spotify_followers
    FROM fact_artist_market_snapshot s
),
velocity AS (
    SELECT
        a.artist_key,
        m.market_key,
        MAX(CASE WHEN s.snapshot_date = CURRENT_DATE THEN s.spotify_followers END)
        -
        MAX(CASE WHEN s.snapshot_date = CURRENT_DATE - INTERVAL '30 days'
                 THEN s.spotify_followers END)
        AS followers_30d_delta
    FROM fact_artist_market_snapshot s
    JOIN dim_artist a ON s.artist_key = a.artist_key
    JOIN dim_market m ON s.market_key = m.market_key
    GROUP BY a.artist_key, m.market_key
)
SELECT
    a.artist_name,
    m.market_name,
    s.spotify_followers AS demand_level,
    v.followers_30d_delta AS demand_velocity_30d,
    CASE
        WHEN v.followers_30d_delta > 0 THEN 'Growing'
        WHEN v.followers_30d_delta < 0 THEN 'Declining'
        ELSE 'Flat'
    END AS momentum_flag
FROM latest l
JOIN fact_artist_market_snapshot s
    ON s.artist_key = l.artist_key
    AND s.market_key = l.market_key
    AND s.snapshot_date = l.latest_date
JOIN velocity v
    ON s.artist_key = v.artist_key
    AND s.market_key = v.market_key
JOIN dim_artist a ON s.artist_key = a.artist_key
JOIN dim_market m ON s.market_key = m.market_key;
