\# 07\_mart\_logic.md — Mart Logic (Artist × Market Recommendation)



\## Purpose

`mart\_artist\_market\_recommendation` is the first decision-ready output table.

It summarizes current demand level, short-term momentum, market competition pressure,

and a simple tension score that highlights where growth may be easiest (or hardest).



\*\*Grain:\*\* 1 row per artist × market (as of latest snapshot date).



\## Inputs

\- `fact\_artist\_market\_snapshot` (time-series demand signals)

\- `dim\_artist` (artist identity + primary\_super\_genre)

\- `dim\_market` (market identity)

\- `fact\_market\_event` (event calendar competition)



\## Core Fields



\### demand\_level (followers)

\*\*Definition:\*\* latest `spotify\_followers` value for the artist in that market.

\*\*Interpretation:\*\* overall scale proxy.



\### demand\_velocity\_30d

\*\*Definition:\*\* followers\_today - followers\_30d\_ago

\*\*Interpretation:\*\* momentum proxy. Positive = growing interest; negative = cooling.



\### momentum\_flag

\*\*Definition:\*\*

\- Growing if demand\_velocity\_30d > 0

\- Declining if demand\_velocity\_30d < 0

\- Flat otherwise



\*\*Interpretation:\*\* categorical summary of momentum for quick scanning.



\### competing\_events\_next\_60d

\*\*Definition:\*\* count of events in the same market occurring in the next 60 days.

If genre data exists for both sides, competition is filtered to same `super\_genre`.



\*\*Interpretation:\*\* calendar crowding pressure.



\### tension\_score

\*\*Definition:\*\* demand\_velocity\_30d / (1 + competing\_events\_next\_60d)



\*\*Interpretation:\*\*

\- Higher = momentum with relatively low competition (potential routing opportunity)

\- Lower = momentum suppressed by crowded calendar (harder market)



\## Key Assumptions / Limitations (v0.2)

\- Spotify followers are global and not truly market-specific; market context is inferred.

\- Competition uses event count (and genre filter when available) as a proxy; no ticket sales data.

\- This mart is a first-pass signal, not a prediction model.



\## Verification Checks

\- View returns 1 row per artist × market latest snapshot

\- demand\_velocity\_30d matches manual delta checks on snapshots

\- competing\_events\_next\_60d changes when additional events are inserted into the calendar



