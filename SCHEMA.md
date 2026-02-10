# The Watchlist - Database Schema Reference

**Source of truth:** `lib/db/schema.ts` (Drizzle ORM), `docs/SCHEMA_NOTES.dbml` (annotated DBML)
**Relations:** `lib/db/relations.ts`
**Config:** `drizzle.config.ts` (`casing: 'snake_case'` -- snake_case DB columns, camelCase in TypeScript)

---

## Schema Conventions

- **Primary keys**: UUIDs with `defaultRandom()` (except `locales` and `countries` which use `code` as PK)
- **Column naming**: snake_case in DB, camelCase in TypeScript (via Drizzle casing config)
- **Timestamps**: `created_at` and `updated_at` with timezone, defaulting to `now()`
- **JSONB fields**: Used on `entries.details`, `products.details`, `creators.details`, `creators.websites`, `companies.websites`, `franchises.websites`, `retailers.affiliate_info`
- **Array fields**: PostgreSQL text arrays for `entries.alternate_titles`, `franchises.alternate_names`, `characters.alternate_names`, `entry_seasons.alternate_titles`, `season_episodes.alternate_titles`, `music_tracks.alternate_titles`
- **Enum**: `user_role` pgEnum (`USER`, `JANITOR`, `MODERATOR`, `ADMIN`)
- **Lookup table pattern**: `name` = machine-readable key (lowercase, hyphenated), `display_name` = human-readable label
- **37 tables total** (1 user, 10 lookup, 6 core, 6 product, 2 retail, 2 TV, 3 music, 7 entry junction, 2 product junction)

---

## Data Hierarchy

```
Media Type (anime-series, manga, movie, music-album, video-game, etc.)
  └── Franchise (Berserk, One Piece, Rush, etc.)
       └── Entry (Berserk 1997 Anime, Vol 1 Manga, Moving Pictures album, etc.)
            └── Product (Guts Figma, Blu-ray Box Set, Vinyl pressing, etc.)
```

---

## Key Relationships

- Franchises have parent/child hierarchy (sub-franchises) via `parent_id` self-reference
- Entries link to Franchises via `entry_franchises` junction table (many-to-many)
- Entries link to a single media type via `media_type_id` (many-to-one)
- Characters belong to a primary franchise via `franchise_id`, appear in multiple entries via `entry_characters`
- Creators link to entries via `entry_creators` with role via `role_id` FK to `creator_roles`; voice actors include `character_id` and `language`
- Companies link to entries via `entry_companies` and to products via `product_companies`, each with role via `role_id`
- Products link to entries and characters via join tables (`product_entries`, `product_characters`)
- Companies have parent/child hierarchy via `parent_company_id` self-reference
- Retailers optionally link to a parent company via `parent_company_id`

---

## Translation Pattern

English name/title/description lives on the **main entity table**. Other locales (Japanese, etc.) live in separate `*_translations` tables. This avoids JOIN overhead for the default locale.

- `creators.native_name` and `characters.native_name` -- inline native name column (no separate translation table)
- `entry_translations` -- entry translated title in other locales (via `locale_code` FK)
- `product_translations` -- product name/description in other locales (via `locale_code` FK)

---

## Tables by Section

### User

| Table | Description |
|-------|-------------|
| `user_profiles` | Extends Supabase `auth.users`; stores display name, role, NSFW preference, dark mode, locale. PK = auth.users.id |

### Lookup Tables

| Table | Description |
|-------|-------------|
| `media_types` | Media types (anime-series, manga, movie, etc.) with name/display_name |
| `creator_roles` | Role types for creators (director, mangaka, voice-actor, etc.) with optional category |
| `company_roles` | Role types for companies (studio, publisher, licensor, etc.) |
| `genres` | Genres with optional media type scope and parent/child hierarchy |
| `tags` | Tags with optional category (theme, mood, setting, content_warning, trope) |
| `relationship_types` | Entry relationship types with inverse pairs, directional flag |
| `locales` | Supported locales (PK = code: 'en', 'ja') |
| `countries` | ISO 3166-1 alpha-2 country codes (PK = code: 'US', 'JP') |
| `product_categories` | Top-level product categories (figure, home-video, book, etc.) |
| `product_subcategories` | Subcategories (nendoroid, blu-ray, etc.) scoped to category |

### Core Entities

| Table | Description |
|-------|-------------|
| `franchises` | IPs/Franchises with parent/child hierarchy, alternate names array, websites JSONB |
| `entries` | Media works; has media type FK, JSONB details, status, primary image URL, alternate titles |
| `entry_translations` | Entry i18n (translated title per locale) |
| `creators` | People (directors, authors); has full_name, biography, websites JSONB, nationality |
| `companies` | Organizations; has company_summary, websites JSONB, parent company hierarchy |
| `characters` | Characters belonging to a primary franchise; has sort_name, alternate names array |

### Product Tables

| Table | Description |
|-------|-------------|
| `products` | Products with NSFW flag, visibility, currency, JSONB details, primary image |
| `product_companies` | Product ↔ Company with role, credit order, notes |
| `product_translations` | Product i18n (name/description per locale) |
| `product_images` | Product images (ordered by `display_order`), stored as URLs |
| `product_entries` | Product ↔ Entry with product order and notes |
| `product_characters` | Product ↔ Character join table |

### Retailers

| Table | Description |
|-------|-------------|
| `retailers` | Storefronts with logo URL, region, currency, optional parent company |
| `product_listings` | Product availability at retailers with price/currency/status, SKU, last checked timestamps |

### TV (Seasons & Episodes)

| Table | Description |
|-------|-------------|
| `entry_seasons` | Seasons with season_number, title, episode count, air dates, TVDB ID |
| `season_episodes` | Episodes with episode_number, runtime_minutes, synopsis, TVDB ID |

### Music

| Table | Description |
|-------|-------------|
| `music_tracks` | Music tracks (title, duration_seconds, ISRC) linked to entries |
| `product_tracks` | Product ↔ Track with disc/track number for physical releases |
| `track_creators` | Track ↔ Creator with role |

### Entry Junction Tables

| Table | Description |
|-------|-------------|
| `entry_creators` | Entry ↔ Creator with role, optional character_id + language (for voice actors), credit order |
| `entry_companies` | Entry ↔ Company with role, credit order, notes |
| `entry_franchises` | Entry ↔ Franchise with franchise release order |
| `entry_genres` | Entry ↔ Genre with is_primary flag |
| `entry_relationships` | Directed entry-to-entry relationships with type and notes |
| `entry_tags` | Entry ↔ Tag join table |
| `entry_characters` | Character appearances in entries with role (main, supporting, etc.) |
