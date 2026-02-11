# Pipeline Implementation Strategies

> Written 2026-02-11 after deep review of pipeline_v3.py, DATA_GATHERING_STRATEGY.md, and lessons from the first 6 test franchises.

---

## Context: What We Know

From building pipeline_v3 (1,478 lines, monolithic), we learned:

1. **The easy parts are genuinely easy.** Mapping AniList `format` → our `media_type`, extracting dates, building slugs, generating INSERT statements — this is mechanical. A `for` loop and a dict do it fine.

2. **The hard parts are genuinely hard.** TV consolidation (which AniList entries merge?), TVDB↔AniList season matching (title + year + episode count fuzzy), cross-franchise contamination filtering (is Lupin vs Conan part of Lupin?), role string normalization ("Chief Episode Director" → which of our 33 roles?). These required multiple bug-fix rounds and still aren't perfect.

3. **Edge cases are infinite.** Every franchise brings new weirdness. AoT's "Final Season" naming, Demon Slayer's arc-as-season splits, Fate's alternate-timeline-as-adaptation structure, JoJo's part-numbering, Lupin's 50-year franchise sprawl. Hard-coding rules for each is whack-a-mole.

4. **TVDB is now the structural backbone**, not AniList. This is a fundamental shift from pipeline_v3, which was AniList-first. The new pipeline needs to start from TVDB and graft AniList/MAL on top.

5. **Output is deterministic SQL.** Whatever we build, it writes `.sql` files that get reviewed and applied.

---

## Strategy A: Pure Scripting (Deterministic Python)

**What it looks like:** Everything in Python. Hard-coded mappings, rapidfuzz for matching, regex for cleanup, explicit rules for every decision. pipeline_v3 taken to its logical conclusion, just better organized.

### Architecture
```
fetch_tvdb.py → fetch_anilist.py → fetch_mal.py
        ↓               ↓              ↓
    tvdb.json      anilist.json     mal.json
                    ↓
            process.py (match, merge, consolidate)
                    ↓
              processed.json
                    ↓
              generate_sql.py
                    ↓
              franchise.sql
```

### Where It Works
- **Mechanical transforms** (95% of columns): Format mapping, date extraction, slug generation, genre/tag linking, SQL generation. These are table lookups and string ops. Python eats this for breakfast.
- **Well-defined mappings**: AniList genre names → our genre IDs, AniList status → our status strings. Finite, enumerable, stable.
- **Reproducibility**: Same input → same output, always. Critical for a database people rely on.
- **Speed and cost**: Runs in seconds, costs nothing. Can process all 500 franchises in an afternoon.
- **Debuggability**: When the SQL is wrong, you can trace every step. Print statements, intermediate JSON files, unit tests.

### Where It Breaks
- **TVDB↔AniList matching**: This is the #1 hard problem. Matching "Shingeki no Kyojin: The Final Season Part 2" to TVDB Season 4 episodes 17-28 requires understanding what those words *mean*, not just fuzzy string distance. rapidfuzz gives you a score, but a score of 65 could be a correct match or a wrong one.
- **Role normalization**: AniList uses free-text: "Chief Episode Director", "Assistant Animation Director", "2nd Key Animation (OP)", "Theme Song Performance (ED2; eps 6, 8)". Mapping these to our 33 roles means maintaining an ever-growing lookup table, and new roles appear with every franchise.
- **Consolidation judgment calls**: Should "Demon Slayer: Mugen Train Arc" (TV version) be a season of the main entry or a separate entry? It aired as TV episodes but adapts a movie. Rules can handle common cases but not the 10% that are weird.
- **Description quality**: AniList descriptions vary wildly — some are paragraphs, some are one sentence, some have HTML artifacts. Picking "the best description" across sources is a qualitative judgment.
- **Cross-franchise contamination**: Title-prefix matching works 90% of the time. The other 10% (crossover specials, shared-universe spinoffs) requires semantic understanding.

### Cost
$0. Just electricity and API calls to data sources.

### Verdict
Works great for the 90%. The 10% produces bad data that silently enters the database. We've already seen this with pipeline_v3 — bugs that went unnoticed until manual review. **The failure mode is silent wrong data, which is the worst kind.**

---

## Strategy B: LLM-Driven Pipeline

**What it looks like:** Fetch raw data, feed it to an LLM with our schema docs and rules, get SQL out. Basically scaled-up ResearchBuddy.

