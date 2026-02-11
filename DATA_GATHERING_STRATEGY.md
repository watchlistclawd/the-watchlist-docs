# Data Gathering Strategy — Column-by-Column

> Written 2026-02-11. Covers the 23 core tables (excluding product/music/retail).
> Focus: Anime/Manga MVP first, extensible to all media later.
> Rule: Save ALL external IDs encountered. When `wikidata_id` is confirmed absent, set to `'0'`.

---

## Source Priority (cheapest/fastest first)

| Priority | Source | Auth | Rate Limits | Best For |
|----------|--------|------|-------------|----------|
| 1 | **AniList GraphQL** | None | 90 req/min | Anime/manga metadata, relations, characters, staff |
| 2 | **Jikan (MAL proxy)** | None | 3 req/sec | Anime/manga, character images, voice actors |
| 3 | **TVDB** | API key | 100 req/day (free) | Season/episode structure, air dates, images |
| 4 | **Wikidata SPARQL** | None | Generous | External IDs, founding years, nationalities, bios |
| 5 | **Wikipedia API** | None | Polite | Descriptions, founding info, biographical data |
| 6 | **MusicBrainz** | None | 1 req/sec | Music entries (future) |
| 7 | **Fan wikis (Fandom)** | Scrape | — | Deep character info, episode synopses |
| 8 | **Google Image Search** | SerpAPI/Serper | Paid | Fallback images only |

### ID Map (save in `details` or `websites` jsonb)

Every entity should accumulate IDs as discovered:
- `anilist_id`, `mal_id` — anime/manga entries, characters, creators
- `tvdb_id` — dedicated column on `entry_seasons` and `season_episodes`; also store in `entries.details`
- `wikidata_id` — dedicated column on `franchises`, `entries`, `characters`, `creators`, `companies`
- `musicbrainz_id` — future (music entries, creators)
- `imdb_id` — future (movies/TV)
- `igdb_id` — future (games)

### ⚠️ AniList ID Namespacing

**AniList IDs are NOT globally unique.** They are unique only within each entity type (Media, Character, Staff, Studio). ID 16498 is both "Shingeki no Kyojin" (Media) and "Takako Kimura" (Character).

This is safe in our schema because IDs are stored on type-specific tables:
- `entries.details.anilist_ids` → always AniList Media IDs
- `characters.details.anilist_id` → always AniList Character IDs
- `creators.details.anilist_id` → always AniList Staff IDs

**The risk is `entries.details.anilist_ids`** — AniList treats anime and manga as separate Media entries with separate ID sequences, but they share the same `Media` type. A consolidated anime entry stores anime AniList IDs; a manga entry stores manga AniList IDs. If `media_type_id` is wrong on an entry, the AniList IDs become ambiguous. Always maintain accurate `media_type_id`.

**Rule:** Never store bare AniList IDs in a context-free location (e.g. a flat cross-reference table) without also storing the entity type (media/character/staff/studio).

---

## Table-by-Table, Column-by-Column

---

### 1. `franchises`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `name` | **AniList**: Use the series name (romaji). For multi-media franchises (e.g. "Attack on Titan"), pick the most commonly known English name. Cross-reference **MAL** and **Wikipedia** to verify canonical name. |
| `native_name` | **AniList** `title.native` (Japanese/Korean/Chinese). For non-anime, **Wikipedia** (native language article title) or **Wikidata** label in original language. |
| `alternate_names` | Union of: **AniList** `title.english` + `synonyms`, **MAL** `title_english` + `title_synonyms`. Deduplicate. Include common abbreviations (e.g. "AoT", "SnK"). |
| `parent_id` | Manual determination. Most franchises are top-level (NULL). Sub-franchises (e.g. "Boruto" under "Naruto") set via inspection of AniList relations + Wikipedia franchise articles. |
| `description` | **Wikipedia** lead paragraph (MediaWiki API `action=query&prop=extracts&exintro=true`). Fallback: AniList franchise description if a "media franchise" article doesn't exist. Keep to 2-3 sentences. |
| `primary_image` | **AniList** cover of the most popular entry in the franchise. Fallback: **Google Image Search** for franchise logo/key art. Store URL; download later. |
| `wikidata_id` | **Wikidata SPARQL**: Search by name + type "media franchise" or "anime television series". Match carefully. If confirmed absent → `'0'`. |
| `websites` | JSON: `{"wikipedia": "url", "anilist_id": N, "mal_id": N}`. Populate from AniList/MAL. Also store official website URL from Wikipedia infobox if available. |
| `slug` | `{name}-franchise`. e.g. `attack-on-titan-franchise`. See Slug Strategy section. |
| `created_at` / `updated_at` | Auto |

