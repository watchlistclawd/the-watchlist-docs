# TODO: Pipeline v4 (Strategy C + D)

> The Watchlist data pipeline rewrite.
> Deterministic skeleton + surgical LLM, organized as mini scripts.

---

## Phase 0: Cleanup & Foundation

### 0.1 Database Cleanup
- [ ] Wipe all entity data (keep lookup tables: media_types, genres, tags, locales, countries, creator_roles, company_roles, relationship_types)
- [ ] Update `seed_lookups.sql` to reflect current state (blacklisted roles as `is_active=false`)
- [ ] Update `seed_lookups.sql` tag threshold note (80% not 70%)
- [ ] Verify lookup tables are correct and complete after wipe + reseed
- [ ] Add `zh` (Chinese) to VA language filter in code and docs

### 0.2 Project Folder Cleanup
- [ ] Archive `the-watchlist-scripts` — merge tvdb-refactor to main, tag as `v3-archive`, push
- [ ] Create new repo: `watchlistclawd/the-watchlist-pipeline` (private)
- [ ] Init with clean structure:
  ```
  the-watchlist-pipeline/
    README.md
    requirements.txt
    common/
      __init__.py
      api_clients.py      # TVDB, AniList, Jikan clients with rate limiting
      config.py            # Thresholds, API keys, paths
      db.py                # Slugify, SQL escaping, SQL generation helpers
      matching.py          # Fuzzy matching utilities (rapidfuzz)
      llm.py               # LLM decision client + cache layer
    cache/
      llm_decisions/
        season_matches.json
        role_mappings.json
        franchise_checks.json
        consolidation.json
    scripts/
      00_fetch_tvdb.py
      01_fetch_anilist.py
      02_fetch_mal.py
      03_create_franchise.py
      04_create_entries.py
      05_create_seasons.py
      06_create_episodes.py
      07_create_translations.py
      08_create_genres.py
      09_create_tags.py
      10_create_characters.py
      11_link_entry_characters.py
      12_create_creators.py
      13_link_entry_creators.py
      14_create_companies.py
      15_link_entry_companies.py
      16_create_relationships.py
      17_link_entry_franchises.py
      18_enrich_wikidata.py
      run_all.py
    tests/
      test_slugify.py
      test_matching.py
      test_sql_generation.py
  ```
- [ ] Migrate reusable code from pipeline_v3 → common/ (slugify, escape_sql, rate_limit, format_date, clean_description, role_blacklists)
- [ ] Set up `the-watchlist-data` folder structure for v4:
  ```
  the-watchlist-data/
    sources/{franchise-slug}/
      tvdb/           # Raw TVDB API responses
      anilist/        # Raw AniList API responses  
      mal/            # Raw Jikan/MAL API responses
    processed/{franchise-slug}/
      franchise.json
      entries.json
      seasons.json
      characters.json
      creators.json
      companies.json
    sql/{franchise-slug}/
      01_franchise.sql
      02_entries.sql
      ...
      99_complete.sql
  ```
- [ ] Archive old data structure (v1-v3 output) in a `legacy/` folder or separate branch

### 0.3 Documentation Sync
- [ ] Move TODO.md slug conventions to match SCHEMA_NOTES.dbml (franchise slug now has `-franchise` suffix)
- [ ] Update MEMORY.md with new pipeline location and architecture
- [ ] Ensure DATA_GATHERING_STRATEGY.md is committed and current (done)
- [ ] Ensure PIPELINE_STRATEGIES.md is committed (done)

---

## Phase 1: Fetch Scripts (No LLM Needed)

### 1.1 `common/api_clients.py`
- [ ] TVDB client: auth, search series, get extended series, get seasons, get episodes
- [ ] AniList client: GraphQL queries for media, characters, staff, relations (paginated)
- [ ] Jikan client: anime, characters, staff endpoints with rate limiting
- [ ] Wikidata client: SPARQL queries for entity lookup
- [ ] All clients: retry logic, rate limiting, response caching to disk