### Architecture
```
fetch_tvdb.py → fetch_anilist.py → fetch_mal.py
        ↓               ↓              ↓
    tvdb.json      anilist.json     mal.json
                    ↓
        slim_sources.py (reduce tokens)
                    ↓
            slimmed_data.json
                    ↓
    LLM prompt: "Here's the data. Here's the schema.
                 Here are the rules. Generate SQL."
                    ↓
              franchise.sql
```

### Where It Works
- **Matching and consolidation**: An LLM can reason about "Attack on Titan: The Final Season Part 2" being part of TVDB Season 4. It understands naming conventions, subtitles, and anime industry patterns. This is genuinely where LLMs shine — fuzzy reasoning over structured data.
- **Role normalization**: "Chief Episode Director" → episode_director. Trivial for an LLM. No mapping table needed.
- **Edge cases**: The "weird bullshit" that breaks hard-coded rules is exactly what LLMs handle well. They've seen enough anime data in training to know that "Mugen Train Arc" is a season, not a spinoff.
- **Description quality**: LLMs can evaluate, clean, and pick the best description. They can strip spoilers, fix HTML artifacts, and synthesize.
- **Less code**: Maybe 200 lines of Python for fetching + prompt construction, instead of 1,478 lines of pipeline logic.

### Where It Breaks
- **Non-deterministic output**: Run it twice, get different SQL. Different column ordering, slightly different description wording, maybe a different slug. This is *terrible* for a database pipeline. You can't meaningfully diff the output to see what changed between runs.
- **Hallucination**: The LLM might invent a release date it doesn't have data for. It might "helpfully" add characters it thinks should be there. It might guess at a wikidata_id instead of leaving it NULL. **Hallucinated data is worse than missing data.**
- **Token costs at scale**: A franchise like Lupin III has 51 entries, 88 characters, 274 creators, 4 companies. Even slimmed, that's 50k+ tokens of input. At 500 franchises, we're looking at millions of tokens. With Anthropic pricing, that's real money. MiniMax is free but less reliable for structured output.
- **Context window limits**: Big franchises may not fit in a single prompt. Splitting means losing cross-entry context (deduplication, relationships).
- **Structured output reliability**: Getting an LLM to produce syntactically correct SQL with proper escaping, UUID references, FK consistency, and ON CONFLICT handling across 17 interdependent tables is asking for pain. One wrong quote character and the whole file fails.
- **Debugging hell**: When the SQL is wrong, you can't step through the logic. You re-prompt and hope for a different answer.
- **Model dependency**: If Anthropic changes the model, outputs change. If we switch providers, outputs change. The pipeline's behavior is tied to a black box.
- **Speed**: Even with a fast model, generating SQL for 500 franchises means 500+ LLM calls. Hours instead of minutes.

### Cost
Significant. Rough estimate for 500 franchises: $50-200 on Anthropic, or free but unreliable on MiniMax. Recurring cost every time we re-run.

### Verdict
Solves the hard 10% but introduces new problems that are arguably worse. Non-determinism and hallucination in a database pipeline are dealbreakers. **The failure mode is plausible-looking wrong data, which is even harder to catch than Strategy A's failures.**

---

## Strategy C: Deterministic Skeleton + Surgical LLM Assist

**What it looks like:** The pipeline is 90% deterministic Python (Strategy A). The LLM is called *only* for specific, bounded decisions where hard-coding fails. LLM decisions are cached permanently so the same question is never asked twice.

### Architecture
```
fetch_tvdb.py → fetch_anilist.py → fetch_mal.py
        ↓               ↓              ↓
    tvdb.json      anilist.json     mal.json
                    ↓
    01_franchise.py ──→ franchise.sql
    02_entries.py ────→ entries.sql
    03_seasons.py ────→ seasons.sql  ← LLM: low-confidence TVDB↔AniList matches
    04_episodes.py ───→ episodes.sql
    05_translations.py → translations.sql
    06_genres.py ─────→ genres.sql
    07_tags.py ───────→ tags.sql
    08_characters.py ─→ characters.sql
    09_creators.py ───→ creators.sql  ← LLM: unmapped role strings
    10_companies.py ──→ companies.sql
    11_relationships.py → relationships.sql ← LLM: ambiguous cross-franchise refs
    12_wikidata.py ───→ enrichment.sql
    
    Each script: read source JSON → deterministic transform → flag ambiguities
                                                                    ↓
                                                            confidence < threshold?
                                                           /                      \
                                                         no                       yes
                                                          ↓                        ↓
                                                   generate SQL            check LLM cache
                                                                          /            \
                                                                      cached         not cached
                                                                        ↓                ↓
                                                                  use cached         ask LLM
                                                                  decision           cache result
                                                                        ↓                ↓
                                                                       generate SQL
```

