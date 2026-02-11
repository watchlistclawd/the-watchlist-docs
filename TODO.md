# TODO: Pipeline v4 (Strategy C + D)

> The Watchlist data pipeline rewrite.
> Deterministic skeleton + surgical LLM, organized as mini scripts.

---

## Current State (2026-02-11)

**Pipeline v4 is functional.** 18 scripts + 4 common modules running end-to-end.
AoT loaded: 1 franchise, 22 entries, 4 seasons, 89 episodes, 207 characters, 473 creators, 15 companies.
14 validation views in PostgreSQL. English episode titles/synopses via TVDB translations.

**Repos:**
- `watchlistclawd/the-watchlist-pipeline` — v4 pipeline (private)
- `watchlistclawd/the-watchlist-data` — source data + output (private)
- `watchlistclawd/the-watchlist-docs` — documentation (public)
- `watchlistclawd/the-watchlist-scripts` — archived v3 (tagged `v3-archive`)

---

## Active TODO

### 1. Improve Creator Matching + Alternate Names

**Problem:** Only 141/473 creators have MAL IDs (30%). Current matching is exact-name-only. AniList `name.alternative` and MAL `alternate_names` are ignored entirely.

**Schema change:**
- [ ] `ALTER TABLE creators ADD COLUMN alternate_names text[];`

**Data sources for alternate names:**

| Source | Field | Example |
|--------|-------|---------|
| AniList Staff | `name.alternative[]` | "Alexander Moran" for Alex Organ |
| Jikan/MAL Person | `alternate_names[]` | Same + additional variants |
| Jikan/MAL Person | `given_name` + `family_name` | Japanese name components |
| Wikidata | `skos:altLabel` | Sparse for VAs, better for directors |

**Pipeline changes:**
- [ ] `01_fetch_anilist.py` — ensure `name.alternative` is captured on staff data
- [ ] `02_fetch_mal.py` — fetch character-VA data per entry for cross-matching
- [ ] `12_create_creators.py` — rewrite MAL matching:
  1. **Character-VA pairing** (primary) — if AniList VA X voices Character Y, and MAL VA Z voices the same character, then X=Z. Way more reliable than name matching.
  2. **Alt name cross-reference** — if AniList `alternative[]` contains MAL name or vice versa, match
  3. **Fuzzy name matching** (fallback) — use rapidfuzz from `common/matching.py`
  4. **Store `alternate_names[]`** — union of AniList + MAL alt names, deduplicated
- [ ] `common/api_clients.py` — verify `jikan_person_full()` exists or add it
- [ ] Jikan person enrichment — for matched creators, fetch `/people/{mal_id}/full` to get `alternate_names[]`, `given_name`, `family_name`, `about`

**Target:** >90% MAL coverage (up from 30%)

**Verification:**
- [ ] Re-run creator pipeline for AoT
- [ ] Verify Alex Organ has MAL ID + alternate names
- [ ] Check MAL match rate improvement
- [ ] Spot-check 10 random creators for data quality

### 2. Harden Enrichment (Script 18)

**Problem:** Wikidata enrichment is the weakest link. Many creators missing birth dates, companies have 0/15 images.

- [ ] Improve SPARQL queries — try name+occupation matching, not just AniList/MAL ID lookup
- [ ] Wikipedia infobox parsing for birth dates, founding years, HQ countries
- [ ] Company image sourcing (Wikipedia/Commons logos)
- [ ] Image URL validation (HEAD requests to verify live URLs)

### 3. Pipeline Infrastructure

- [ ] `run_all.py` orchestrator — run scripts 00-18 in order for a given franchise
- [ ] Bake TVDB English translation fetch into `06_create_episodes.py` ✅ (done)
- [ ] Update `06_create_episodes.py` SQL to include `alternate_titles` in ON CONFLICT ✅ (done)

### 4. Test on More Franchises

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
