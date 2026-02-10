# The Watchlist - ResearchBuddy

## Purpose

ResearchBuddy is an on-demand research agent embedded in admin entity forms. It queries anime/manga APIs, feeds the results through a Groq LLM, and auto-populates form fields — reducing manual data entry for franchises and entries.

---

## Architecture

```
User types query in admin form
  → API sources fetched in parallel (Jikan, AniList, TVDB, Serper)
  → Results serialized to TOON format (token-reduced)
  → Sent to Groq LLM with entity-specific prompt
  → LLM returns structured JSON
  → Form fields auto-populated
```

---

## Handler Types

| Handler | File | Sources | Use Case |
|---------|------|---------|----------|
| `franchise-anime` | `handlers/franchise-anime.ts` | AniList + Jikan + Google Images | Franchise form research |
| `entry-anime-series` | `handlers/entry-anime-series.ts` | AniList + Jikan + TVDB seasons | Entry form (anime series) |
| `entry-anime-movie` | `handlers/entry-anime-movie.ts` | AniList + Jikan | Entry form (anime movie) |
| `character-anime` | `handlers/character-anime.ts` | AniList + Jikan (character detail) | Character form (anime/manga) |
| `creator-anime` | `handlers/creator-anime.ts` | AniList + Jikan + Wikipedia | Creator form research |
| `product-anime-figure` | `handlers/product-anime-figure.ts` | MFC (Playwright scraping) | Product form research (anime figures) |

---

## Two-Stage Flow (Entries)

Anime series and anime movie entries use a two-stage research flow:

1. **Stage 1 — Title Search**: User types a query → API returns matching titles → displayed in `TitlePickerDialog`
2. **Stage 2 — Full Research**: User picks a title → full research runs with that specific title → form populated

Stage 1 API routes:
- `POST /api/admin/research/entry-anime-series` — TVDB search, sorted by string similarity
- `POST /api/admin/research/entry-anime-movies` — AniList movie search

Stage 2 API route:
- `POST /api/admin/research/entry` — Full research with handler dispatch

Character research also uses a two-stage flow:
- `POST /api/admin/research/character-anime` — AniList + Jikan character search, deduplicated
- `POST /api/admin/research/character` — Full character research with handler dispatch

Creator research also uses a two-stage flow:
- `POST /api/admin/research/creator-anime` — AniList Staff + Jikan People search, deduplicated
- `POST /api/admin/research/creator` — Full creator research with handler dispatch

Product research (anime figures) is single-stage — user pastes an MFC URL:
- `POST /api/admin/research/product` — Extracts MFC ID from URL, Playwright scrapes detail page, handler dispatch
- MFC search scraping was abandoned due to Cloudflare blocking. User finds the item on MFC manually.

Franchise research is single-stage (search bar → immediate research).

---

## Data Sources

| Source | File | API | Data Provided |
|--------|------|-----|---------------|
| Jikan | `sources/anime/jikan.ts` | MyAnimeList (REST) | Titles, synopsis, images, air dates |
| AniList | `sources/anime/anilist.ts` | AniList (GraphQL) | Titles, description, images, start dates |
| AniList Movies | `sources/anime/anilist-movies.ts` | AniList (GraphQL) | Movie-specific title search |
| TVDB Seasons | `sources/tvdb.ts` | TVDB v4 | Season names, episode air dates, English translations |
| TVDB Search | `sources/tvdb-search.ts` | TVDB v4 | Series title search for picker |
| Google Images | `sources/google-images.ts` | Serper.dev | Franchise logo images (top 12) |
| Wikipedia | `sources/wikipedia-person.ts` | Wikipedia REST (free) | Person summaries, thumbnails |
| MFC | `sources/mfc/mfc-search.ts`, `sources/mfc/mfc-detail.ts` | MyFigureCollection (HTML scraping) | Figure names, manufacturers, series, characters, release dates, images, JAN codes |

---

## TOON Format

Token-Oriented Object Notation (`lib/research/toon.ts`) is a custom serialization format that reduces token count by ~50-60% compared to JSON. Used to compress source data before sending to the LLM.

Format:
```
name[count]{key1,key2,key3}:
value1,value2,value3
value4,value5,value6
```

