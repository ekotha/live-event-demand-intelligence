# Metrics Definition Document

## Purpose

Define the meaning, calculation logic, assumptions, and interpretation of all metrics used in marts and dashboards.

This document ensures:

- Metrics are reproducible
- Assumptions are explicit
- Interpretations are consistent
- Future enhancements do not break semantic meaning

---

## Core Mart: `mart_artist_market_recommendation`

### Grain

One row per `(artist, market)` representing the most recent snapshot available for that artist-market pair.

This mart is designed to support routing and scheduling decisions.

---

## Core Metrics (v0.2)

### `demand_level`

| Field | Source |
|---|---|
| `demand_level` | `fact_artist_market_snapshot.spotify_followers` |

**Definition:** Spotify followers from the most recent snapshot (`as_of_date`) for an artist-market pair.

**Interpretation:** Proxy for baseline audience size in that market. Higher = larger established audience base.

**Limitations:**
- Follower counts are a demand proxy, not ticket purchase data.
- Does not account for engagement quality or ticket conversion rate.

---

### `as_of_date`

**Definition:** The latest available `snapshot_date` for an artist-market pair.

**Purpose:** Ensures calculations are anchored to the most recent observed data rather than system date (`CURRENT_DATE`).

This makes the mart robust to:
- Weekly snapshot cadence
- Backfills
- Historical simulations

---

### `demand_velocity_30d`

**Definition (v0.2 implementation):**

```
demand_level (most recent snapshot)
- demand_level (most recent snapshot at or before as_of_date - 28 days)
```

This uses a windowed lookback rather than requiring an exact 30-day match.

**Interpretation:** Momentum proxy (breakout signal).
- Positive → accelerating interest
- Negative → cooling demand
- `NULL` → insufficient historical data

> **Why 28 days instead of exactly 30?**
> To accommodate weekly snapshot cadence and avoid brittle date equality logic.

**Limitations:**
- Sensitive to snapshot frequency
- Measures follower growth, not ticket conversion

---

### `momentum_flag`

**Definition:**

| Value | Condition |
|---|---|
| `Growing` | `demand_velocity_30d > 0` |
| `Declining` | `demand_velocity_30d < 0` |
| `Flat` | `demand_velocity_30d = 0` |
| `Insufficient history` | velocity is `NULL` |

**Interpretation:** Quick categorical summary for dashboards and executive views.

---

## Competition Metrics (v0.2)

### `competing_events_next_60d`

**Definition:** Count of events in the same market where:
- `event_datetime >= as_of_date`
- `event_datetime < as_of_date + 60 days`
- `event.super_genre = artist.super_genre`

**Interpretation:** Calendar crowding / competing supply proxy. Higher = more near-term competition for the same audience segment.

**Design Choice:** Genre matching is strict. If either side has `NULL` genre, events are not counted. This favors conservative competition estimation.

**Limitations:**
- Assumes `super_genre` is sufficient proxy for audience overlap
- Does not account for venue capacity or event scale
- Does not model exact date collision (only 60-day window density)

---

## Composite Opportunity Metric (v0.2)

### `tension_score`

**Definition:**

```
demand_velocity_30d / (1 + competing_events_next_60d)
```

> **Why +1?** Avoids division-by-zero and ensures velocity is preserved when competition = 0.

**Interpretation:**
- Higher → strong momentum with relatively low competition
- Lower → momentum diluted by crowded calendar
- Negative → declining demand under competition

> This is **not a predictive model**. It is an interpretable routing signal.

---

## Business Interpretation

The mart answers:

> *"Where is this artist gaining demand, and where is that growth least suppressed by competing supply?"*

It intentionally separates:
- **Scale** (`demand_level`)
- **Momentum** (`demand_velocity_30d`)
- **Supply pressure** (`competing_events_next_60d`)

And combines only the latter two for opportunity scoring.

---

## Planned Enhancements (v1+)

### Demand Index (0–100)

Weighted composite of:
- Normalized followers (scale)
- Popularity score (if ingested)
- Velocity (momentum)

Optional extensions:
- Touring intensity (artist supply-side saturation)
- Market normalization (market population scaling)

**Goal:** Produce a comparable cross-artist score.

---

### Venue Right-Sizing

Rule-based recommendation layer combining:
- `demand_level` or `demand_index`
- Venue capacity tiers
- Historical routing patterns

**Goal:**
- Flag likely under-scaled bookings
- Flag over-scaled risk
- Recommend capacity band

---

### Competition Weighting

Future iterations may weight competition by:
- Venue capacity
- Event scale
- Headliner strength
- Exact date overlap

Rather than simple event count.

---

## Assumptions and Constraints

- No direct ticket sales data available (followers used as proxy).
- Spotify data is global; market context is inferred via competition + venue supply.
- Super-genre normalization reduces granularity for interpretability.
- Metrics are directional signals, not forecasts.

---

## Versioning

| Version | Changes |
|---|---|
| v0.1 | Basic level + velocity |
| v0.2 | Adds competition + `tension_score` |
| v1+ | Adds venue optimization + composite demand index |