**Process**: AniList → get all related media → derive franchise name → Wikidata lookup → Wikipedia description → generate slug.

---

### 2. `entries`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `media_type_id` | **AniList** `format` mapped to our types: TV→tv, TV_SHORT→tv, MOVIE→movie, OVA→ova, ONA→ona, SPECIAL→special, MUSIC→music, MANGA→manga, NOVEL→novel, ONE_SHOT→manga. **MAL** `type` as fallback/cross-check. |
| `title` | **AniList** `title.romaji` (our canonical). This is the primary display title in our system. |
| `sort_title` | Strip leading articles ("The", "A"). For Japanese, use romaji. Auto-generate from `title`. |
| `alternate_titles` | **Synonyms and shorthands only** — NOT official translations (those go in `entry_translations`). Sources: AniList `synonyms[]`, MAL `title_synonyms[]`. Examples: "AoT", "SnK", "Shingeki". Deduplicate, exclude canonical title and any officially published localized titles. |
| `release_date` | **AniList** `startDate` (year/month/day). Fallback: **MAL** `aired.from` or `published.from`. For partial dates (year-only), store as YYYY-01-01 and note in details. |
| `status` | **AniList** `status` mapped: RELEASING→airing, FINISHED→released, NOT_YET_RELEASED→upcoming, CANCELLED→cancelled, HIATUS→hiatus. |
| `description` | **AniList** `description` (HTML → plaintext). Fallback: **MAL** synopsis. Clean up spoiler tags, source citations. |
| `nsfw` | **MAL** `rating` == "rx" or "r+" → true. AniList `isAdult`. Default false. |
| `locale_code` | Determine from origin: Japanese anime/manga → `ja`. Korean manhwa → `ko`. Chinese manhua → `zh`. English-origin → `en`. AniList `countryOfOrigin` is the key signal. |
| `primary_image` | **AniList** `coverImage.extraLarge`. Fallback: **MAL** main image. Store URL; download later for self-hosting. |
| `wikidata_id` | **Wikidata SPARQL**: Search by title + media type. Match AniList/MAL IDs if Wikidata has them (P8731 for AniList, P4086 for MAL). If confirmed absent → `'0'`. |
| `details` | JSON object — **this is our external ID warehouse**: `{"anilist_id": N, "mal_ids": [N], "tvdb_id": N, "episodes": N, "chapters": N, "volumes": N, "source": "manga/light_novel/etc", "external_links": [...], "consolidated": true/false, "duration_minutes": N, "average_score": N, "popularity": N}`. Sourced from AniList + MAL + TVDB. |
| `slug` | `{title}-{media_type}-{release_year}`. e.g. `attack-on-titan-anime-2013`. See Slug Strategy section. |
| `created_at` / `updated_at` | Auto |

**Consolidation rule (TV anime)**: AniList splits sequel seasons into separate entries. We consolidate all TV sequel chains into ONE entry. Each AniList season becomes an `entry_season`. Movies, OVAs, specials, and spin-offs stay as separate entries. The pipeline's `crawl_relations` handles this via SEQUEL/PREQUEL chain walking.

---

### 3. `entry_seasons`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `entry_id` | FK → parent entry (the consolidated TV entry) |
| `season_number` | **TVDB** season number. This is the structural backbone — TVDB defines what a "season" is. |
| `title` | **TVDB** season name. Enriched with **AniList** `title.romaji` for the matched AniList entry (fuzzy match by title + year + episode count). |
| `alternate_titles` | Graft from matched **AniList** entry: `title.english`, `title.native`, `synonyms[]`. TVDB translations endpoint for additional languages. |
| `episode_count` | **TVDB** season episode count (authoritative — defines structure). Cross-check with matched **AniList** `episodes` to validate the match. |
| `air_date_start` | **TVDB** season first episode air date (authoritative). Cross-check with matched **AniList** `startDate`. |
| `air_date_end` | **TVDB** season last episode air date (authoritative). Cross-check with matched **AniList** `endDate`. |
| `synopsis` | **AniList** `description` from the matched AniList entry (richer than TVDB for anime). Fallback: **TVDB** season overview. |
| `primary_image` | **AniList** `coverImage.extraLarge` from the matched entry (anime-specific art). Fallback: **TVDB** season poster. |
| `tvdb_id` | **TVDB** season ID. Dedicated column — this is our structural anchor. |
| `created_at` / `updated_at` | Auto |