### The Key Insight
**The LLM doesn't generate SQL. The LLM makes classification decisions.** The output of an LLM call is never a SQL statement — it's a structured answer like:

```json
// Season matching
{"tvdb_season": 4, "anilist_ids": [131681, 162804, 163139], "confidence": "high",
 "reasoning": "All three are parts of AoT Final Season, TVDB groups as S4"}

// Role mapping  
{"anilist_role": "Chief Episode Director", "our_role": "episode_director",
 "reasoning": "Episode-level directorial role"}

// Cross-franchise check
{"entry": "Lupin III vs Detective Conan", "belongs_to_franchise": false,
 "reasoning": "Crossover special, not a canonical Lupin entry"}
```

These decisions feed into the deterministic SQL generator. The SQL generation itself is always the same code path.

### Where the LLM Gets Called (and only here)

1. **TVDB↔AniList season matching** (03_seasons.py): When fuzzy title match score is below threshold (e.g. <75), or when episode counts don't align, ask the LLM: "TVDB Season 4 has 30 episodes. These AniList entries exist: [list]. Which map to this season?" ~5-10% of seasons need this.

2. **Role string normalization** (09_creators.py): When an AniList role doesn't match any of our 33 roles via substring, ask the LLM: "Which of these roles best matches 'Chief Episode Director'?" New franchises might trigger this 10-20 times; the cache means it's asked once ever.

3. **Cross-franchise contamination** (11_relationships.py): When a SIDE_STORY relation's title-similarity score is ambiguous (40-70%), ask the LLM: "Is 'Lupin III vs Detective Conan' part of the Lupin III franchise?" ~1-5 per franchise.

4. **Consolidation edge cases** (02_entries.py): When the TV-sequel-chain logic isn't sure (e.g. a TV_SHORT sequel to a TV series), ask: "Should this be a season or a separate entry?" Rare — maybe 1-2 per franchise.

### The Cache

```
the-watchlist-scripts/cache/
  llm_decisions/
    season_matches.json      # TVDB↔AniList pairings
    role_mappings.json       # AniList role → our role
    franchise_checks.json    # Cross-franchise yes/no
    consolidation.json       # Merge/separate decisions
```

- Keyed by a deterministic hash of the input (e.g. the AniList role string, or the TVDB season + candidate AniList IDs)
- Once cached, the decision is permanent until manually invalidated
- Cache is committed to git — decisions are reviewable, auditable, diffable
- After 50 franchises, the cache covers most common patterns and LLM calls drop to near-zero

### Where It Works
- **All of Strategy A's strengths**: Deterministic, fast, free (for the 90%), debuggable, reproducible.
- **Handles the hard 10%**: LLM provides semantic reasoning where string matching fails.
- **Economical**: LLM calls are bounded and decrease over time as the cache fills. First franchise might need 20 LLM calls. By franchise #50, maybe 2-3 per franchise (genuinely novel edge cases only).
- **Auditable**: Every LLM decision is cached with reasoning. DanP can review the cache and override bad decisions.
- **Deterministic after first run**: Once cached, the pipeline is 100% deterministic. Same input → same output. The cache is the "learned" mapping table.
- **Graceful degradation**: If the LLM is down or we want to skip it, flag low-confidence items for manual review instead. The pipeline still produces SQL — just with `-- TODO: MANUAL REVIEW NEEDED` comments.

