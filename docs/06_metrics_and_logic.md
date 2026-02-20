\# 06\_metrics\_and\_logic.md — Metrics and Business Logic



\## Purpose

Define the meaning of the metrics used in marts and dashboards, including assumptions and interpretation.



---



\## Core Metrics (v0.x)



\### demand\_level

\*\*Field:\*\* demand\_level (followers)  

\*\*Definition:\*\* latest spotify\_followers for the artist-market pair (from latest snapshot).  

\*\*Interpretation:\*\* scale proxy (bigger base audience).



\### demand\_velocity\_30d

\*\*Field:\*\* demand\_velocity\_30d  

\*\*Definition:\*\* followers\_today - followers\_30d\_ago  

\*\*Interpretation:\*\* momentum proxy (breakout signal).



\*\*Limitations (v0.1):\*\*

\- Requires snapshots exactly on CURRENT\_DATE and CURRENT\_DATE-30 days.

\- In v1, compute using nearest snapshot within a window (e.g., nearest >= 28 days ago).



\### momentum\_flag

\*\*Definition:\*\*

\- Growing if demand\_velocity\_30d > 0

\- Declining if demand\_velocity\_30d < 0

\- Flat otherwise



\*\*Interpretation:\*\* quick categorical summary.



---



\## Competition Metrics (v0.2 target)



\### competing\_events\_next\_60d

\*\*Definition:\*\* count of events in the same market occurring between today and today+60 days.  

\*\*Optional filter:\*\* same super\_genre as the artist.



\*\*Interpretation:\*\* calendar crowding / competing supply proxy.



---



\## Composite Opportunity Metric (v0.2 target)



\### tension\_score

\*\*Definition:\*\* demand\_velocity\_30d / (1 + competing\_events\_next\_60d)



\*\*Interpretation:\*\*

\- Higher: momentum with relatively low competition → potential routing opportunity

\- Lower: momentum suppressed by crowded calendar → harder to win attention



\*\*Notes:\*\*

\- +1 avoids division-by-zero.

\- This is not a “prediction”; it’s an interpretable signal.



---



\## Planned Enhancements (v1+)



\### Demand Index (0–100)

A weighted composite of:

\- followers (scale)

\- popularity (heat)

\- velocity (momentum)

Optionally:

\- touring intensity (artist supply-side)

\- market normalization



\### Venue right-sizing

Rule-based recommendation using:

\- demand\_index and/or demand\_level

\- venue capacity tiers

Goal:

\- flag likely under-scaled / over-scaled bookings



---



\## Assumptions and Constraints

\- No direct ticket sales data; proxies used (followers/popularity, capacity, event density).

\- Spotify signals are global; market context inferred via competition + venue supply.

\- Genre normalization trades granularity for interpretability.



