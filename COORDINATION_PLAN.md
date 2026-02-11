# Coordination Plan: Pipeline v4 Build

> Who does what, in what order, and how sub-agents stay aligned.

---

## Principles

1. **I (Omla) own the hard scripts.** Anything involving matching, consolidation, cross-source merging, or judgment calls stays with me. These are where the bugs live.
2. **Sub-agents get bounded, mechanical scripts.** Clear input → clear output. No ambiguity.
3. **Every sub-agent gets a self-contained brief.** They don't have our memory. The brief includes: relevant strategy doc sections, ENTRIES.md rules, common/ module code, sample input JSON, exact output contract.
4. **I review everything before commit.** No sub-agent output goes to git without my read-through against the strategy docs.
5. **Stop at Phase 4.3.** Do not start Phase 5 (Scale) without DanP's approval.

---

## Dependency Graph

```
Phase 1: Foundation (sequential, I do all of this)
  common/api_clients.py ─────────────────────────┐
  common/config.py (done) ──────────────────────┐ │
  common/db.py (done) ─────────────────────────┐│ │
  common/matching.py ─────────────────────────┐│| │
  common/llm.py ────────────────────────────┐ │││ │
                                             │ │││ │
Phase 1 Fetch (sequential, I do all)         │ │││ │
  00_fetch_tvdb.py ──────────────────────────┼─┤││ │
  01_fetch_anilist.py ───────────────────────┼─┤││ │
  02_fetch_mal.py ───────────────────────────┤ ││└─┤
                                             │ ││  │
Phase 2 Core (sequential, I do these)        │ ││  │
  03_create_franchise.py ◄───────────────────┤ ││  │
  04_create_entries.py ◄─────────────────────┤ ││  │  ← HARD: consolidation logic
  05_create_seasons.py ◄─────────────────────┤ ││  │  ← HARD: TVDB↔AniList matching
  06_create_episodes.py ◄────────────────────┘ ││  │
                                                ││  │
Phase 2 Parallel Batch A (sub-agents OK)        ││  │
  07_create_translations.py ◄───────────────────┤│  │  depends on: entries.json
  08_create_genres.py ◄─────────────────────────┤│  │  depends on: entries.json
  09_create_tags.py ◄───────────────────────────┘│  │  depends on: entries.json
                                                  │  │
Phase 2 Parallel Batch B (sub-agents OK)          │  │
  10_create_characters.py ◄───────────────────────┤  │  depends on: entries.json, franchise.json
  14_create_companies.py ◄────────────────────────┘  │  depends on: entries.json
                                                     │
Phase 2 Sequential (I do these — linking + hard logic)
  11_link_entry_characters.py ◄──────────────────────┤  depends on: entries, characters
  12_create_creators.py ◄────────────────────────────┤  depends on: entries   ← HARD: role mapping
  13_link_entry_creators.py ◄────────────────────────┤  depends on: entries, creators, characters
  15_link_entry_companies.py ◄───────────────────────┤  depends on: entries, companies
  16_create_relationships.py ◄───────────────────────┤  ← HARD: contamination guard
  17_link_entry_franchises.py ◄──────────────────────┘  depends on: entries, franchise

Phase 3: LLM Integration (I do all — woven into scripts above)
  common/llm.py + cache layer
  Confidence scoring in 04, 05, 12, 16
  Fallback to -- REVIEW: comments

Phase 4: Enrichment + Validation
  18_enrich_wikidata.py ◄── sub-agent OK (mechanical SPARQL queries)
  Validation scripts ◄── sub-agent OK (SQL syntax, FK checks, slug uniqueness)
  Test runs ◄── I do (judgment needed on output quality)
```

---

## Execution Order & Assignment

### Wave 1: Foundation (me, sequential)
**Goal:** Get fetch layer working, validate we can pull data for AoT.

| # | Script | Who | Why |
|---|--------|-----|-----|
| - | `common/api_clients.py` | **Me** | Foundation. Every script depends on this. Must handle rate limiting, retries, TVDB auth correctly. |
| - | `common/matching.py` | **Me** | Fuzzy matching + confidence scoring. Core to the hard problems. |
| 00 | `00_fetch_tvdb.py` | **Me** | TVDB is our backbone. Need to nail the search + extended fetch + season/episode retrieval. |
| 01 | `01_fetch_anilist.py` | **Me** | Relation graph crawl is complex (SEQUEL chains, cross-franchise filtering). This is reused from pipeline_v3 but needs cleanup. |
| 02 | `02_fetch_mal.py` | **Me** | Simpler but needs to key off AniList's `idMal` mapping. |