### 1.2 `common/db.py`
- [ ] `slugify()` — from pipeline_v3
- [ ] `escape_sql()` — from pipeline_v3
- [ ] `escape_json_for_sql()` — from pipeline_v3
- [ ] `format_date()` — from pipeline_v3
- [ ] `clean_description()` — from pipeline_v3, improved HTML stripping
- [ ] SQL INSERT/UPSERT generation helpers
- [ ] UUID generation (deterministic from slug? or random?)

### 1.3 `common/config.py`
- [ ] API keys (TVDB)
- [ ] Paths (data dir, cache dir)
- [ ] Thresholds (fuzzy match, tag rank, confidence)
- [ ] Role blacklists (move from config/role_blacklists.py)
- [ ] VA language filter: `['ja', 'en', 'ko', 'zh']`

### 1.4 Fetch Scripts
- [ ] `00_fetch_tvdb.py` — search + extended fetch for all series/movies in a franchise
- [ ] `01_fetch_anilist.py` — crawl relations graph from seed AniList ID, save per-entry JSON
- [ ] `02_fetch_mal.py` — fetch MAL data for all AniList entries that have `idMal`

**Deliverable:** Given a franchise slug + AniList seed ID, fetch all raw source data to `sources/{slug}/`.

---

## Phase 2: Deterministic Transform Scripts

### 2.1 Core Entity Scripts
- [ ] `03_create_franchise.py` — create franchise record from aggregated source data
- [ ] `04_create_entries.py` — TVDB series/movies → entries, with TV consolidation logic
  - Consolidation: walk AniList SEQUEL chains to identify which entries merge
  - TVDB structure defines what exists; AniList defines how they group
  - Output: `entries.json` + `entries.sql`
- [ ] `05_create_seasons.py` — TVDB seasons → entry_seasons
  - Deterministic for high-confidence TVDB↔AniList matches (fuzzy score ≥ 75)
  - Flag low-confidence matches for LLM (Phase 3)
  - Output: `seasons.json` + `seasons.sql`
- [ ] `06_create_episodes.py` — TVDB episodes → season_episodes (pure TVDB, no matching needed)
- [ ] `07_create_translations.py` — AniList/MAL titles → entry_translations

### 2.2 Linking Scripts
- [ ] `08_create_genres.py` — AniList genres → entry_genres (create new genres if needed)
- [ ] `09_create_tags.py` — AniList tags (rank ≥ 80%) → entry_tags (create new tags if needed)
- [ ] `10_create_characters.py` — AniList characters, deduplicated by anilist_id
- [ ] `11_link_entry_characters.py` — character↔entry links with roles
- [ ] `12_create_creators.py` — AniList staff + Jikan VAs, deduplicated by normalized name
  - Role mapping: deterministic for known mappings, flag unknowns for LLM (Phase 3)
- [ ] `13_link_entry_creators.py` — creator↔entry links with roles + VA↔character mappings
- [ ] `14_create_companies.py` — AniList studios + MAL producers, deduplicated
- [ ] `15_link_entry_companies.py` — company↔entry links with roles
- [ ] `16_create_relationships.py` — AniList relations → entry_relationships
  - Cross-franchise contamination guard: title similarity check
  - Flag ambiguous cases for LLM (Phase 3)
- [ ] `17_link_entry_franchises.py` — entry↔franchise links with release order

### 2.3 Orchestrator
- [ ] `run_all.py` — runs scripts 00-17 in order for a given franchise
  - CLI: `python run_all.py <franchise-slug> --anilist-id <ID> [--skip-fetch] [--skip-llm]`
  - Concatenates individual SQL files into `99_complete.sql`
  - Summary output: entry count, character count, flagged items count

**Deliverable:** Full pipeline that produces SQL for any franchise. Low-confidence items are flagged with `-- REVIEW:` comments in the SQL and logged to a review file.

---

## Phase 3: LLM Integration

