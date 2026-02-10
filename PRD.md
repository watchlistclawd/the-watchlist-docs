# The Watchlist - Product Requirements Document

## 1. Project Overview

### Vision
A hierarchical media franchise product database that enables collectors and enthusiasts to track releases across all mediums with customizable email alerts.

### Core Value Proposition
- Never miss a product release in your areas of interest
- Discover products through franchise/character/creator relationships
- Affiliate-driven revenue model connecting users to retailers

### Target MVP
Anime/Manga with extensible architecture for all media types

---

## 2. Data Hierarchy (Conceptual)

```
Medium (Anime, Manga, Movies, TV, Music, etc.)
  └── Franchise (Berserk, One Piece, etc.)
       └── Entry (Berserk 1997 Anime, Berserk Manga Vol 1, etc.)
            └── Product (Guts Figma, Blu-ray Box Set, etc.)
```

The hierarchy is intentionally broad and flexible — Mediums are the top-level category, Franchises represent IPs/brands, Entries are specific releases, and Products are purchasable items. This structure supports any media type without medium-specific schema changes.

See `docs/SCHEMA.md` for the full database model reference.

---

## 3. User Flows

### A. Discovery & Browsing
```
Home → Search/Browse → Franchise Page → Entry Page → Product Page
```

### B. Watchlist Creation
```
Profile → Watchlists → Create Watchlist → Multi-Select Builder → Set Cadence → Save
```

Watchlist filters (AND logic):
- Medium, Franchise, Entry, Character, Creator
- Product Category/Subcategory
- Storefront (limit alerts to specific retailers)

### C. Notification System

**Two-tier notifications:**
1. **Announcement notifications**: New product announced
2. **Availability notifications**: Product available at specific retailer

**Cadences:**
- Immediate (ASAP)
- Daily roundup
- Weekly roundup (user-selected day, default Sunday)
- Monthly roundup (user-selected day, default last day of month)

**Limits:**
- Free tier: 6 emails/day maximum (5 asap + 1 roundup)
- Paid tier: Unlimited (future)

---

## 4. Admin Panel

### Features
- CRUD for all entities (Mediums, Franchises, Entries, Characters, Creators, Products, Companies, Retailers)
- Bulk import (CSV/JSON)
- User submission review queue
- Audit logging (track which admin made changes, with JSON diffs)
- Role-based access (Admin, Moderator, Janitor)
- ResearchBuddy integration for auto-populating form fields (see `docs/RESEARCH.md`)

### Admin Todo System
Unified queue for:
- User submissions
- API scrapes (with partial matching detection)
- Admin-created items

Todo types: CREATE, UPDATE, MERGE, DELETE

---

## 5. Authentication

### Current (Phase 0/1)
- Email/password registration
- Supabase Auth with cookie-based SSR sessions
- TOTP 2FA (Google Authenticator compatible)
- Remember username option
- Password requirements: 8+ chars, uppercase, lowercase, number

### Future (Phase 4+)
- OAuth providers (Google, Discord)
- Account recovery

---

## 6. Settings & Preferences

### Profile Tab
- Name/email update
- Language selector (English/Japanese)
- Theme toggle (Light/Dark)
- Show NSFW toggle (hidden by default)

### Security Tab
- Password change
- 2FA enable/disable

### Danger Zone Tab
- Account deletion (3-step confirmation)

---

## 7. Development Phases

### Phase 0: Foundation (COMPLETE)
- [x] Next.js project setup with TypeScript
- [x] TailwindCSS v4 + Radix UI
- [x] Drizzle ORM with PostgreSQL (Supabase)
- [x] Supabase Auth (cookie-based SSR)
- [x] TOTP 2FA via Supabase MFA
- [x] i18n setup (English/Japanese)
- [x] Database schema (37 tables)
- [x] Initial seed data (Mediums, Categories)

### Phase 1: UI Components + Auth (COMPLETE)
- [x] UI Component library (Button, Input, Card, Form, Toast, Dialog, Tabs, Select)
- [x] Sign In/Up pages with conditional 2FA
- [x] Settings page (Profile, Security, Danger Zone)
- [x] Theme system (light/dark with persistence)
- [x] Header navigation
- [x] Form validation with translated messages

### Phase 2: Admin Panel MVP (COMPLETE)
- [x] Admin dashboard with sidebar navigation
- [x] CRUD interfaces for all entities
- [x] Role-based access control
- [x] Relationship management UI
- [x] Audit logging with JSON diffs
- [x] Duplicate detection
- [x] Users admin panel (role management)
- [x] ResearchBuddy (franchise + entry research)
- [x] Image storage via external URLs

### Phase 3: Public Browse + Search
- [ ] Franchise listing page
- [ ] Franchise detail page
- [ ] Entry detail page
- [ ] Product detail page
- [ ] Search with typeahead
- [ ] Filters and sorting

### Phase 4: Watchlists + Notifications
- [ ] Watchlist builder UI
- [ ] Email service integration (Resend)
- [ ] Notification scheduling
- [ ] Digest consolidation logic
- [ ] Storefront filtering

### Phase 5: Community Features
- [ ] User submissions
- [ ] Translation contributions (admin-reviewed)
- [ ] Reputation system

### Phase 6: Data Analytics
- [ ] Trending products
- [ ] Popular franchises
- [ ] Admin analytics dashboard

### Phase 7: Multi-Medium Expansion
- [ ] Additional mediums (Movies, TV, Music, Comics, Board Games, Video Games)
- [ ] Medium-specific metadata

---

## 8. Cost Estimates

### MVP Phase (~1000 users, ~10k products)
- Vercel Pro: $20/month
- Supabase (Postgres + Auth): $25-50/month
- Email (Resend): $0-20/month
- **Total: $45-90/month**

### Growth Phase (~10k users, ~100k products)
- **Total: $300-600/month**

### Revenue Model
- Primary: Affiliate commissions (3-8% per purchase)
- Secondary: Anonymized data sales (Phase 6+)

---

## 9. Success Metrics

### Phase 1-3 (MVP)
- 100 franchises catalogued
- 1,000 products added
- 500 registered users
- 50 active watchlists

### Phase 4-6 (Growth)
- 500+ franchises, 10,000+ products, 5,000 users, 500+ affiliate clicks/month

### Phase 7+ (Scale)
- 100,000+ products, 50,000+ users, $2,000+/month affiliate revenue

---

## 10. Key Decisions

1. **Project name**: The Watchlist
2. **MVP focus**: Anime/Manga only, extensible architecture
3. **Admin todo system**: Unified queue for all content changes
4. **2FA**: TOTP (Google Authenticator compatible) in Phase 0
5. **i18n**: English primary, Japanese secondary (critical for native titles)
6. **Email limits**: 5/day free tier to manage costs
7. **OAuth**: Deferred to Phase 4+
8. **Theater tracking**: Dropped from scope
9. **Digest scheduling**: User-configurable weekly/monthly days
10. **Theme**: Light mode default with off-white backgrounds
11. **NSFW content**: Hidden site-wide by default. Only registered users who explicitly enable "Show NSFW" see adult content.
12. **Research Agent**: On-demand search in admin forms. See `docs/RESEARCH.md` for full details.
