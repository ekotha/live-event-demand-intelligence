\# 04\_genre\_taxonomy.md — Genre Taxonomy and Normalization



\## Purpose

This project ingests genre labels from multiple sources (Spotify, Ticketmaster). Those labels are messy:

\- Spotify returns many micro-genres (e.g., "indie pop", "bedroom pop", "alt z").

\- Ticketmaster provides segment/genre/subgenre that can be inconsistent or missing.



To keep analysis and dashboards readable, we normalize raw genres into a small set of \*\*Super Genres\*\*.



\## Canonical Super Genres (v1)

1\. Pop

2\. Hip-Hop / Rap

3\. R\&B / Soul

4\. Rock / Alt

5\. Electronic / Dance

6\. Country / Americana

7\. Latin

8\. Indie / Folk

9\. Metal / Hardcore

10\. Jazz / Blues

11\. Other / Specialty



These are the only genres used for:

\- Competition filtering (same-genre events)

\- Market summaries (market heat by super genre)

\- Artist profile grouping



\## Data Model

Normalization is handled by a mapping table:



**\*\*dim\_genre\_map\*\***

\- raw\_genre (text)

\- source (spotify | ticketmaster)

\- super\_genre (text)

\- confidence (high | medium | low)

\- notes (text)



Raw source genres are stored in the underlying tables (e.g., event genre, spotify genres), and the mapping table is applied during transformation to marts.



\## Mapping Rules (v1)



\### Spotify → Super Genre (rule-based)

Spotify often returns multiple genre strings per artist. We choose a \*\*primary super genre\*\* per artist.



\*\*Primary super genre selection:\*\*

1\) Map each Spotify genre string to a super genre using dim\_genre\_map (or rule patterns).

2\) Prefer mappings with confidence = high.

3\) If multiple match, choose the most frequent / strongest match (or the first high-confidence match).

4\) If no match, set super genre to "Other / Specialty".



\### Ticketmaster → Super Genre

Ticketmaster may provide:

\- segment

\- genre

\- subGenre



Mapping priority:

1\) subGenre (if present)

2\) genre

3\) segment

4\) else "Other / Specialty"



\## Confidence

Confidence communicates reliability of the mapping.



\- high: unambiguous mapping (e.g., "hip hop", "country", "latin", "edm")

\- medium: common but sometimes ambiguous (e.g., "alternative", "indie")

\- low: vague or overloaded labels (e.g., "miscellaneous", "variety")



Confidence can be used to reduce recommendation confidence.



\## Examples (seed-style)

| source     | raw\_genre              | super\_genre           | confidence |

|------------|------------------------|-----------------------|------------|

| spotify    | dance pop              | Pop                   | high       |

| spotify    | trap                   | Hip-Hop / Rap         | high       |

| spotify    | neo soul               | R\&B / Soul            | high       |

| spotify    | indie rock             | Rock / Alt            | medium     |

| spotify    | indie folk             | Indie / Folk          | high       |

| spotify    | techno                 | Electronic / Dance    | high       |

| ticketmaster | Dance/Electronic     | Electronic / Dance    | high       |

| ticketmaster | Hip-Hop/Rap           | Hip-Hop / Rap         | high       |

| ticketmaster | Rock                  | Rock / Alt            | high       |

| ticketmaster | Miscellaneous         | Other / Specialty     | low        |



\## Known Limitations (v1)

\- Artists can belong to multiple genres; v1 uses a single primary super genre.

\- Some genres require context (e.g., "alternative" can span rock/pop).

\- Festival/multi-artist events may not map cleanly.



Future improvement:

\- multi-label genre assignment with weights.



\## Implementation Note (v1)

In early sprints, `dim\_artist.primary\_super\_genre` is treated as the canonical super genre for the artist, and `fact\_market\_event.super\_genre` is treated as the canonical super genre for events.



In later sprints, both fields should be populated via `dim\_genre\_map` (or equivalent transformation logic), so marts do not rely on manual or seed-only labels.

