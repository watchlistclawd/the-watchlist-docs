# The Watchlist — Data Rules & Mental Framework

Master reference for how the database schema applies across all mediums.
This is the source of truth for data gathering, synthesis, and loading.

---

## Core Hierarchy

```
Franchise (IP/brand umbrella)
  └── Entry (conceptual work — the art itself, not a product)
       └── Product (purchasable item — physical or digital)
```

- **Franchises** tie everything together for user discovery
- **Entries** are the creative works themselves
- **Products** are things you can buy

---

## What Is an Entry?

An entry is a **single conceptual work**. Not a season. Not a volume. Not a pressing.

### Entry Rules by Medium

| Medium | What counts as ONE entry | Notes |
|--------|--------------------------|-------|
| **Anime (TV series)** | The entire serialized show (all seasons/episodes) | AniList/MAL split by season — we CONSOLIDATE. Seasons go in `entry_seasons`. |
| **Anime (Movie)** | Each movie is its own entry | Even if it's a direct continuation of a TV series (e.g., Mugen Train) |
| **Anime (OVA)** | Each standalone OVA is its own entry | Some OVAs are a few episodes — still one entry |
| **Manga** | The entire serialized run (all volumes/chapters) | Berserk = one entry. Individual volumes are products. |
| **Manhua/Manhwa** | Same as manga | Entire serialized run = one entry |
| **Comics** | TBD — likely per run/series | Need to define: is "Batman" one entry or is each run separate? |
| **Novel** | Each book is its own entry | Harry Potter 1, Harry Potter 2 = separate entries |
| **Light Novel** | Each book/series TBD | May treat full series as one entry (like manga) — needs decision |
| **Movie (Hollywood)** | Each movie is its own entry | Mad Max, Mad Max 2 = separate entries under same franchise |
| **TV Show (Hollywood)** | The entire serialized show (all seasons) | The Bear = one entry. Seasons in `entry_seasons`. |
| **Video Game** | Each game is its own entry | Fallout 4, Fallout: New Vegas = separate entries. DLC = product-level. |
| **Music Album** | Each album or single is its own entry | Tracks belong to the entry. |
| **Music Single** | Each single is its own entry | Treat as mini-album (a few tracks). Same architecture. |
| **Board Game** | Each game is its own entry | Expansions TBD (product-level or separate entry?) |

### Music: Tracks vs Products

- **Tracks** (`music_tracks`) belong to the **entry** (the conceptual album)
- **Track ordering** (`product_tracks`) belongs to the **product** (the specific release)
- Different releases have different track lists:
  - Walmart exclusive may have bonus tracks
  - iTunes version may have different bonus tracks
  - Japanese pressing may have different track order + obi strip
- ALL tracks from ALL releases are tied to the entry
- Track SPECIFICS (disc number, track number, bonus status) are tied to the product via `product_tracks`

---

## Seasons & Episodes (TV/Anime)

- `entry_seasons` stores seasons within an entry
- `season_episodes` stores episodes within a season
- Season numbering follows TVDB normalization (not Japanese broadcast numbering)
- For anime: AniList/MAL treat each season as a separate listing — we must consolidate

### Consolidation Rules (Anime)

When fetching from AniList/MAL:
1. Find the "root" anime (first season)
2. Follow SEQUEL relations to find continuation seasons
3. Group all TV sequels into ONE entry with multiple seasons
4. **Movies** stay as SEPARATE entries (even direct continuations)
5. **OVAs** stay as SEPARATE entries
6. **Specials** — case by case, generally separate entries
7. The **manga source** is a separate entry (different medium)
8. All entries link to the same franchise

### Example: Demon Slayer

**Franchise:** Demon Slayer: Kimetsu no Yaiba
- **Entry 1 (anime-series):** Demon Slayer: Kimetsu no Yaiba
  - Season 1: Unwavering Resolve (26 eps, Spring 2019)
  - Season 2: Mugen Train Arc + Entertainment District Arc (18 eps, Fall 2021)
  - Season 3: Swordsmith Village Arc (11 eps, Spring 2023)
  - Season 4: Hashira Training Arc (8 eps, Spring 2024)