**Process**: TVDB is the source of truth for season structure. AniList/MAL data is grafted on via fuzzy matching.
1. Fetch TVDB series → get seasons (number, episode count, air dates)
2. For each TVDB season, fuzzy-match to one or more AniList entries by title + year + episode count
3. Graft AniList metadata (synopsis, images, titles, alt titles) onto the TVDB skeleton
4. AniList entries that don't match a TVDB season get flagged for manual review
5. Store matched AniList/MAL IDs in parent entry's `details` jsonb for traceability

**Handling AniList/MAL splits within a single TVDB season**:
Anime production committees love splitting cours, arcs, and parts into separate marketing units. AniList and MAL treat these as separate entries because they track per-broadcast-run. TVDB doesn't — it groups by the actual series structure.

Examples:
- **AoT Final Season**: AniList has 4 separate entries (Final Season, Part 2, Final Chapters Part 1, Final Chapters Part 2). TVDB has this as one Season 4 with ~30 episodes. **We follow TVDB.** One `entry_season` row for Season 4.
- **Demon Slayer**: AniList splits each arc (Mugen Train Arc TV, Entertainment District, Swordsmith Village, Hashira Training). TVDB may group differently by broadcast season. **We follow TVDB.**
- **JoJo's**: AniList has separate entries for Stardust Crusaders S1 and S2. TVDB may combine them into one season. **We follow TVDB.**