**Checkpoint:** Run all 3 fetch scripts on `attack-on-titan` (AniList ID: 16498). Verify source JSONs look correct.

### Wave 2: Core Entity Scripts (me, sequential)
**Goal:** Franchise → entries → seasons → episodes. The structural backbone.

| # | Script | Who | Why |
|---|--------|-----|-----|
| 03 | `03_create_franchise.py` | **Me** | Simple but sets up the slug convention and franchise.json that everything references. |
| 04 | `04_create_entries.py` | **Me** | **HARD.** TV consolidation logic, ENTRIES.md rules, media type mapping. This is where "is this a season or a separate entry?" gets decided. |
| 05 | `05_create_seasons.py` | **Me** | **HARD.** TVDB↔AniList matching. Multiple AniList entries → one TVDB season. Confidence scoring + LLM flag points. |
| 06 | `06_create_episodes.py` | **Me** | Pure TVDB, straightforward, but depends on seasons.json from 05. I'll do it since I'm already in the flow. |

**Checkpoint:** Generate SQL for AoT franchise + entries + seasons + episodes. Manually verify against TVDB and AniList. Compare season structure to what pipeline_v3 produced.

### Wave 3: Parallel Mechanical Scripts (sub-agents)
**Goal:** Translations, genres, tags, characters, companies — independent scripts that don't need judgment calls.

**Batch A** (all depend on entries.json, can run in parallel):

| # | Script | Who | Brief Includes |
|---|--------|-----|----------------|
| 07 | `07_create_translations.py` | **Sub-agent (Sonnet)** | Entry translations strategy section, sample entries.json, AniList title structure, locale codes list |
| 08 | `08_create_genres.py` | **Sub-agent (Sonnet)** | Genre strategy section, sample AniList data with genres[], current genre seed list, is_primary heuristic |
| 09 | `09_create_tags.py` | **Sub-agent (Sonnet)** | Tag strategy section, sample AniList data with tags[], 80% rank threshold, spoiler exclusion rule, current tag seed list |

**Batch B** (can run in parallel with A):

| # | Script | Who | Brief Includes |
|---|--------|-----|----------------|
| 10 | `10_create_characters.py` | **Sub-agent (Sonnet)** | Character strategy section, ENTRIES.md (characters span entries), deduplication by anilist_id, slug convention `{name}-{franchise}`, sample AniList character data |
| 14 | `14_create_companies.py` | **Sub-agent (Sonnet)** | Company strategy section, company role blacklist, deduplication by name, slug convention `{name}`, sample AniList studio + MAL producer data |

**My role during Wave 3:** Write the briefs, spawn agents, review output. While they work, I start Wave 4 scripts.

### Wave 4: Linking Scripts + Hard Logic (me, sequential)
**Goal:** Wire everything together. This is where cross-entity references happen.