- **Entry 2 (anime-movie):** Demon Slayer: Mugen Train (2020)
- **Entry 3 (manga):** Demon Slayer: Kimetsu no Yaiba (manga, 23 volumes)

### Example: Little Witch Academia

**Franchise:** Little Witch Academia
- **Entry 1 (anime-movie/ova):** Little Witch Academia (2013 OVA)
- **Entry 2 (anime-movie/ova):** Little Witch Academia: The Enchanted Parade (2015 OVA)
- **Entry 3 (anime-series):** Little Witch Academia (2017 TV series, 25 eps)

---

## Franchises

- Top-level grouping for related entries across media types
- Can be hierarchical via `parent_id` (e.g., "Guardians of the Galaxy" → "MCU" → "Marvel")
- Characters belong to a primary franchise
- An entry can belong to multiple franchises via `entry_franchises`

---

## Products

Products are purchasable items linked to entries and/or characters:
- Figures, Blu-rays, vinyl records, manga volumes, game discs, apparel
- Each product has a category and optional subcategory
- Products link to entries via `product_entries` and characters via `product_characters`
- Retailer availability tracked in `product_listings`

---

## External ID Capture

Capture ALL external IDs from every source. These are critical for cross-referencing, deduplication, and future API lookups.

### What to Capture

| Entity | IDs to Capture |
|--------|---------------|
| **Entry (anime)** | AniList ID, MAL ID (per season in `entry_seasons`) |
| **Entry (movie/OVA)** | AniList ID, MAL ID |
| **Character** | AniList ID, MAL ID |
| **Voice Actor** | AniList ID, MAL ID |
| **Staff (director, etc.)** | AniList ID, MAL ID |
| **Studio/Company** | AniList ID, MAL ID |
| **Franchise** | Root AniList ID, root MAL ID |
| **Entry (TV/movie)** | TVDB ID, TMDB ID, IMDB ID (when available) |
| **Entry (game)** | IGDB ID (when available) |
| **Entry (music)** | MusicBrainz ID, Spotify ID, Discogs ID (when available) |
| **Entry (book/manga)** | OpenLibrary ID, ISBN, MangaDex ID (when available) |

### Rules

- Store IDs in raw TOON data as-is from the source
- In synthesized JSON, use `external_ids` object: `{"anilist": 123, "mal": 456, "tvdb": 789}`
- Season-level IDs go in the season manifest (each season has its own AniList/MAL entry)
- Character IDs: cross-reference AniList character IDs with Jikan/MAL character IDs when both sources return data
- Never discard an ID even if we don't use it yet — future-proofing

---

## Data Source Priority

1. Free + Open APIs (AniList GraphQL, Jikan/MAL, MusicBrainz, OpenLibrary)
2. Free + Authenticated APIs (TVDB, IGDB, Spotify)
3. Paid APIs (TMDB, Serper)
4. Scraping (MFC, retailer sites)

---

## Status Mapping

| Source Value | Our Value |
|-------------|-----------|
| FINISHED / Finished Airing / Completed | `released` |
| RELEASING / Currently Airing / Publishing | `airing` / `ongoing` |
| NOT_YET_RELEASED / Not yet aired | `announced` |
| CANCELLED / Discontinued | `cancelled` |
| HIATUS | `hiatus` |

---

## Slug Rules

- Lowercase, hyphenated, no special characters
- Generated from English title (or romaji if no English)
- Must be unique per table
- Examples: `demon-slayer-kimetsu-no-yaiba`, `attack-on-titan`, `moving-pictures-rush`

---

## This Document

This is a living document. Update it as we establish rules for new mediums, edge cases, and data patterns. Every decision should be recorded here so subagents and future sessions can reference it.
