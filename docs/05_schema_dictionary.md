\# 05\_schema\_dictionary.md — Schema Dictionary



\## Purpose

This document defines each table, its grain, and the meaning of each field.

The goal is for someone new to the project to understand the data model quickly and trust the outputs.



---



\## dim\_artist

\*\*Grain:\*\* 1 row per unique artist identity  

\*\*Primary Key:\*\* artist\_key  

\*\*Type:\*\* Dimension (slow-changing)



\### Fields

\- artist\_key: internal surrogate key used for joins

\- artist\_name: display name (not used for identity joins)

\- spotify\_artist\_id: Spotify identifier (nullable, unique)

\- ticketmaster\_attraction\_id: Ticketmaster artist identifier (nullable, unique)

\- musicbrainz\_mbid: MusicBrainz identifier (nullable, unique)

\- primary\_super\_genre: normalized genre bucket used in analytics

\- created\_at, updated\_at: audit timestamps



\*\*Notes / Decisions\*\*

\- Surrogate key avoids reliance on imperfect external IDs.

\- Multiple external IDs supported to improve matching coverage.



---



\## dim\_market

\*\*Grain:\*\* 1 row per canonical market (city/metro/region)  

\*\*Primary Key:\*\* market\_key  

\*\*Type:\*\* Dimension (stable)



\### Fields

\- market\_key: internal primary key

\- market\_name: canonical name (e.g., "New York City")

\- market\_type: city/metro/region (used for rollups)

\- state, country: disambiguation and filtering

\- lat, lon: centroid coordinates for mapping/distance

\- population: optional, supports per-capita normalization

\- parent\_market\_key: optional rollup mapping (e.g., borough → city)

\- created\_at, updated\_at: audit timestamps



\*\*Notes / Decisions\*\*

\- Standardizes geography across data sources.

\- parent\_market\_key enables rollups without hardcoding logic.



---



\## dim\_venue

\*\*Grain:\*\* 1 row per venue (a specific room/building)  

\*\*Primary Key:\*\* venue\_key  

\*\*Type:\*\* Dimension (slow-changing)



\### Fields

\- venue\_key: internal primary key

\- venue\_name: display name

\- ticketmaster\_venue\_id: Ticketmaster venue ID (nullable, unique)

\- market\_key: FK to dim\_market

\- address/city/state/country/postal\_code: location details

\- lat, lon: venue coordinates

\- capacity: seating/attendance capacity (nullable)

\- capacity\_confidence: indicates reliability of capacity value

\- venue\_tier: capacity bucket (useful when capacity is missing)

\- is\_active: handles closures without deleting history

\- created\_at, updated\_at: audit timestamps



\*\*Notes / Decisions\*\*

\- Capacity is a core supply constraint but often incomplete; store confidence + tier.

\- market\_key ensures all venues roll up to canonical markets.



---



\## etl\_run

\*\*Grain:\*\* 1 row per extraction/load run  

\*\*Primary Key:\*\* run\_id  

\*\*Type:\*\* Operational lineage



\### Fields

\- run\_id: primary key

\- source: ticketmaster/spotify/etc.

\- started\_at, finished\_at: run timing

\- status: running/success/failure

\- records\_inserted, records\_updated: basic observability

\- notes: free-form debug notes



\*\*Notes / Decisions\*\*

\- Enables reproducibility: every fact row can be traced back to a run.



---



\## fact\_artist\_market\_snapshot

\*\*Grain:\*\* 1 row per artist × market × snapshot\_date  

\*\*Primary Key:\*\* (artist\_key, market\_key, snapshot\_date)  

\*\*Type:\*\* Fact (append-only time series)



\### Fields

\- artist\_key: FK to dim\_artist

\- market\_key: FK to dim\_market

\- snapshot\_date: date of snapshot measurement

\- spotify\_followers: demand scale proxy

\- spotify\_popularity: demand heat proxy (0–100)

\- spotify\_monthly\_listeners: optional enrichment field (nullable)

\- demand\_index: optional stored composite score (nullable)

\- data\_completeness\_score: 0–1 indicator of missingness

\- run\_id: FK to etl\_run

\- created\_at: audit timestamp



\*\*Notes / Decisions\*\*

\- Composite PK prevents duplicate snapshots for the same day.

\- Append-only supports velocity, breakout detection, and trend analysis.



---



\## fact\_market\_event

\*\*Grain:\*\* 1 row per event instance  

\*\*Primary Key:\*\* ticketmaster\_event\_id  

\*\*Type:\*\* Fact (event calendar)



\### Fields

\- ticketmaster\_event\_id: Ticketmaster event ID

\- event\_name: display name

\- event\_datetime: event timestamp

\- onsale\_datetime: optional onsale date

\- status: onsale/cancelled/postponed/etc.

\- market\_key: FK to dim\_market

\- venue\_key: FK to dim\_venue

\- super\_genre: normalized genre used for competition filtering

\- source: default ticketmaster

\- last\_seen\_at: helps detect removals from feed

\- run\_id: FK to etl\_run

\- ingested\_at: audit timestamp



\*\*Notes / Decisions\*\*

\- Enables competition pressure metrics (events in next 60 days).

\- last\_seen\_at prevents silent disappearance from breaking analytics.



---



\## bridge\_event\_artist

\*\*Grain:\*\* 1 row per event × artist  

\*\*Primary Key:\*\* (ticketmaster\_event\_id, artist\_key)  

\*\*Type:\*\* Bridge (many-to-many)



\### Fields

\- ticketmaster\_event\_id: FK to fact\_market\_event

\- artist\_key: FK to dim\_artist

\- billing\_order: 1=headliner

\- role: headliner/support/festival lineup

\- is\_primary: convenience boolean flag



\*\*Notes / Decisions\*\*

\- Events can have multiple artists; bridge table preserves reality and avoids incorrect one-to-one assumptions.



