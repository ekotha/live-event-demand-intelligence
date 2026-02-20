CREATE TABLE IF NOT EXISTS dim_artist (
  artist_key SERIAL PRIMARY KEY,
  artist_name TEXT NOT NULL,
  spotify_artist_id TEXT UNIQUE,
  ticketmaster_attraction_id TEXT UNIQUE,
  musicbrainz_mbid TEXT UNIQUE,
  primary_super_genre TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dim_market (
  market_key SERIAL PRIMARY KEY,
  market_name TEXT NOT NULL,
  market_type TEXT DEFAULT 'city',
  state TEXT,
  country TEXT DEFAULT 'USA',
  lat NUMERIC(9,6),
  lon NUMERIC(9,6),
  population BIGINT,
  parent_market_key INT REFERENCES dim_market(market_key),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dim_venue (
  venue_key SERIAL PRIMARY KEY,
  venue_name TEXT NOT NULL,
  ticketmaster_venue_id TEXT UNIQUE,
  market_key INT NOT NULL REFERENCES dim_market(market_key),
  address TEXT,
  city TEXT,
  state TEXT,
  country TEXT DEFAULT 'USA',
  postal_code TEXT,
  lat NUMERIC(9,6),
  lon NUMERIC(9,6),
  capacity INT,
  capacity_confidence TEXT DEFAULT 'unknown',
  venue_tier TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS etl_run (
  run_id BIGSERIAL PRIMARY KEY,
  source TEXT NOT NULL,
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  finished_at TIMESTAMP,
  status TEXT DEFAULT 'running',
  records_inserted INT DEFAULT 0,
  records_updated INT DEFAULT 0,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS fact_artist_market_snapshot (
  artist_key INT NOT NULL REFERENCES dim_artist(artist_key),
  market_key INT NOT NULL REFERENCES dim_market(market_key),
  snapshot_date DATE NOT NULL,
  spotify_followers BIGINT,
  spotify_popularity INT,
  spotify_monthly_listeners BIGINT,
  demand_index NUMERIC(6,2),
  data_completeness_score NUMERIC(4,2),
  run_id BIGINT REFERENCES etl_run(run_id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (artist_key, market_key, snapshot_date)
);

CREATE TABLE IF NOT EXISTS fact_market_event (
  ticketmaster_event_id TEXT PRIMARY KEY,
  event_name TEXT,
  event_datetime TIMESTAMP,
  onsale_datetime TIMESTAMP,
  status TEXT,
  market_key INT REFERENCES dim_market(market_key),
  venue_key INT REFERENCES dim_venue(venue_key),
  super_genre TEXT,
  source TEXT DEFAULT 'ticketmaster',
  last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  run_id BIGINT REFERENCES etl_run(run_id),
  ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bridge_event_artist (
  ticketmaster_event_id TEXT REFERENCES fact_market_event(ticketmaster_event_id),
  artist_key INT REFERENCES dim_artist(artist_key),
  billing_order INT,
  role TEXT,
  is_primary BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (ticketmaster_event_id, artist_key)
);

-- Helpful indexes for time windows / joins
CREATE INDEX IF NOT EXISTS idx_event_market_datetime ON fact_market_event (market_key, event_datetime);
CREATE INDEX IF NOT EXISTS idx_snapshot_market_date ON fact_artist_market_snapshot (market_key, snapshot_date);
CREATE INDEX IF NOT EXISTS idx_snapshot_artist_date ON fact_artist_market_snapshot (artist_key, snapshot_date);