### Where It Might Struggle
- **Architecture complexity**: More moving parts than pure scripting. Cache management, confidence thresholds, LLM client integration. More code than Strategy A (but less than pipeline_v3 since it's modular).
- **Threshold tuning**: What fuzzy score triggers an LLM call? Too low → misses real problems. Too high → too many LLM calls. Needs calibration.
- **Cache staleness**: If we change our role taxonomy, old cached role mappings might be wrong. Need a cache version/invalidation strategy.
- **First-run cost**: Processing 500 franchises from scratch means hundreds of LLM calls. Manageable but not zero. Mostly front-loaded.
- **LLM quality for decisions**: The LLM needs to be good enough for classification tasks. Haiku ($0.25/MTok) is probably sufficient for yes/no and multiple-choice decisions. MiniMax might work but less reliably.

### Cost
First run (500 franchises): Maybe 200-500 LLM calls × ~500 tokens each = ~250K tokens. At Haiku rates: ~$0.06. Essentially free. Subsequent runs: near-zero (cache hits).

### Verdict
Best of both worlds. Deterministic where determinism works, intelligent where it doesn't. The cache means it gets cheaper and more deterministic over time. **The failure mode is flagged ambiguity that gets human review, which is the best failure mode possible.**

---

## Strategy D: Mini Scripts in Execution Order (Organizational, Not Mutually Exclusive)

This is orthogonal to A/B/C — it's about *structure*, not *logic*. Any of the above can be organized as mini scripts.

**What it looks like:** Instead of one 1,478-line monolith, break into small scripts that each handle one table or one phase:

```
scripts/pipeline/
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
  run_all.py  (orchestrator)
```

### Pros
- Each script is small (~50-150 lines), single-purpose, easy to understand
- Can re-run one step without re-running everything
- Natural checkpoints — if step 6 fails, steps 1-5 output is preserved
- Matches DATA_GATHERING_STRATEGY.md execution order exactly
- Easy to develop incrementally — build, test, ship one script at a time
- Easy for DanP to review — small focused diffs
- Independent scripts can run in parallel where no dependencies exist
- Shared logic goes in a `common/` module (slugify, SQL escaping, API clients, config)

### Cons
- More files to manage (though each is simpler)
- Cross-script state coordination (UUIDs generated in step 3 needed in step 11)
- Need a shared intermediate format between scripts
- Running the full pipeline means an orchestrator or a bash script

### State Coordination Solution
Each script reads source JSON + previously generated SQL/JSON outputs:
```
data/{franchise-slug}/
  sources/
    tvdb.json
    anilist.json
    mal.json
  processed/
    franchise.json       ← 03 writes, later scripts read
    entries.json         ← 04 writes
    seasons.json         ← 05 writes
    characters.json      ← 10 writes
    creators.json        ← 12 writes
    companies.json       ← 14 writes
  sql/
    01_franchise.sql
    02_entries.sql
    03_seasons.sql
    ...
    99_complete.sql      ← cat of all above, in order
```

Each processed JSON includes generated UUIDs/slugs so downstream scripts can reference them.

---

## My Recommendation: Strategy C + D

**Implement Strategy C (Deterministic + Surgical LLM) organized as Strategy D (Mini Scripts).**

Here's why:

1. **Mini scripts give us incremental development.** We can build and ship `00_fetch_tvdb.py` → `03_create_franchise.py` → `04_create_entries.py` one at a time. Each is testable in isolation. We don't need to build the whole thing before seeing results.

2. **Deterministic core gives us reproducibility.** The database needs consistent, diffable output. 90% of the pipeline is mechanical transforms that don't need intelligence.

3. **Surgical LLM gives us quality on the hard problems.** The 10% that breaks pure scripting — season matching, role mapping, contamination filtering — gets semantic reasoning instead of increasingly desperate heuristics.

4. **The cache makes it economically sustainable.** Front-loaded LLM cost that trends toward zero. After the first 50-100 franchises, the pipeline is essentially free to run.

5. **Flagged ambiguity is the right failure mode.** Instead of silently inserting wrong data (Strategy A) or plausibly-wrong data (Strategy B), we get explicit `-- REVIEW: low-confidence match` flags that a human can audit.

### Development Order
Build the scripts in dependency order. Each one is a concrete, shippable unit:

**Phase 1 — Core skeleton (no LLM needed):**
- Fetch scripts (TVDB, AniList, MAL)
- Franchise creation
- Genre/tag linking
- Translation creation
- Episode creation (pure TVDB)

**Phase 2 — Add the hard matching:**
- Entry creation with consolidation logic
- Season creation with TVDB↔AniList matching
- Character/creator creation with deduplication
- Entry-creator linking with role mapping
- Relationship building with contamination guards

**Phase 3 — LLM integration for Phase 2's edge cases:**
- Confidence scoring on all matching operations
- LLM calls for low-confidence items
- Cache layer
- Graceful degradation (flag instead of fail)

**Phase 4 — Enrichment:**
- Wikidata batch queries
- Image URL verification
- Cross-franchise creator deduplication