When multiple AniList entries map to a single TVDB season:
- The season gets **one** `entry_season` row (TVDB's structure wins)
- `episode_count` comes from TVDB (the actual episode total)
- `synopsis` can merge or pick the best AniList description
- All matched AniList IDs are stored in the parent entry's `details.anilist_season_ids` array for traceability
- `alternate_titles` accumulates from all matched AniList entries

When an AniList entry spans multiple TVDB seasons (rare but possible):
- Each TVDB season still gets its own `entry_season` row
- The AniList entry is noted as matching multiple seasons in `details`

The principle: **TVDB defines structure, AniList/MAL enrich it.** Never let AniList's marketing-driven splits dictate our season boundaries.

---

### 4. `season_episodes`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `season_id` | FK → entry_seasons |
| `episode_number` | **TVDB** episode number within season. Cross-check with AniList episode count. |
| `absolute_number` | Calculate: sum of all previous seasons' episode counts + this episode's number. TVDB sometimes has this natively. |
| `title` | **TVDB** `/episodes/{id}/translations/eng` → English title. Fallback: TVDB `name` field (series primary language). Always prefer English for display. |
| `alternate_titles` | TVDB `name` field (native/original language title, e.g. Japanese) goes here when English title is available and differs. Additional languages from TVDB translations endpoint if needed. |
| `air_date` | **TVDB** `aired` date. This is authoritative for episode-level air dates. Cross-check AniList `airingSchedule` if available. |
| `runtime_minutes` | **TVDB** `runtime`. Fallback: **AniList** `duration` (per-episode average for the season). |
| `synopsis` | **TVDB** `/episodes/{id}/translations/eng` → English overview. Fallback: TVDB `overview` field. Leave NULL if no English synopsis available. |
| `primary_image` | **TVDB** episode image (`image` field). This is TVDB's killer feature — per-episode stills. |
| `tvdb_id` | **TVDB** episode ID. Dedicated column. |
| `created_at` / `updated_at` | Auto |

**Process**: Fetch TVDB series → iterate seasons → iterate episodes → insert. TVDB is the primary source for episode-level data. AniList doesn't have per-episode detail.

---

### 5. `entry_translations`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `entry_id` | FK → entries |
| `locale_code` | Target locale code (e.g. `en`, `ja`, `ko`, `zh`) |
| `translated_title` | **AniList** `title.english` → `en` row. `title.native` → `ja`/`ko`/`zh` row (based on `countryOfOrigin`). **MAL** `title_english`, `title_japanese`. **TVDB** translations endpoint for additional languages. |
| `created_at` / `updated_at` | Auto |

**Minimum**: Every entry gets `en` and original-language rows. We always have these from AniList.

---

### 6. `entry_genres`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `entry_id` | FK → entries |
| `genre_id` | FK → genres. **AniList** `genres[]` mapped to our genre table. **MAL** genres as cross-check. AniList genres are cleaner (fewer duplicates). |
| `is_primary` | First 3 genres listed by AniList → `true`. Rest → `false`. Heuristic: AniList lists genres in relevance order. |
| `created_at` | Auto |

**Genre mapping**: AniList genres map 1:1 to our seed data (Action, Adventure, Comedy, Drama, etc.). Any new genres discovered → create in `genres` table. MAL sometimes has more specific genres — merge if they match our taxonomy.

---

### 7. `entry_tags`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `entry_id` | FK → entries |
| `tag_id` | FK → tags. **AniList** `tags[]` (AniList has rich tag taxonomy: ~300+ tags with categories). Filter by `rank >= 80` (% of user votes) to keep only high-confidence tags. Map to our tags table; create new tags as discovered. |
| `created_at` | Auto |

**Tag filtering**: AniList tags include spoiler tags — exclude any with `isMediaSpoiler: true`. Use `rank` threshold (80%+) to keep only high-confidence tags. Category field from AniList maps to our `tags.category`.

---

### 8. `entry_relationships`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `source_entry_id` | FK → entries (the "from" entry) |
| `target_entry_id` | FK → entries (the "to" entry) |
| `relationship_type_id` | FK → relationship_types. **AniList** `relations[]` has `relationType`: ADAPTATION, PREQUEL, SEQUEL, PARENT, SIDE_STORY, CHARACTER, SUMMARY, ALTERNATIVE, SPIN_OFF, OTHER, COMPILATION, CONTAINS. Map to our types. |
| `notes` | Optional context. e.g. "Based on manga chapters 1-50" for adaptations. Sourced from Wikipedia or manual review. |
| `created_at` | Auto |

**AniList → Our mapping**:
- ADAPTATION → adaptation
- PREQUEL → prequel
- SEQUEL → sequel (NOTE: sequels within consolidated TV entries are NOT stored here — they become seasons)
- PARENT → parent
- SIDE_STORY → side_story (CAREFUL: can cross into unrelated franchises — validate title similarity)
- SPIN_OFF → spinoff
- ALTERNATIVE → alternative
- SUMMARY → summary
- OTHER → other
- SOURCE → source
- COMPILATION/CONTAINS → parent or main_story as appropriate

**Cross-franchise contamination guard**: Before adding a SIDE_STORY relationship, verify the target entry shares significant title words or franchise with the source. If not (e.g. Lupin × Conan crossover), skip or tag as `other`.

---

### 9. `entry_franchises`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `entry_id` | FK → entries |
| `franchise_id` | FK → franchises |
| `franchise_release_order` | Integer ordering within franchise. Determined by: sort all franchise entries by `release_date` ASC, assign sequential numbers. Ties broken by media type priority (manga/LN before anime adaptation, TV before movie). |
| `created_at` | Auto |

**Process**: After all entries for a franchise are created, query by franchise, sort by release_date, assign order numbers.

---

### 10. `entry_characters`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `entry_id` | FK → entries |
| `character_id` | FK → characters |
| `role` | **AniList** character `role`: "MAIN", "SUPPORTING", "BACKGROUND". Store as lowercase. **MAL** also provides this via Jikan. |
| `created_at` | Auto |

**Process**: AniList `characters` connection on each media → for consolidated entries, take the union of characters across all seasons. If a character appears in multiple AniList entries within a consolidated chain, they appear once in entry_characters with the highest role (MAIN > SUPPORTING > BACKGROUND).

---

### 11. `entry_creators`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `entry_id` | FK → entries |
| `creator_id` | FK → creators |
| `role_id` | FK → creator_roles. **AniList** `staff[].role` text → map to our role slugs. Mapping needed (AniList uses free-text roles like "Director", "Original Creator", etc.). **MAL** staff roles via Jikan as cross-check. |
| `character_id` | FK → characters. Only populated for voice actors: links the VA to the specific character they voice. **AniList** `characters[].voiceActors[]` provides this mapping directly. |
| `language` | For voice actors: **AniList** `voiceActors[].languageV2` → "Japanese", "English", "Korean", "Chinese", etc. Convert to locale codes: `ja`, `en`, `ko`, `zh`. Only keep these 4 languages. |
| `credit_order` | Integer. AniList doesn't explicitly order staff, but we can use: directors first, then writers, then key staff, then VAs. Within VAs, order by character role (MAIN characters' VAs first). |
| `notes` | Optional. e.g. "Episodes 1-12" for role-specific notes. Usually NULL for initial data load. |
| `created_at` / `updated_at` | Auto |

**AniList role → our creator_role mapping** (partial):
- "Director" → director
- "Original Creator" → original_creator
- "Series Composition" → series_composition
- "Script" / "Screenplay" → script / screenplay
- "Character Design" → character_design
- "Music" → music
- "Sound Director" → sound_director
- "Art Director" → art_director
- "Animation Director" → animation_director
- "Key Animation" → key_animation
- "Storyboard" → storyboard
- "Episode Director" → episode_director
- Voice actors handled separately via character connection

For unmapped AniList roles, normalize to closest match in our 33 creator_roles. If no match, flag for manual review and add new role to `creator_roles` table.