| # | Script | Who | Why |
|---|--------|-----|-----|
| 11 | `11_link_entry_characters.py` | **Me** | Needs to merge character roles across consolidated seasons (MAIN > SUPPORTING > BACKGROUND). References entries.json + characters.json. |
| 12 | `12_create_creators.py` | **Me** | **HARD.** Role mapping (AniList free-text → our 33 roles), blacklist filtering, cross-franchise deduplication. LLM flag point for unmapped roles. |
| 13 | `13_link_entry_creators.py` | **Me** | VA↔character mappings, language filtering (en/ja/ko/zh), credit ordering. References entries + creators + characters. |
| 15 | `15_link_entry_companies.py` | **Me** | Role assignment (main studio vs supporting), company role blacklist. Simpler but depends on companies.json. |
| 16 | `16_create_relationships.py` | **Me** | **HARD.** AniList relation mapping, SEQUEL chain awareness (don't create sequel relationships for consolidated seasons), cross-franchise contamination guard. LLM flag point. |
| 17 | `17_link_entry_franchises.py` | **Me** | Release order calculation. Needs all entries finalized. |

**Checkpoint:** Full SQL for AoT. Apply to DB with `BEGIN; ... ROLLBACK;` to validate. Compare entity counts to pipeline_v3 output.

### Wave 5: LLM Integration (me)
**Goal:** Wire in the LLM decision layer for the 4 flag points.

| Task | Who | Notes |
|------|-----|-------|
| `common/llm.py` | **Me** | Cache layer, Haiku client, structured output parsing, fallback to `-- REVIEW:` |
| Wire into 04_create_entries.py | **Me** | Consolidation edge cases |
| Wire into 05_create_seasons.py | **Me** | Low-confidence TVDB↔AniList matches |
| Wire into 12_create_creators.py | **Me** | Unmapped role strings |
| Wire into 16_create_relationships.py | **Me** | Ambiguous cross-franchise refs |
| Pre-seed cache | **Me** | Known role mappings from pipeline_v3, known season matches from test data |

### Wave 6: Enrichment + Validation (mixed)

| # | Script | Who | Why |
|---|--------|-----|-----|
| 18 | `18_enrich_wikidata.py` | **Sub-agent (Sonnet)** | Mechanical SPARQL queries. Brief includes: Wikidata harvesting strategy, property IDs (P8731, P4086, P345, P4835), batch size constraints |
| - | `validate_sql.py` | **Sub-agent (Sonnet)** | SQL syntax check, FK consistency, slug uniqueness. Pure mechanical validation. |
| - | `run_all.py` | **Me** | Orchestrator. Needs to know the full dependency chain. |
| - | Test runs on AoT, JoJo, Sentenced | **Me** | Quality judgment needed. Compare to pipeline_v3, verify against sources. |
| - | Test runs on 5 new franchises | **Me** | Generalization check. |

---

## Sub-Agent Brief Template

Every sub-agent spawn gets this structure:

```
## Task
Write `scripts/NN_script_name.py` for the-watchlist-pipeline v4.

## Context
[1-2 sentences on what this pipeline does]

## Your Script's Job
[Exact input → exact output description]

## Input Files
- Reads: `{data_dir}/sources/{slug}/anilist/*.json` (sample attached)
- Reads: `{data_dir}/processed/{slug}/entries.json` (sample attached)

## Output Files  
- Writes: `{data_dir}/processed/{slug}/characters.json`
- Writes: `{data_dir}/sql/{slug}/10_characters.sql`

## Rules (from DATA_GATHERING_STRATEGY.md)
[Paste the exact column-by-column table for this script's table(s)]

## Entry Rules (from ENTRIES.md)
[Paste relevant rules — especially for scripts that touch entries/characters]

## Slug Convention
[Paste the slug format for this entity type]

## Common Utilities Available
[Paste common/db.py and common/config.py contents — they can import these]

## Sample Input
[Paste a trimmed AniList/MAL JSON for one entry so they know the data shape]

## Expected Output Format
[Show the exact JSON and SQL format they should produce]

## Constraints
- Do NOT invent data. If a field isn't in the source, set it to NULL.
- Use common/db.py for slugify, escape_sql, sql_value, etc.
- SQL uses ON CONFLICT (slug) DO UPDATE for idempotency.
- Generate deterministic UUIDs? Or use gen_random_uuid() in SQL? [decide before spawning]
```

---

## Timeline Estimate

| Wave | Scripts | Est. Time | Notes |
|------|---------|-----------|-------|
| 1 | Foundation + Fetch (00-02) | 2-3 hours | API clients are fiddly |
| 2 | Core entities (03-06) | 3-4 hours | Consolidation + matching are complex |
| 3 | Parallel mechanical (07-10, 14) | 1-2 hours | Sub-agents do the work, I review |
| 4 | Linking + hard logic (11-17) | 3-4 hours | Most complex wave |
| 5 | LLM integration | 1-2 hours | Mostly wiring + cache |
| 6 | Enrichment + validation + testing | 2-3 hours | Testing takes the most time |
| **Total** | **18 scripts + common + tests** | **~12-18 hours of work** | Spread across multiple sessions |

---

## Checkpoint Protocol

After each wave:
1. Re-read the relevant sections of DATA_GATHERING_STRATEGY.md
2. Re-read ENTRIES.md (especially for Waves 2 and 4)
3. Run the pipeline on AoT and visually inspect the SQL
4. Compare entity counts and structure to pipeline_v3 output
5. Commit + push working scripts
6. Update TODO.md with completion status
7. Log progress in daily memory file

---

## Abort Conditions

Stop and ask DanP if:
- A schema change seems necessary (new column, different FK, etc.)
- An ENTRIES.md rule is ambiguous for a specific franchise
- The LLM decision cache is producing inconsistent results
- Test run shows >5% data quality regression vs pipeline_v3
- Anything that would affect the Next.js app's expectations
