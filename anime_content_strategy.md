# Anime & Manga Content Strategy

> **Purpose:** Column-by-column data retrieval strategy for anime and manga content.  
> **Created:** 2026-02-12  
> **Last Updated:** 2026-02-12  
> **Scope:** All tables relevant to anime/manga entries (excludes product/retail/music)

---

## Table of Contents

1. [Data Sources & Priority](#data-sources--priority)
2. [API Endpoints Reference](#api-endpoints-reference)
3. [Matching Logic](#matching-logic)
4. [Default Values (Gap-Filling)](#default-values-gap-filling)
5. [Schema: Core Tables](#schema-core-tables)
6. [Schema: Junction Tables](#schema-junction-tables)
7. [Schema: Lookup Tables](#schema-lookup-tables)

---

## Data Sources & Priority

### Source Hierarchy (cheapest/fastest first)

| Priority | Source | Auth | Rate Limits | Best For |
|----------|--------|------|-------------|----------|
| 1 | **AniList GraphQL** | None | 90 req/min | Anime/manga metadata, relations, characters, staff |
| 2 | **Jikan (MAL proxy)** | None | 3 req/sec | Character images, voice actors, supplementary data |
| 3 | **TVDB** | API key | 100 req/day (free) | Season/episode structure, air dates, images |
| 4 | **Wikidata SPARQL** | None | Generous | External IDs, birthdates, nationalities, bios |
| 5 | **Wikipedia API** | None | Polite | Descriptions, founding info |
| 6 | **Web Search** | Brave API | 1 req/10s (free) | Fallback for obscure data |

### API Rate Limit Strategy

```
AniList:   90 requests/minute  → sleep 0.7s between calls
Jikan:     3 requests/second   → sleep 0.35s between calls  
TVDB:      100 requests/day    → batch carefully, cache aggressively
Wikidata:  Generous            → sleep 1s between SPARQL queries
Wikipedia: Polite              → sleep 1s between calls
Brave:     1 request/10s       → sleep 10s between searches
```

---

## API Endpoints Reference

### AniList GraphQL

**Endpoint:** `https://graphql.anilist.co` (POST)

```graphql
# Media (anime/manga) query
query Media($id: Int, $search: String, $type: MediaType) {
  Media(id: $id, search: $search, type: $type) {
    id idMal
    title { romaji english native }
    format status episodes chapters volumes
    startDate { year month day }
    endDate { year month day }
    description(asHtml: false)
    coverImage { extraLarge large medium }
    genres tags { name rank category isMediaSpoiler }
    studios { nodes { id name isAnimationStudio } edges { isMain } }
    staff { nodes { id name { full native } } edges { role } }
    characters { nodes { id name { full native } } edges { role voiceActors { id name { full native } languageV2 } } }
    relations { edges { relationType node { id type format title { romaji } } } }
    countryOfOrigin isAdult
  }
}

# Staff (creator) query
query Staff($id: Int) {
  Staff(id: $id) {
    id name { full native alternative }
    dateOfBirth { year month day }
    dateOfDeath { year month day }
    description(asHtml: false)
    image { large }
    primaryOccupations
  }
}

# Character query
query Character($id: Int) {
  Character(id: $id) {
    id name { full native alternative alternativeSpoiler }
    description(asHtml: false)
    image { large }
    age gender bloodType
    dateOfBirth { month day }
  }
}
```

### Jikan (MAL Proxy)

**Base URL:** `https://api.jikan.moe/v4`

| Endpoint | Purpose |
|----------|---------|
| `/anime/{id}` | Anime details |
| `/anime/{id}/characters` | Characters + voice actors |
| `/anime/{id}/staff` | Staff list |
| `/manga/{id}` | Manga details |
| `/characters/{id}` | Character details |
| `/people/{id}` | Person (creator) details |

### TVDB

**Base URL:** `https://api4.thetvdb.com/v4`

| Endpoint | Purpose |
|----------|---------|
| `/search?query={name}&type=series` | Find series by name |
| `/series/{id}` | Series details |
| `/series/{id}/episodes` | All episodes |
| `/series/{id}/artworks` | Images |
| `/episodes/{id}/translations/{lang}` | Episode translations |

### Wikidata SPARQL

**Endpoint:** `https://query.wikidata.org/sparql`

```sparql
# Find person by name + occupation (voice actor)
SELECT ?item ?itemLabel WHERE {
  ?item wdt:P106 wd:Q2405480.  # occupation: voice actor
  ?item rdfs:label ?label.
  FILTER(LANG(?label) = "en")
  FILTER(CONTAINS(LCASE(?label), "kaji"))
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en,ja". }
}
LIMIT 10

# Get person details
SELECT ?birth ?death ?nationality ?image WHERE {
  wd:Q123456 wdt:P569 ?birth.
  OPTIONAL { wd:Q123456 wdt:P570 ?death. }
  OPTIONAL { wd:Q123456 wdt:P27 ?nationality. }
  OPTIONAL { wd:Q123456 wdt:P18 ?image. }
}
```

---

## Matching Logic

### AniList ↔ MAL Matching

**Primary:** AniList provides `idMal` field directly for media.

**Fallback (when idMal is null):**
1. Search MAL by romaji title + format + year
2. Verify episode count matches (±2 tolerance)
3. Verify start year matches

### AniList ↔ TVDB Matching (Seasons)

**Algorithm:**
1. Search TVDB by series name (English or romaji)
2. For each TVDB season, match to AniList entries by:
   - Year of first episode air date (±1 year tolerance)
   - Episode count (±2 episodes tolerance)
   - Title similarity (fuzzy match, >70% threshold)
3. **TVDB defines structure** — multiple AniList entries may map to one TVDB season

### Character AniList ↔ MAL Matching

1. Cross-reference via character appearances in matched entries
2. Match by name (romaji) + franchise context
3. If ambiguous, prefer AniList as canonical source

### Creator AniList ↔ MAL Matching

1. Match by name (full_name) — exact or fuzzy (>85%)
2. Verify with at least one shared work credit
3. If ambiguous, use Wikidata as tiebreaker

### Wikidata Matching (5-Tier Cascade)

1. **T1:** Direct property lookup (P8731 AniList, P4086 MAL)
2. **T2:** Native name + birth year + occupation
3. **T3:** Native name + occupation (no birth year)
4. **T4:** English name + birth year + occupation
5. **T5:** English name + occupation (no birth year)

---

## Default Values (Gap-Filling)

When data cannot be found after reasonable research effort:

| Column | Default Value | Notes |
|--------|---------------|-------|
| `birth_date` | `1900-01-01` | Indicates unknown |
| `death_date` | `NULL` or `9999-12-31` | NULL = living, 9999 = unknown |
| `nationality` | `NULL` | Don't assume |
| `wikidata_id` | `'0'` | Confirmed not found |
| `description` | `''` (empty) | Better than NULL |
| `biography` | `'Information unavailable.'` | Standard placeholder |
| `primary_image` | `NULL` | Don't use placeholder images |
| `credit_order` | `1` | Default ordering |
| `franchise_release_order` | `1` | Default ordering |
| `tvdb_id` | `0` | Indicates not matched |
| `alternate_names` | `'{}'::text[]` | Empty array |
| `is_primary` (genres) | `false` | Conservative default |
| `role` (characters) | `'supporting'` | Conservative default |

---

## Schema: Core Tables

### `franchises`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto: `gen_random_uuid()` |
| `name` | text NOT NULL | **AniList** title.romaji of root entry. Cross-check Wikipedia for canonical name. |
| `native_name` | text | **AniList** title.native. Fallback: Wikidata label in ja/ko/zh. |
| `alternate_names` | text[] | Union of AniList synonyms + MAL title_synonyms. Include abbreviations (AoT, KnY). |
| `parent_id` | uuid | Manual. Most = NULL. Sub-franchises reference parent. |
| `description` | text | **Wikipedia** lead paragraph (MediaWiki extracts API). Max 2-3 sentences. |
| `primary_image` | text | **AniList** coverImage from most popular entry in franchise. |
| `wikidata_id` | text | **Wikidata SPARQL**: name + "media franchise" type. If absent → `'0'`. |
| `websites` | jsonb | `{"wikipedia": "url", "anilist_id": N, "mal_id": N}` |
| `slug` | text NOT NULL | `{slugify(name)}`. e.g. `demon-slayer-kimetsu-no-yaiba` |

**Process:** AniList root entry → derive franchise name → Wikidata lookup → Wikipedia description → generate slug.

---

### `entries`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto: `gen_random_uuid()` |
| `media_type_id` | uuid NOT NULL | **AniList** format mapped: TV→anime-series, MOVIE→anime-movie, OVA→anime-ova, MANGA→manga, NOVEL→light-novel. Query media_types for UUID. |
| `title` | text NOT NULL | **AniList** title.romaji (canonical). |
| `sort_title` | text | Strip "The", "A" from start. For Japanese, use romaji as-is. |
| `alternate_titles` | text[] | **AniList** synonyms[] + **MAL** title_synonyms[]. NOT translations (those go in entry_translations). |
| `release_date` | date | **AniList** startDate. Fallback: MAL aired.from. Partial → YYYY-01-01. |
| `status` | text | **AniList** status mapped: FINISHED→released, RELEASING→airing, NOT_YET_RELEASED→upcoming, CANCELLED→cancelled, HIATUS→hiatus. Default: `'released'`. |
| `description` | text | **AniList** description (strip HTML). Fallback: MAL synopsis. |
| `nsfw` | boolean | **AniList** isAdult OR **MAL** rating in ['rx', 'r+']. Default: `false`. |
| `locale_code` | varchar(10) NOT NULL | **AniList** countryOfOrigin: JP→`ja`, KR→`ko`, CN→`zh`, else→`en`. |
| `primary_image` | text | **AniList** coverImage.extraLarge. Fallback: MAL image. |
| `wikidata_id` | text | **Wikidata**: name + media type. Match via P8731/P4086 if available. If absent → `'0'`. |
| `details` | jsonb | `{"anilist_id": N, "mal_ids": [N], "tvdb_id": N, "episodes": N, "chapters": N, "volumes": N, "duration_minutes": N, "average_score": N, "popularity": N, "consolidated": bool}` |
| `is_active` | boolean | Default: `true`. |
| `slug` | text NOT NULL | `{slugify(title)}-{media_type}-{release_year}`. e.g. `attack-on-titan-anime-2013`. |

**Consolidation Rule (TV Anime):** AniList splits sequel seasons. We consolidate all TV SEQUEL chains into ONE entry. Movies/OVAs/specials stay separate. Manga is always separate.

---

### `entry_seasons`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto: `gen_random_uuid()` |
| `entry_id` | uuid NOT NULL | FK → entries (the consolidated TV entry). |
| `season_number` | integer NOT NULL | **TVDB** season number (structural backbone). |
| `title` | text | **TVDB** season name. Enrich with **AniList** title.romaji from matched entry. |
| `alternate_titles` | text[] | Graft from matched **AniList**: title.english, title.native, synonyms[]. |
| `episode_count` | integer | **TVDB** (authoritative). Cross-check with AniList episodes. |
| `air_date_start` | date | **TVDB** first episode air date. Cross-check AniList startDate. |
| `air_date_end` | date | **TVDB** last episode air date. NULL if ongoing. |
| `synopsis` | text | **AniList** description from matched entry (richer for anime). Fallback: TVDB overview. |
| `primary_image` | text | **AniList** coverImage from matched entry. Fallback: TVDB poster. |
| `tvdb_id` | integer | **TVDB** season ID (structural anchor). Default: `0` if no TVDB match. |

**Process:** TVDB → get seasons → fuzzy match to AniList entries → graft AniList metadata.  
**Principle:** TVDB defines structure, AniList/MAL enrich it.

---

### `season_episodes`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto: `gen_random_uuid()` |
| `season_id` | uuid NOT NULL | FK → entry_seasons. |
| `episode_number` | integer NOT NULL | **TVDB** episode number within season. |
| `absolute_number` | integer | Calculate: sum of previous seasons' episodes + episode_number. |
| `title` | text | **TVDB** translations/eng. Fallback: TVDB name field. |
| `alternate_titles` | text[] | **TVDB** name in native language (if different from title). |
| `air_date` | date | **TVDB** aired date. |
| `runtime_minutes` | integer | **TVDB** runtime. Fallback: AniList duration. |
| `synopsis` | text | **TVDB** translations/eng overview. |
| `primary_image` | text | **TVDB** episode image (still frame). |
| `tvdb_id` | integer | **TVDB** episode ID. Default: `0` if unavailable. |

**Note:** AniList doesn't have per-episode data. TVDB is primary source.

---

### `characters`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto: `gen_random_uuid()` |
| `name` | text NOT NULL | **AniList** name.full (romanized). Cross-check MAL. |
| `sort_name` | text | "Family, Given" for Japanese. Auto-generate. |
| `native_name` | text | **AniList** name.native. |
| `alternate_names` | text[] | **AniList** name.alternative[] (exclude spoilers for display). |
| `description` | text | **AniList** description. Fallback: MAL bio. |
| `primary_image` | text | **MAL** character image (higher quality). Fallback: AniList image.large. |
| `franchise_id` | uuid NOT NULL | Derived from entry's franchise. |
| `wikidata_id` | text | **Wikidata**: character name + "fictional character" + franchise. If absent → `'0'`. |
| `is_active` | boolean | Default: `true`. |
| `slug` | text NOT NULL | `{slugify(name)}-{franchise_slug}`. |
| `details` | jsonb | `{"anilist_id": N, "mal_id": N, "age": "17", "gender": "Female", "blood_type": "O"}` |

**Deduplication:** Characters have global AniList IDs. Consolidate across entries by anilist_id.

---

### `creators`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto: `gen_random_uuid()` |
| `full_name` | text NOT NULL | **AniList** name.full. Cross-check MAL. |
| `sort_name` | text | "Family, Given" for Japanese. Auto-generate. |
| `native_name` | text | **AniList** name.native. |
| `alternate_names` | text[] | **AniList** name.alternative[]. |
| `disambiguation` | text | For common names: add context. Usually NULL. |
| `birth_date` | date | **AniList** dateOfBirth. Fallback: **Wikidata** P569. Fallback: **Wikipedia**. Default: `1900-01-01`. |
| `death_date` | date | **AniList** dateOfDeath. Fallback: **Wikidata** P570. NULL = living. |
| `birth_place` | text | **Wikidata** P19. Fallback: Wikipedia. |
| `nationality` | varchar(2) | **Wikidata** P27 → ISO code. Fallback: infer from native_name script. |
| `biography` | text | **Wikipedia** lead paragraph. Fallback: AniList description. Default: `'Information unavailable.'`. |
| `primary_image` | text | **MAL** person image (higher quality). Fallback: AniList image.large. |
| `wikidata_id` | text | **Wikidata SPARQL**: name + occupation. If absent → `'0'`. |
| `websites` | jsonb | `{"twitter": "url", "official": "url", "anilist_id": N, "mal_id": N}` |
| `details` | jsonb | `{"anilist_id": N, "mal_id": N, "occupations": [...]}` |
| `is_active` | boolean | Default: `true`. |
| `slug` | text NOT NULL | `{slugify(name)}-{birth_year}`. If no birth year: `{slugify(name)}`. |
| `wikidata_confidence` | text | Matching tier used: `T1`, `T2`, `T3`, `T4`, `T5`, or `manual`. |

---

### `companies`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto: `gen_random_uuid()` |
| `name` | text NOT NULL | **AniList** studio name. Use official English name. |
| `native_name` | text | **Wikidata** label in ja/ko/zh. Fallback: Wikipedia. |
| `primary_type` | text | Classify: `animation_studio`, `publisher`, `producer`, `broadcaster`, `record_label`. Infer from usage context. |
| `founded_year` | integer | **Wikidata** P571. Fallback: Wikipedia. |
| `defunct_year` | integer | **Wikidata** P576. NULL if operating. |
| `headquarters_country` | varchar(2) | **Wikidata** P17/P159 → ISO code. Most anime studios → `JP`. |
| `company_summary` | text | **Wikipedia** lead paragraph. 1-2 sentences. |
| `primary_image` | text | **Wikipedia** logo (check license). |
| `parent_company_id` | uuid | **Wikidata** P749. Fallback: Wikipedia. |
| `wikidata_id` | text | **Wikidata SPARQL**: company name + type. If absent → `'0'`. |
| `websites` | jsonb | `{"official": "url", "anilist_id": N}` |
| `is_active` | boolean | Based on defunct_year == NULL. |
| `slug` | text NOT NULL | `{slugify(name)}`. |

---

## Schema: Junction Tables

### `entry_franchises`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto |
| `entry_id` | uuid NOT NULL | FK → entries |
| `franchise_id` | uuid NOT NULL | FK → franchises |
| `franchise_release_order` | integer | Sort all franchise entries by release_date, assign sequential. Default: `1`. |

---

### `entry_creators`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto |
| `entry_id` | uuid NOT NULL | FK → entries |
| `creator_id` | uuid NOT NULL | FK → creators |
| `role_id` | uuid NOT NULL | FK → creator_roles. Map **AniList** staff.role to our role slugs. |
| `character_id` | uuid | FK → characters. Only for voice actors: links VA to character. |
| `language` | varchar(10) | For VAs: **AniList** voiceActors.languageV2 → `ja`, `en`, `ko`, `zh`. |
| `credit_order` | integer | Directors first, then writers, then staff, then VAs. Within VAs, MAIN chars first. Default: `1`. |
| `notes` | text | Optional context. Usually NULL. |

**Role Mapping (AniList → creator_roles):**
- "Director" → director
- "Original Creator" → original_creator
- "Series Composition" → series_composition
- "Script" → script
- "Character Design" → character_design
- "Music" → music
- Voice actors use `voice_actor` role + character_id

---

### `entry_characters`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto |
| `entry_id` | uuid NOT NULL | FK → entries |
| `character_id` | uuid NOT NULL | FK → characters |
| `role` | text | **AniList** character role: `main`, `supporting`, `background`. Default: `supporting`. |

---

### `entry_companies`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto |
| `entry_id` | uuid NOT NULL | FK → entries |
| `company_id` | uuid NOT NULL | FK → companies |
| `role_id` | uuid NOT NULL | FK → company_roles. **AniList** studios (isMain:true) → `animation_studio`. MAL producers → `producer`. |
| `credit_order` | integer | Main studio first. Default: `1`. |
| `notes` | text | e.g. "Season 1 only". Usually NULL. |

---

### `entry_genres`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto |
| `entry_id` | uuid NOT NULL | FK → entries |
| `genre_id` | uuid NOT NULL | FK → genres. **AniList** genres[] mapped to our genre table. |
| `is_primary` | boolean | First 3 AniList genres → `true`. Rest → `false`. |

---

### `entry_tags`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto |
| `entry_id` | uuid NOT NULL | FK → entries |
| `tag_id` | uuid NOT NULL | FK → tags. **AniList** tags[] with rank ≥ 80%. Exclude spoiler tags. |

---

### `entry_translations`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto |
| `entry_id` | uuid NOT NULL | FK → entries |
| `locale_code` | varchar(10) NOT NULL | Target locale: `en`, `ja`, `ko`, `zh`, etc. |
| `translated_title` | text NOT NULL | **AniList** title.english → `en`. title.native → origin locale. |

**Minimum:** Every entry gets `en` + origin-language rows.

---

### `entry_relationships`

| Column | Type | Strategy |
|--------|------|----------|
| `id` | uuid | Auto |
| `source_entry_id` | uuid NOT NULL | FK → entries (from) |
| `target_entry_id` | uuid NOT NULL | FK → entries (to) |
| `relationship_type_id` | uuid NOT NULL | FK → relationship_types. **AniList** relationType mapped. |
| `notes` | text | Optional context. |

**AniList → relationship_types mapping:**
- ADAPTATION → adaptation
- PREQUEL → prequel
- SEQUEL → sequel (only for cross-entry, not within consolidated)
- SIDE_STORY → side_story (validate title similarity to avoid cross-franchise contamination)
- SPIN_OFF → spinoff
- ALTERNATIVE → alternative
- SOURCE → source

---

## Schema: Lookup Tables

### `media_types` (seeded)

| name | display_name |
|------|--------------|
| anime-series | Anime Series |
| anime-movie | Anime Movie |
| anime-ova | Anime OVA |
| anime-ona | Anime ONA |
| anime-special | Anime Special |
| manga | Manga |
| light-novel | Light Novel |
| manhua | Manhua |
| manhwa | Manhwa |

### `creator_roles` (seeded, 33 roles)

**Categories:** animation, audio, cast, direction, music, production, story, visual, writing

### `company_roles` (seeded, 10 roles)

animation_studio, broadcaster, developer, distributor, manufacturer, producer, publisher, record_label, serialization, studio

### `genres` (seeded, 42 genres)

Action, Adventure, Comedy, Drama, Fantasy, Horror, Mecha, Mystery, Psychological, Romance, Sci-Fi, Slice of Life, Sports, Supernatural, Thriller, etc.

### `relationship_types` (seeded)

adaptation, alternative, character, compilation, contains, other, parent, prequel, sequel, side_story, spinoff, summary, main_story, source

### `locales` (seeded)

en, ja, ko, zh, de, es, fr, it, pt, ru, etc.

### `countries` (seeded, 50 countries)

JP, US, KR, CN, TW, GB, CA, AU, DE, FR, etc.

---

## Gap-Filling Process

When scanning for missing data:

1. **Identify NULL columns** that should have values
2. **Check source priority** — AniList → MAL → TVDB → Wikidata → Wikipedia → Web Search
3. **Apply matching logic** to find correct entity
4. **Retrieve value** from best available source
5. **If unfindable after reasonable effort** → apply default value
6. **Document** in LESSONS.md what was searched and why default was applied

---

*This document is the source of truth for anime/manga content population. Update as new patterns emerge.*