**Creator Role Blacklist** (from `config/role_blacklists.py` — substring match, case-insensitive):
<!-- Tags: blacklist, role blacklist, creator role blacklist, filter roles -->
AniList roles matching any of these substrings are **dropped** before import. Blacklist approach (not whitelist) so new/unknown roles are included by default.
- **Production admin:** assistant producer, associate producer, planning producer, planning, production manager, production assistant, production coordination
- **Low-level animation:** 2nd key animation, in-between animation, layout
- **Art/color/photo:** art design, background art, color design, color setting, photography
- **Music sub-roles:** composition, arrangement, lyrics *(keeps "Theme Song Performance" and "Music")*
- **Audio technical:** sound effects, recording engineer
- **Localization:** adr script
- **Misc technical:** cg animation, prop design, special effects, publicity, editing, finishing, endcard, talent coordination

**Surviving creator_roles (33):**
animation: animation_director, chief_animation_director, key_animation
audio: music, music_production, sound_director, sound_production
cast: adr_director, narrator, voice_actor
direction: assistant_director, chief_director, director, episode_director, unit_director
music: insert_song_performance, theme_song_performance
production: editor, executive_producer, producer
story: author, original_character_design, original_creator, original_story
visual: art_director, artist, cgi_director, character_design, illustrator, storyboard
writing: screenplay, script, series_composition

---

### 12. `entry_companies`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `entry_id` | FK → entries |
| `company_id` | FK → companies |
| `role_id` | FK → company_roles. **AniList** `studios[]` → `animation_studio` (if `isMain: true`) or `studio`. **MAL** provides: studios, producers. Map accordingly: MAL `studios` → `animation_studio`, MAL `producers` → `producer`. MAL `licensors` → **dropped** (blacklisted). |
| `credit_order` | AniList: main studio first (`isMain: true`), then others. MAL: order as listed. |
| `notes` | Usually NULL. Could note "Season 1 only" if studio changes between seasons. |
| `created_at` | Auto |

**Company Role Blacklist** (from `config/role_blacklists.py` — substring match, case-insensitive):
<!-- Tags: blacklist, role blacklist, company role blacklist, filter roles -->
- `other` — AniList "Producer/Other" catch-all
- `licensor` — regional distribution rights (noise, not creative involvement)

**Surviving company_roles (10):** animation_studio, broadcaster, developer, distributor, manufacturer, producer, publisher, record_label, serialization, studio

**Process**: AniList studios + MAL studios/producers → deduplicate by company name → assign roles → filter blacklisted → insert.

---

### 13. `characters`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `name` | **AniList** `name.full` (romanized). Cross-check **MAL** via Jikan. Use most widely recognized romanization. |
| `sort_name` | "Last, First" format when applicable. For Japanese names, this is tricky — most anime characters use given-name-first in English. Store as-is or "Family Given" for Japanese ordering. Auto-generate. |
| `native_name` | **AniList** `name.native` (Japanese/Korean/Chinese characters). |
| `alternate_names` | **AniList** `name.alternative[]` + `name.alternativeSpoiler[]` (exclude spoilers for public display, but store them). **MAL** alternate spellings via Jikan. |
| `description` | **AniList** `description` (HTML → plaintext). Usually a paragraph about the character. Fallback: **MAL** character bio. Tertiary: **Fan wiki** (Fandom) character page intro. |
| `primary_image` | **MAL** character image (via Jikan — higher quality than AniList for characters). Fallback: **AniList** `image.large`. |
| `franchise_id` | FK → franchises. Determined by: which franchise does this character primarily belong to? If they appear in AoT anime + AoT manga, franchise is "Attack on Titan". The pipeline derives this from the entry's franchise. |
| `wikidata_id` | **Wikidata SPARQL**: Search by character name + "fictional character" + franchise context. Many popular anime characters have Wikidata entries. If absent → `'0'`. |
| `is_active` | Default `true`. Set `false` only for erroneous/duplicate entries during cleanup. |
| `slug` | `{name}-{franchise}`. e.g. `armin-arlert-attack-on-titan`. See Slug Strategy section. |
| `details` | JSON: `{"anilist_id": N, "mal_id": N, "age": "17", "gender": "Female", "blood_type": "O", "date_of_birth": {"month": 2, "day": 10}}`. AniList has `age`, `gender`, `bloodType`, `dateOfBirth`. |
| `created_at` / `updated_at` | Auto |

**Deduplication**: Characters appear across multiple AniList entries. Consolidate by `anilist_id` (each character has one global AniList ID). MAL character ID is separate — store both. Match AniList↔MAL by name+franchise cross-reference.

