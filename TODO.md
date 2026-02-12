# TODO: Pipeline v4 (Strategy C + D)

> The Watchlist data pipeline rewrite.
> Deterministic skeleton + surgical LLM, organized as mini scripts.

---

## Current State (2026-02-12)

**Pipeline v4 is functional.** 18 scripts + 4 common modules running end-to-end.
AoT loaded: 1 franchise, 22 entries, 4 seasons, 89 episodes, 207 characters, 473 creators, 15 companies.
14 validation views in PostgreSQL. English episode titles/synopses via TVDB translations.

**Recent improvements (2026-02-11):**
- Creator MAL matching: 414/473 (87.5%) — up from 408 via VA cross-ref + name variants
- Character MAL matching: 165/207 (79.7%) — up from 111 via VA cross-ref
- Wikidata 5-tier cascade: 309/473 (65.3%) creators matched with confidence flags
  - 200 high confidence (birthdate-verified), 109 low (occupation-only)
- `wikidata_confidence` column added to creators table + v_creators view

**Repos:**
- `watchlistclawd/the-watchlist-pipeline` — v4 pipeline (private)
- `watchlistclawd/the-watchlist-data` — source data + output (private)
- `watchlistclawd/the-watchlist-docs` — documentation (public)
- `watchlistclawd/the-watchlist-scripts` — archived v3 (tagged `v3-archive`)

---

## Active TODO

### 1. Compartmentalized Data Gathering (Source Cache) — HIGH PRIORITY

**Problem:** Every franchise re-fetches all its creators/characters from AniList individually. Shared entities (VAs in multiple franchises) get re-pulled. 473 individual AniList calls with rate limiting = 15+ minutes per run.

**Solution:** Global entity cache with per-source manifests.

```
cache/sources/
  anilist/
    staff/{id}.json        ← one file per person
    characters/{id}.json
    media/{id}.json
    manifest.json          ← pull dates, staleness tracking
  mal/
    people/{id}.json
    characters/{id}.json
    anime/{id}.json
    manifest.json
  tvdb/
    series/{id}.json
    episodes/{id}.json
    manifest.json
  wikidata/
    entities/{qid}.json
    manifest.json
```

**How it works:**
1. Franchise discovery returns entity IDs (staff, chars, media)
2. Check cache manifest — skip if fresh, fetch if missing/stale
3. Processing reads from global cache, not franchise-specific sources
4. Second franchise onwards is near-instant for shared entities

**Staleness rules:**
| Entity Type | Stale After | Rationale |
|-------------|------------|-----------|
| Staff/People | 90 days | Names/bios rarely change |
| Characters | 90 days | Static once created |
| Media/Entries | 30 days | New seasons, status changes |
| Episodes | 7 days | Airing shows need fresh data |
| Companies | 180 days | Very static |

**Implementation steps:**
- [ ] Build `common/source_cache.py` — cache read/write/staleness logic
- [ ] Refactor AniList fetching to use cache
- [ ] Refactor MAL fetching to use cache
- [ ] Refactor TVDB fetching to use cache
- [ ] Update `12_create_creators.py` — alt name fetch reads from cache
- [ ] Backfill cache from existing `sources/attack-on-titan/` data
- [ ] Add `cache_stats.py` — show coverage, stale counts

### 2. Improve Creator Matching + Alternate Names

**Status:** Mostly done. Character cross-ref + name variants implemented.

**Schema change:**
- [x] `ALTER TABLE creators ADD COLUMN alternate_names text[];`

**Pipeline changes:**
- [x] `12_create_creators.py` — character-VA cross-reference matching (primary strategy)
- [x] `12_create_creators.py` — name variant matching (native_name, alt_names against MAL index)
- [x] `12_create_creators.py` — fuzzy name matching checks all name variants
- [x] `10_create_characters.py` — VA cross-reference fallback for character MAL matching
- [x] `10_create_characters.py` — match by all name variants (full, native, alternates)
- [ ] `01_fetch_anilist.py` — ensure `name.alternative` captured on staff (currently fetched in 12, should move to source cache)

