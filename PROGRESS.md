# The Watchlist - Progress Checklist

## Migration: Prisma/NextAuth/Cloudinary -> Drizzle/Supabase/External URLs

- [x] Phase 1: Infrastructure (Drizzle + Supabase Setup)
- [x] Phase 2: Auth Migration (NextAuth -> Supabase Auth)
- [x] Phase 3: Image Simplification (Cloudinary -> External URLs)
- [x] Phase 4: CRUD Rebuild (all admin entities rewritten with Drizzle)
- [x] Phase 5: Cleanup (old deps removed, old files deleted, docs updated)

## Schema Alignment: DBML → Supabase + Drizzle (37 tables)

- [x] SQL migration script (lookup table name/displayName pattern, table renames, PK changes, column renames)
- [x] Drizzle schema.ts + relations.ts + seed.ts rewrite
- [x] Application code updates (validations, actions, pages, API routes, components)
- [x] Documentation updates (SCHEMA_NOTES.dbml, SCHEMA.md, TECH.md, SITEMAP.md)

---

## Phase 2: Remaining Admin Features
- [x] Image upload to Cloudinary (replaced with external URL storage)
- [ ] Admin todo queue UI
- [ ] Bulk import (CSV)

## Phase 3: Public Browse + Search
- [ ] Franchise listing page with filters
- [ ] Franchise detail page (Overview, Entries, Characters, Products tabs)
- [ ] Entry detail page
- [ ] Product detail page with affiliate links
- [ ] Character page
- [ ] Search with typeahead
- [ ] Browse by medium
- [ ] Filters and sorting

## Phase 4: Watchlists + Notifications
- [ ] Watchlist builder UI (multi-select filters)
- [ ] Email service integration (Resend)
- [ ] Notification queue with Upstash Redis
- [ ] Digest scheduling (daily, weekly, monthly)
- [ ] Storefront filtering
- [ ] 5 emails/day limit for free tier

## Phase 5: Community Features
- [ ] User submissions
- [ ] Translation contributions (admin-reviewed)
- [ ] Reputation system

## Phase 6: Data Analytics
- [ ] Trending products
- [ ] Popular franchises
- [ ] Admin analytics dashboard

## Phase 7: Multi-Medium Expansion
- [ ] Additional mediums (Movies, TV, Music, Comics, Board Games, Video Games)
- [ ] Medium-specific metadata

## Optional Improvements
- [ ] Loading skeletons on pages
- [ ] Improve mobile responsiveness
- [ ] OAuth providers (Google, Discord)
- [ ] Account recovery flow
