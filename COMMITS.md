# The Watchlist - Commit History

Most recent first.

---

## February 1, 2026

### Doc Cleanup
- `63ac31d` - Document intentional duplication in research prompts folder
- `27d7f4c` - Refactor admin actions with CRUD factory and remove TECHDEBT.md
- `ac4dcde` - Update TECHDEBT.md: correct error handling entry, clarify handler design
- `28957f8` - Revert unnecessary Promise.allSettled in movie handler
- `4852c55` - Update docs for tech debt cleanup

### Tech Debt Cleanup
- Fixed N+1 queries in all 10 bulk delete admin actions (batched findMany + groupBy)
- Consolidated 10 duplicate check functions into 1 generic function (312 → 80 lines)
- Extracted reusable Zod validation helpers (optionalUrl, optionalString)
- Created lib/research/constants.ts for shared timeouts, limits, and LLM config
- Standardized error handling in research handlers (Promise.allSettled)
- Reduced overfetching in franchises and products list pages
- Removed unused Prisma models: AdminTodoItem, ScraperRun, ScraperLog, ScheduledReveal
- Removed deprecated EntryCreator.role column
- Added missing DB indexes: User.role, Product.manufacturerId, Product.embargoUntil
- Added CircleXIcon to shared icons, replaced all inline SVGs with shared imports
- Removed stale open-x-page.ts dev script and empty auth event handler
- Created generic CRUD action factory (`lib/admin/crud-factory.ts`) and migrated all 10 entity action files

### Research Agent Phase 5: TVDB Series Title Picker
- `88a6e06` - Add two-stage TVDB series picker for anime series research

### Research Agent Phase 4: Anime Movie Title Picker
- Two-stage anime movie research flow via AniList title search
- TitlePickerDialog with thumbnail, year, and DB existence indicator

### Research Agent Phase 3: Entry Research + Save & New Fix
- `a3fdfae` - Add entry research handler with TVDB seasons, fix Save & New across all forms

---

## January 31, 2026

### Research Agent Phase 2: Logo Picker + UI Polish
- LLM returns up to 12 ranked `imageUrls`; LogoPickerDialog with 4x3 grid and resolution labels
- All admin Edit headers show entity name in blue; Radix Checkbox standardized

---

## January 30, 2026

### Research Agent Phase 1.5: Medium Dropdown + Logo Search
- ResearchSearchBar medium dropdown (Anime/Manga, Music, Movies/TV, General)
- Google Custom Search logo source via Serper

### Research Agent Phase 1: Franchise Form
- Research infrastructure: Jikan + AniList sources, Groq LLM integration
- Franchise prompt template, API route, ResearchSearchBar component

---

## January 29, 2026

### Phase 2.6: Users Admin Panel
- `816d3f2` - Add users admin panel with role management
- Users management page, side panel role editor, god admin protection, audit logging

---

## January 26, 2026

### Phase 2.5: Product Editor Enhancement
- Manufacturers and Retailers CRUD
- Product form: manufacturer dropdown, multi-image upload, purchase links editor
- Searchable checkbox lists for franchise/character/entry associations
- QuickAddDialog, SearchableCheckboxList, MultiImageUpload, PurchaseLinksEditor components

### Phase 2: Admin Panel MVP
- `635d9ce` - Add Phase 2 Admin Panel MVP with CRUD operations
- Admin dashboard with sidebar, CRUD for all entities, role-based access, audit logging, duplicate detection

---

## January 24-25, 2026

### Phase 1: UI Components + Authentication
- `2525992` - Add authentication, settings, and theme system (55 files, 5504 additions)
- UI component library, auth pages, settings page, theme system, header navigation

### Phase 0: Foundation
- `5e83a88` - Initial commit - Phase 0 foundation
- `c6e38c7` - Fix i18n locale routing structure
- Next.js 16, Prisma, NextAuth.js v5, 2FA, i18n, database seeding

---

## QA Infrastructure

- `5e8631e` - Fix Playwright test specs: programmatic sign-in and correct selectors
- `f0115d9` - Add users admin section to QA release checklist
- `ba99e76` - Add Playwright QA test infrastructure