**Results:**
- Creator MAL match: 414/473 (87.5%) — target was >90%, close
- Character MAL match: 165/207 (79.7%) — up from 111
- Remaining misses are mostly translation gaps (e.g. "Moses no Haha" vs "Moses's Mother")

### 3. Harden Enrichment (Script 18)

**Status:** Wikidata cascade implemented and validated.

- [x] 5-tier Wikidata cascade for creators (MAL ID → native name+birth → native name+occupation → English+birth → English+occupation)
- [x] Birth date validation ±30 days (caught 41 false positives)
- [x] `wikidata_confidence` flag (high/low) in JSON + DB
- [x] `wikidata_confidence` column in v_creators view
- [ ] Wikipedia infobox parsing for birth dates, founding years, HQ countries
- [ ] Company image sourcing (Wikipedia/Commons logos) — 0/15 companies have images
- [ ] Image URL validation (HEAD requests to verify live URLs)

### 4. Pipeline Infrastructure

- [ ] `run_all.py` orchestrator — run scripts 00-18 in order for a given franchise
- [x] Bake TVDB English translation fetch into `06_create_episodes.py`
- [x] Update `06_create_episodes.py` SQL to include `alternate_titles` in ON CONFLICT

### 5. Test on More Franchises

- [ ] JoJo's Bizarre Adventure
- [ ] Sentenced to Be a Hero
- [ ] 3-5 additional franchises for generalization testing
- [ ] Compare output against pipeline_v3 where applicable

---

## Inactive TODO

> Tasks from the original plan that are either complete or deferred. Kept for reference.

### Phase 0: Cleanup & Foundation — COMPLETE
- [x] Wipe all entity data, reseed lookup tables
- [x] Update `seed_lookups.sql` (blacklisted roles, tag threshold 80%)
- [x] Add `zh` to VA language filter
- [x] Archive `the-watchlist-scripts` (tagged `v3-archive`)
- [x] Create `the-watchlist-pipeline` repo with clean structure
- [x] Migrate common utils from v3
- [x] Set up `the-watchlist-data` folder structure, archive legacy data
- [x] Documentation sync (SCHEMA_NOTES.dbml, DATA_GATHERING_STRATEGY.md, PIPELINE_STRATEGIES.md)

### Phase 1: Fetch Scripts — COMPLETE
- [x] `common/api_clients.py` — TVDB, AniList, Jikan, Wikidata, Wikipedia clients
- [x] `common/db.py` — slugify, escape_sql, format_date, clean_description, sql_value
- [x] `common/config.py` — API keys, paths, thresholds, blacklists, VA filter
- [x] `common/matching.py` — fuzzy matching utilities
- [x] `00_fetch_tvdb.py`, `01_fetch_anilist.py`, `02_fetch_mal.py`

### Phase 2: Transform Scripts — COMPLETE (functional, improvements ongoing)
- [x] Scripts 03-17 all functional
- [x] `06_create_episodes.py` updated for English titles/synopses via TVDB translations

### Phase 3: LLM Integration — DEFERRED
Not needed for clean franchises like AoT. Will revisit when hitting ambiguous franchises.
- [ ] `common/llm.py` — Haiku client + cache layer
- [ ] Wire into 04 (consolidation), 05 (season matching), 12 (role mapping), 16 (cross-franchise)
- [ ] Pre-seed cache with known good mappings

### Phase 4: Validation — PARTIALLY COMPLETE
- [x] 14 validation views in PostgreSQL
- [ ] SQL syntax validation (dry-run with ROLLBACK)
- [ ] FK consistency check
- [ ] Slug uniqueness check
- [ ] Image URL validation (HEAD requests)
- [ ] Review file generator

### Phase 5: Scale — NOT STARTED (waiting for DanP approval)
- [ ] Top 500 anime by MAL popularity → franchise list
- [ ] Batch runner, cross-franchise dedup, resume capability
- [ ] Manga expansion (AniList + MAL only, no TVDB)