---

### 14. `creators`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `full_name` | **AniList** `name.full` (romanized). Cross-check **MAL**. For Japanese names, AniList uses "Given Family" order. |
| `sort_name` | "Family, Given" for Japanese. "Last, First" for Western. Auto-generate from `full_name` + nationality detection. |
| `native_name` | **AniList** `name.native`. |
| `disambiguation` | For common names: add context. e.g. "Yuki Kaji (voice actor)". Usually NULL unless needed. Manually determined. |
| `birth_date` | **AniList** `dateOfBirth` (year/month/day — sometimes partial). Fallback: **Wikidata** P569 (date of birth). Fallback: **Wikipedia** infobox. |
| `death_date` | **AniList** `dateOfDeath`. Fallback: **Wikidata** P570. |
| `birth_place` | **Wikidata** P19 (place of birth) → resolve to city/prefecture. Not available from AniList. Fallback: **Wikipedia** infobox "Born" field. |
| `nationality` | **Wikidata** P27 (country of citizenship) → ISO 2-letter code. Fallback: infer from `native_name` (kanji → JP, hangul → KR, hanzi → CN). AniList `languageV2` on voice actor roles can hint at this. |
| `biography` | **AniList** `description` (often minimal). Better: **Wikipedia** lead paragraph. Fan wikis for lesser-known creators. Keep concise — 2-3 sentences. |
| `primary_image` | **MAL** person image (via Jikan — usually higher quality). Fallback: **AniList** `image.large`. Tertiary: **Wikipedia** infobox image (check license). |
| `wikidata_id` | **Wikidata SPARQL**: Search by name + occupation (voice actor/animator/mangaka). Most industry professionals have entries. If absent → `'0'`. |
| `websites` | JSON: `{"twitter": "url", "instagram": "url", "official_site": "url", "anilist_id": N, "mal_id": N}`. AniList sometimes has social links. Wikipedia external links section. |
| `details` | JSON: `{"anilist_id": N, "mal_id": N, "occupations": ["Voice Actor", "Singer"], "years_active": "2005-present", "notable_roles": [...]}`. |
| `is_active` | Default `true`. |
| `slug` | `{name}-{birth_year}`. e.g. `hiroyuki-sawano-1980`. If birth year is positively confirmed NULL in all sources, use `{name}` only. See Slug Strategy section. |
| `created_at` / `updated_at` | Auto |

**Deduplication**: AniList staff have global IDs. Match AniList↔MAL by name. Wikidata helps disambiguate common names (e.g. multiple "Yuki" voice actors).

---

### 15. `companies`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `name` | **AniList** studio name. Cross-check **MAL** studios/producers list. Use official English name (e.g. "MAPPA" not "マッパ"). |
| `native_name` | **Wikidata** label in native language. Fallback: **Wikipedia** native-language article title. For Japanese studios, look for katakana/kanji name. For Chinese studios, look for simplified Chinese name. |
| `primary_type` | Classify: "animation_studio", "publisher", "record_label", "game_developer", "broadcaster", "licensor". Infer from how they appear in our data: if they're listed as AniList studio → `animation_studio`. If MAL producer → check Wikipedia for more specificity. |
| `founded_year` | **Wikidata** P571 (inception). Fallback: **Wikipedia** infobox "Founded" field. Not available from AniList/MAL. |
| `defunct_year` | **Wikidata** P576 (dissolved/abolished). Fallback: Wikipedia. NULL if still operating. |
| `headquarters_country` | **Wikidata** P17 (country) or P159 (headquarters location) → ISO 2-letter code. Fallback: Wikipedia infobox "Headquarters". Most anime studios → `JP`. |
| `company_summary` | **Wikipedia** lead paragraph. Keep to 1-2 sentences. Not available from AniList/MAL. |
| `primary_image` | **Wikipedia** infobox logo (check license). Fallback: **Google Image Search** for official logo. Store URL. |
| `parent_company_id` | **Wikidata** P749 (parent organization). Fallback: Wikipedia "Parent" in infobox. e.g. Aniplex's parent is Sony Music Entertainment Japan. Self-referencing FK — insert parent first. |
| `wikidata_id` | **Wikidata SPARQL**: Search by company name + type (animation studio, publisher, etc.). Most studios have entries. If absent → `'0'`. |
| `websites` | JSON: `{"official": "url", "twitter": "url", "anilist_id": N, "mal_id": N}`. AniList has studio IDs. Wikipedia external links for official website. |
| `is_active` | `true` if still operating. Based on `defunct_year` == NULL. |
| `slug` | `{name}`. e.g. `mappa`, `wit-studio`. See Slug Strategy section. |
| `created_at` / `updated_at` | Auto |