### 3.1 `common/llm.py`
- [ ] LLM client (Haiku for classification tasks — cheap, fast, good enough)
- [ ] Cache layer: read/write `cache/llm_decisions/*.json`
  - Key: deterministic hash of input (e.g. the question being asked)
  - Value: decision + reasoning + timestamp
- [ ] Structured output parsing (JSON responses from LLM)
- [ ] Fallback: if LLM unavailable, write `-- REVIEW:` comment and continue

### 3.2 Decision Points
- [ ] **Season matching** (05_create_seasons.py): "Which AniList entries map to TVDB Season N?"
  - Input: TVDB season info + candidate AniList entries
  - Output: `{anilist_ids: [...], confidence: "high"}`
- [ ] **Role mapping** (12_create_creators.py): "Which creator_role matches this AniList role string?"
  - Input: AniList role string + list of our 33 active roles
  - Output: `{our_role: "episode_director"}`
- [ ] **Cross-franchise check** (16_create_relationships.py): "Does this entry belong to this franchise?"
  - Input: entry title + franchise name + relation type
  - Output: `{belongs: true/false}`
- [ ] **Consolidation** (04_create_entries.py): "Should this entry be a season or standalone?"
  - Input: entry info + relation chain context
  - Output: `{action: "consolidate_as_season" | "keep_separate"}`

### 3.3 Cache Seeding
- [ ] Pre-populate role_mappings.json with all known AniList→our role mappings from pipeline_v3
- [ ] Pre-populate season_matches.json with known good matches from test franchises (AoT, JoJo, Sentenced)

**Deliverable:** Pipeline resolves ambiguities automatically via LLM. Decisions cached for reproducibility. Review file shows what LLM decided and why.

---

## Phase 4: Enrichment & Validation

### 4.1 Wikidata Enrichment
- [ ] `18_enrich_wikidata.py` — batch SPARQL queries for all new entities
  - Match by AniList/MAL ID first (Wikidata P8731/P4086)
  - Fall back to name + type search
  - Harvest extra IDs (IMDB, MusicBrainz, official website)
  - Set `wikidata_id = '0'` when confirmed absent
  - Determine batch size limits experimentally

### 4.2 Validation
- [ ] SQL syntax validation (dry-run against DB with `BEGIN; ... ROLLBACK;`)
- [ ] FK consistency check (all referenced UUIDs exist in prior SQL statements)
- [ ] Slug uniqueness check (no duplicates within generated SQL)
- [ ] Image URL validation (HEAD request to verify URLs are live)
- [ ] Review file generator: list all `-- REVIEW:` items across all SQL files

### 4.3 Testing
- [ ] Re-run pipeline on 3 test franchises (AoT, JoJo, Sentenced to Be a Hero)
- [ ] Compare output against pipeline_v3 output — identify regressions
- [ ] Run against 5 new franchises to validate generalization
- [ ] Verify DB state after applying generated SQL

---

## Phase 5: Scale

### 5.1 Batch Processing
- [ ] Top 500 anime by MAL popularity → franchise list
- [ ] Batch runner: process all franchises, aggregate SQL
- [ ] Cross-franchise creator/company deduplication pass
- [ ] Progress tracking and resume capability

### 5.2 Manga Expansion
- [ ] Adapt fetch scripts for manga-only entries (no TVDB)
- [ ] Manga entries: AniList + MAL only, no season/episode structure
- [ ] Handle manga↔anime adaptation relationships

---

## Current State Snapshot (2026-02-11)

**DB:** 3 franchises, 35 entries, 292 characters, 544 creators, 26 companies. All from pipeline_v3.
**Repos:**
- `the-watchlist-scripts` — pipeline v1-v3, tvdb-refactor branch (to be archived)
- `the-watchlist-data` — raw sources + generated SQL for 3 franchises
- `the-watchlist-docs` — schema docs, strategy docs, this TODO
- `the-watchlist-pipeline` — NEW, clean implementation of Strategy C+D
