-- ==========================================
-- SEED: Bad Bunny, SZA, Ariana Grande
-- Synthetic test universe for mart validation
-- ==========================================

-- 1️⃣ Insert / Upsert Artists

INSERT INTO dim_artist
(artist_name, spotify_artist_id, ticketmaster_attraction_id, primary_super_genre)
VALUES
  ('Bad Bunny',      'spotify_bad_bunny',      'tm_bad_bunny',      'Latin'),
  ('SZA',            'spotify_sza',            'tm_sza',            'R&B / Soul'),
  ('Ariana Grande',  'spotify_ariana_grande',  'tm_ariana_grande',  'Pop')
ON CONFLICT (spotify_artist_id) DO UPDATE
SET primary_super_genre = EXCLUDED.primary_super_genre,
    updated_at = CURRENT_TIMESTAMP;


-- 2️⃣ Insert Snapshots (30 days ago)

INSERT INTO fact_artist_market_snapshot
(artist_key, market_key, snapshot_date, spotify_followers, spotify_popularity)
SELECT
  a.artist_key,
  m.market_key,
  CURRENT_DATE - INTERVAL '30 days',
  followers,
  popularity
FROM (
  SELECT 'Bad Bunny' AS artist_name, 69000000 AS ny, 68800000 AS la, 68500000 AS chi, 92 AS popularity
  UNION ALL
  SELECT 'SZA', 28000000, 27900000, 27800000, 90
  UNION ALL
  SELECT 'Ariana Grande', 85000000, 84800000, 84500000, 97
) d
JOIN dim_artist a ON a.artist_name = d.artist_name
JOIN dim_market m ON m.market_key IN (1,2,3)
CROSS JOIN LATERAL (
  SELECT CASE m.market_key
    WHEN 1 THEN d.ny
    WHEN 2 THEN d.la
    ELSE d.chi
  END AS followers
) f
ON CONFLICT (artist_key, market_key, snapshot_date) DO UPDATE
SET spotify_followers = EXCLUDED.spotify_followers;

-- 3️⃣ Insert Snapshots (Today)

INSERT INTO fact_artist_market_snapshot
(artist_key, market_key, snapshot_date, spotify_followers, spotify_popularity)
SELECT
  a.artist_key,
  m.market_key,
  CURRENT_DATE,
  followers,
  popularity
FROM (
  SELECT 'Bad Bunny' AS artist_name, 70500000 AS ny, 70300000 AS la, 70000000 AS chi, 93 AS popularity
  UNION ALL
  SELECT 'SZA', 29200000, 29100000, 28900000, 92
  UNION ALL
  SELECT 'Ariana Grande', 86000000, 85800000, 85500000, 98
) d
JOIN dim_artist a ON a.artist_name = d.artist_name
JOIN dim_market m ON m.market_key IN (1,2,3)
CROSS JOIN LATERAL (
  SELECT CASE m.market_key
    WHEN 1 THEN d.ny
    WHEN 2 THEN d.la
    ELSE d.chi
  END AS followers
) f
ON CONFLICT (artist_key, market_key, snapshot_date) DO UPDATE
SET spotify_followers = EXCLUDED.spotify_followers;


-- 4️⃣ Insert Competition Events (Next 60 Days)

INSERT INTO fact_market_event
(ticketmaster_event_id, event_name, event_datetime, market_key, venue_key, super_genre)
VALUES
  ('EVT_LATIN_NYC_01',  'Latin Night NYC',      CURRENT_DATE + INTERVAL '10 days', 1, 1, 'Latin'),
  ('EVT_LATIN_NYC_02',  'Reggaeton Bash NYC',   CURRENT_DATE + INTERVAL '20 days', 1, 1, 'Latin'),

  ('EVT_RNB_LA_01',     'R&B Soul Fest LA',     CURRENT_DATE + INTERVAL '15 days', 2, 2, 'R&B / Soul'),

  ('EVT_POP_CHI_01',    'Pop Arena Chicago',    CURRENT_DATE + INTERVAL '25 days', 3, 3, 'Pop')
ON CONFLICT (ticketmaster_event_id) DO NOTHING;