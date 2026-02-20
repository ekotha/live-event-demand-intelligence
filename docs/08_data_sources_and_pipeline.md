\# 07\_data\_sources\_and\_pipeline.md — Data Sources and Pipeline



\## Purpose

Describe where data comes from, how it is stored, and how it becomes decision-ready marts.



---



\## Data Sources (planned)



\### Ticketmaster (events + venues + attractions)

Primary use:

\- event calendar (competition pressure)

\- venue references (market + venue identity)

\- artist "attraction" IDs for linking events to artists



Typical objects used:

\- Event (id, name, dates, status, venue, classifications)

\- Venue (id, name, address, location)

\- Attraction/Artist (id, name)



Notes:

\- Requires API key.

\- Event feeds change; handle cancellations and removals.



\### Spotify (artist metrics)

Primary use:

\- followers (scale)

\- popularity (heat)

\- genre tags (input for normalization)



Notes:

\- Requires OAuth client credentials.

\- Followers and popularity are global metrics.



---



\## Storage Layers



\### Dimensions (stable anchors)

\- dim\_artist, dim\_market, dim\_venue



\### Facts (append-heavy / time-based)

\- fact\_artist\_market\_snapshot (weekly append)

\- fact\_market\_event (event feed refresh)

\- bridge\_event\_artist (many-to-many)



\### Marts (BI-ready outputs)

\- mart\_artist\_market\_recommendation (v0.1 → v1)

\- (future) market summaries, capacity alignment, routing views



---



\## Pipeline Steps (planned)



\### Step 1 — Extract

\- Pull Ticketmaster events (date range, markets of interest)

\- Pull Spotify artist metrics (for tracked artists)



\### Step 2 — Load

\- Upsert dims (artists, venues) based on external IDs where possible

\- Append facts (snapshots weekly; events refreshed)



\### Step 3 — Transform

\- Normalize genres via dim\_genre\_map

\- Build marts using SQL views or materialized tables



\### Step 4 — Validate

\- Run sql/tests scripts:

&nbsp; - uniqueness and row count checks

&nbsp; - non-null checks where expected

&nbsp; - sanity checks on deltas



---



\## Refresh Cadence (planned)

\- Ticketmaster events: daily or weekly refresh

\- Spotify metrics: weekly snapshot append

\- Marts: rebuild on refresh (view or materialized refresh)



---



\## Known Risks

\- ID matching between Ticketmaster and Spotify may require fuzzy matching + confidence scoring.

\- Some venues lack capacity; use tier + confidence field.