This keeps API costs low while providing the LLM with all available context.

---

## Prompt Files

| File | Purpose |
|------|---------|
| `prompts/franchise-anime.ts` | System prompt + model config for franchise research |
| `prompts/entry-anime-series.ts` | System prompt + model config for anime series entries |
| `prompts/entry-anime-movie.ts` | System prompt + model config for anime movie entries |
| `prompts/character-anime.ts` | System prompt + model config for anime/manga characters |
| `prompts/creator-anime.ts` | System prompt + model config for anime/manga creators. Includes DB role names for work filtering. |
| `prompts/product-anime-figure.ts` | System prompt + model config for anime figures. Includes DB category/subcategory/manufacturer names for mapping. |

### Why prompts are intentionally duplicated

Each prompt file is custom-tailored to a specific combination of:
- **Database level**: franchise vs entry (different output fields)
- **Medium category**: anime series vs anime movie (different data sources, different LLM instructions)

The data sources, expected fields, and LLM instructions differ per combination. **Do not consolidate them into a generic template.**

---

## Franchise Auto-Population (Characters)

When character research runs, the Groq prompt returns a `franchiseName` field derived from AniList `media_titles` and Jikan `anime_titles`. The character form fuzzy-matches this against existing franchises (case-insensitive `startsWith` in both directions) and auto-selects the match — only if no franchise is already selected. This avoids overriding intentional user choices.

---

## Creator Works Auto-Population

When creator research returns, Groq maps raw AniList/Jikan credit strings to the site's CreatorRole names (fetched from DB and injected into the prompt). The form fuzzy-matches returned work titles against all DB entries and exact-matches role names against CreatorRole options, auto-populating the entries panel. Only high-profile roles are tracked (Director, Author, etc.) since the site focuses on creators users would follow for watchlist purposes.

---

## Product Research (Anime Figures)

MFC has no public API — product research uses server-side HTML scraping with a browser User-Agent. The Groq prompt receives DB category names, subcategory names, and manufacturer names so it can map MFC's classification/company fields to exact DB values. Franchise and character names are returned as free-text for client-side fuzzy matching. This approach is inherently brittle (MFC redesigns could break selectors) but MFC is the most comprehensive anime figure database available.

---

## Design Decisions

- **Handlers are separate per type**: Each handler orchestrates different source combinations and returns different result shapes. A generic handler would add complexity without reducing code.
- **TOON over JSON**: Reduces token usage by 50-60%, directly lowering Groq API costs. The LLM handles TOON just fine.
- **Graceful degradation**: Optional API keys (TVDB, Serper) — sources skip silently if keys are missing. Research still works with just Jikan + AniList.
- **Promise.allSettled**: Sources are fetched in parallel. One failure doesn't block others; warnings are collected and surfaced.

---

## Constants (`lib/research/constants.ts`)

| Constant | Value | Description |
|----------|-------|-------------|
| `API_TIMEOUT` | 10s | Timeout for external API calls |
| `LLM_TIMEOUT` | 30s | Timeout for Groq LLM calls |
| `MAX_DESCRIPTION_LENGTH` | 500 | Max characters for descriptions |
| `LLM_TEMPERATURE` | 0.1 | Low temperature for deterministic output |
| `FRANCHISE_MAX_TOKENS` | 1024 | Max tokens for franchise research |
| `ENTRY_MAX_TOKENS` | 1536 | Max tokens for entry research |
| `CHARACTER_MAX_TOKENS` | 1024 | Max tokens for character research |
| `CREATOR_MAX_TOKENS` | 2048 | Max tokens for creator research (larger due to works array) |
| `PRODUCT_MAX_TOKENS` | 2048 | Max tokens for product research |
| `ANIME_RESULTS_PER_SOURCE` | 3 | Results to keep per source |
| `JIKAN_RESULTS_LIMIT` | 5 | Max results from Jikan API |

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GROQ_API_KEY` | Yes | Groq LLM API key |
| `TVDB_API_KEY` | No | TVDB v4 API key (enables season data for anime series) |
| `SERPER_API_KEY` | No | Serper.dev API key (enables Google Images logo search) |