---

### 16. `genres`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `name` | Slug-style: `action`, `adventure`, `sci_fi`. Already seeded (42 genres). |
| `display_name` | Human-readable: "Action", "Adventure", "Sci-Fi". Already seeded. |
| `parent_id` | Hierarchical. e.g. "Mecha" parent could be "Sci-Fi". Define manually based on genre taxonomy. Most are top-level (NULL). |
| `media_type_id` | Optional scope. Most genres are universal (NULL = applies to all media). Some are medium-specific: "Shounen" → anime/manga only. |
| `description` | Short definition. Write manually or pull from **Wikipedia** genre articles. |
| `is_active` | Default `true`. |
| `created_at` / `updated_at` | Auto |

**New genres**: If AniList or MAL returns a genre not in our 42, add it. Merge similar genres (e.g. MAL "Martial Arts" and AniList doesn't have it separately → add as new genre).

---

### 17. `tags`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `name` | Slug-style from AniList tag names. e.g. `time-skip`, `male-protagonist`. |
| `display_name` | AniList tag name verbatim: "Time Skip", "Male Protagonist". |
| `category` | **AniList** tag `category`: "Theme-Other", "Cast-Main Cast", "Setting-Universe", etc. Map to clean categories: "theme", "cast", "setting", "demographic". |
| `description` | **AniList** tag `description` (AniList provides this for every tag). |
| `created_at` / `updated_at` | Auto |

**Expansion**: AniList has ~350 tags. We seeded 48. As we encounter new tags during entry processing, add them to the table. Only import tags with ≥80% rank agreement.

---

### 18. `locales`

| Column | Strategy |
|--------|----------|
| `id` | PK is `code` |
| `code` | IETF language tag: `en`, `ja`, `ko`, `zh`, `fr`, `de`, `es`, `pt`, `it`, etc. Already seeded. |
| `name` | English name: "English", "Japanese", etc. Already seeded. |
| `native_name` | Self-referential name: "English", "日本語", "한국어", etc. Already seeded. |
| `is_active` | Default `true`. |
| `created_at` | Auto |

**Mostly static**. Expand if we encounter new languages from TVDB translations or user demand.

---

### 19. `countries`

| Column | Strategy |
|--------|----------|
| `id` | PK is `code` |
| `code` | ISO 3166-1 alpha-2. Already seeded. |
| `name` | English name. Already seeded. |
| `is_active` | Default `true`. |
| `created_at` | Auto |

**Static lookup table**. Seeded from ISO standard. No external sources needed.

---

### 20. `media_types`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `name` | Slug: `anime`, `manga`, `tv`, `movie`, etc. Already seeded (15 types). |
| `display_name` | Human: "Anime", "Manga", "TV", "Movie". Already seeded. |
| `description` | Short definition. Write manually. |
| `is_active` | Default `true`. |
| `created_at` / `updated_at` | Auto |

**Mostly static**. May add types as we expand beyond anime/manga (e.g. `podcast`, `web_series`).

---

### 21. `relationship_types`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `name` | Slug: `sequel`, `prequel`, `adaptation`, etc. Already seeded (12 types). |
| `display_name` | Human: "Sequel", "Prequel", "Adaptation". Already seeded. |
| `inverse_name` | The reverse: `sequel` ↔ `prequel`, `adaptation` ↔ `source`, `parent` ↔ `side_story`. Already seeded. |
| `inverse_display_name` | Human-readable inverse. Already seeded. |
| `is_directional` | `true` for most (sequel/prequel have direction). `false` for symmetric relationships like `alternative`. |
| `description` | Short definition. Write manually. |
| `created_at` / `updated_at` | Auto |

**Mostly static**. The AniList relation types all map to our existing 12.

---

### 22. `creator_roles`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `name` | Slug: `director`, `voice_actor`, `original_creator`, etc. Already seeded (46 roles). |
| `display_name` | Human: "Director", "Voice Actor", "Original Creator". Already seeded. |
| `category` | Group: "direction", "writing", "art", "music", "voice", "production". Manually categorized. |
| `description` | Short definition. Write manually or leave NULL. |
| `is_active` | Default `true`. |
| `created_at` / `updated_at` | Auto |

**Expansion**: AniList uses free-text role strings. New roles encountered during processing → normalize to existing or add new. Keep granularity manageable.

---

### 23. `company_roles`

| Column | Strategy |
|--------|----------|
| `id` | Auto-generated UUID |
| `name` | Slug: `animation_studio`, `publisher`, `licensor`, etc. Already seeded (11 roles). |
| `display_name` | Human: "Animation Studio", "Publisher", "Licensor". Already seeded. |
| `description` | Short definition. |
| `is_active` | Default `true`. |
| `created_at` / `updated_at` | Auto |

**Expansion**: Add roles as needed: `streaming_platform`, `production_committee_member`, etc.

---

## Cross-Cutting Strategies

### Wikidata ID Harvesting

For every entity type with `wikidata_id`:

1. **Batch SPARQL queries**: Query Wikidata for anime/manga series, characters, people, studios in bulk
2. **Match by external ID**: Wikidata often has AniList (P8731) and MAL (P4086) IDs — match these first
3. **Match by name**: For entities without AniList/MAL Wikidata properties, search by label + instance-of type
4. **Confirmed absent**: After checking both ID-match and name-match, if nothing found → set `wikidata_id = '0'`
5. **Harvest extra IDs**: When we find a Wikidata entry, also grab: IMDB (P345), TVDB (P4835), MusicBrainz (P434/P436), official website (P856)

### Image Strategy

1. **Phase 1** (now): Store image URLs from AniList/MAL/TVDB
2. **Phase 2** (later): Download to self-hosted storage, update URLs
3. **Fallback chain**: AniList → MAL/Jikan → TVDB → Wikipedia (Commons) → Google Image Search (Serper API)
4. **Characters**: MAL/Jikan images tend to be better quality than AniList
5. **Episodes**: TVDB is the only source with per-episode stills
6. **Companies**: Wikipedia/Commons for logos, Google for fallbacks

### Slug Strategy
<!-- Tags: slug, slugging, slug strategy, slug convention, slug format -->

All slugs: lowercase, hyphenated, ASCII-safe. Unique per table.

| Table | Format | Example |
|-------|--------|---------|
| **characters** | `{name}-{franchise}` | `armin-arlert-attack-on-titan` |
| **companies** | `{name}` | `mappa`, `wit-studio` |
| **creators** | `{name}-{birth_year}` | `hiroyuki-sawano-1980` |
| **creators** (no birth year) | `{name}` — only when birth year is positively confirmed NULL across all sources | `some-obscure-animator` |
| **entries** | `{title}-{media_type}-{release_year}` | `attack-on-titan-anime-2013` |
| **franchises** | `{name}-franchise` | `attack-on-titan-franchise` |
| **products** | `{name}-{product_type}-{manufacturer}-{yyyyMMdd}` | `eren-yeager-figure-bandai-20230915` |
| **retailers** | `{name}-{region}` | `amazon-us`, `cdjapan-jp` |

### Details/Websites JSONB Convention

All external IDs go in `details` (entities) or `websites` (companies/franchises/creators):
```json
{
  "anilist_id": 12345,
  "mal_id": 67890,
  "mal_ids": [67890, 67891],  // when consolidated
  "tvdb_id": 11111,
  "wikidata_props": { "P345": "tt1234567" },  // extra Wikidata properties
  "imdb_id": "tt1234567",
  "musicbrainz_id": "uuid"
}
```

---

## Execution Order

When processing a new franchise:

1. **Franchise** → create franchise record
2. **Entries** → create all entries (AniList crawl + consolidation)
3. **Entry Seasons** → create seasons for consolidated entries
4. **Season Episodes** → fetch from TVDB
5. **Entry Translations** → populate from AniList titles
6. **Genres + Tags** → create new lookup values if needed, then link
7. **Entry Genres + Entry Tags** → link entries to genres/tags
8. **Characters** → create character records (deduplicated across entries)
9. **Entry Characters** → link characters to entries with roles
10. **Creators** → create creator records (deduplicated across entries AND franchises!)
11. **Entry Creators** → link creators to entries with roles + VA character mappings
12. **Companies** → create company records
13. **Entry Companies** → link companies to entries with roles
14. **Entry Relationships** → link entries to each other
15. **Entry Franchises** → link entries to franchise with release order
16. **Wikidata enrichment pass** → batch query for wikidata_ids on all new entities
17. **Image verification pass** → check all image URLs are valid, flag broken ones

---

## Resolved Decisions

1. **TVDB API access**: Business API key, no revenue = free. Rate limits TBD — will test and document.
2. **Image hosting**: Store URLs in DB. No self-hosting, not even at launch. Revisit post-revenue.
3. **Voice actor language filter**: Keep **en/ja/ko/zh**. Chinese donghua is gaining popularity — worth capturing.
4. **Tag threshold**: AniList rank **≥ 80%**. We don't care about unpopular tags.
5. **Wikidata batch size**: TBD — will determine experimentally and document limits.
