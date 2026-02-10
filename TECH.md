# The Watchlist - Technical Reference

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Next.js 16 (App Router, Server Components, Server Actions) |
| Language | TypeScript |
| Database | PostgreSQL (Supabase) via Drizzle ORM (postgres.js driver) |
| Auth | Supabase Auth (cookie-based SSR sessions, TOTP MFA) |
| Styling | TailwindCSS v4, Radix UI primitives |
| Forms | React Hook Form + Zod |
| i18n | next-intl (English/Japanese) |
| Deployment | Vercel |
| Images | External URL storage (self-hosted upload deferred) |
| Email | Resend (Phase 4+) |
| Caching | Upstash Redis (Phase 4+) |

---

## Directory Structure

```
app/[locale]/
  ├── page.tsx              # Home
  ├── auth/                  # Sign in, sign up, password reset
  ├── settings/              # Profile, security, danger zone
  └── admin/                 # Admin CRUD (media types, franchises, entries, etc.)

components/
  ├── ui/                    # Base Radix UI primitives (button, input, card, dialog, etc.)
  ├── admin/                 # Admin-specific (data-table, editors, etc.)
  ├── auth/                  # Auth forms
  ├── settings/              # Settings tabs
  ├── layout/                # Header, navigation
  └── providers/             # Session, theme providers

lib/
  ├── auth.ts                # Auth helpers (getUser, requireAuth)
  ├── db/
  │   ├── index.ts           # Drizzle client (exports `db`)
  │   ├── schema.ts          # All table/enum definitions
  │   ├── relations.ts       # Drizzle relational query config
  │   └── seed.ts            # Database seed script
  ├── supabase/
  │   ├── server.ts          # Server-side Supabase client (cookie-based)
  │   ├── client.ts          # Browser-side Supabase client
  │   └── admin.ts           # Service-role client (bypasses RLS)
  ├── admin/                 # Role checks, audit logging, CRUD factory, duplicate detection
  ├── utils.ts               # cn() and other utilities
  ├── research/              # ResearchBuddy system (see docs/RESEARCH.md)
  └── validations/           # Zod schemas (admin, auth, settings)

hooks/
  ├── use-toast.ts           # Toast notifications
  ├── use-duplicate-check.ts # Debounced duplicate name checking
  ├── use-password-strength.ts # Password strength calculation
  └── use-slug-generation.ts # Auto-generate slug from name

drizzle.config.ts            # Drizzle Kit configuration
middleware.ts                # Supabase session refresh + next-intl locale routing
messages/{en,ja}.json        # i18n translations
```

---

## Commands

```bash
# Development
npm run dev          # Start dev server (localhost:3000)
pkill -f "next"      # Kill stuck dev server

# Database
npm run db:push      # Push schema to database (drizzle-kit push)
npm run db:generate  # Generate migration files (drizzle-kit generate)
npm run db:migrate   # Run migrations (drizzle-kit migrate)
npm run db:studio    # Visual database browser (drizzle-kit studio)
npm run db:seed      # Seed initial data (tsx lib/db/seed.ts)

# Testing
npm run test         # Run tests (vitest watch)
npm run test:run     # Run tests once (vitest run)

# Research (requires GROQ_API_KEY in .env)
npm run research -- <entity-type> <query>     # Research an entity
npm run research:review                       # Review drafts interactively
npm run research:import                       # Import approved drafts
npm run research:import --dry-run             # Preview import without inserting

# QA (separate project)
cd ~/projects/the-watchlist-QA && npm test
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Supabase PostgreSQL connection string (pooler, transaction mode) |
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anonymous/public key |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key (server-side only, bypasses RLS) |
| `GOD_ADMIN_EMAIL` | Email auto-promoted to ADMIN role on sign-up |
| `GROQ_API_KEY` | Groq LLM for research agent |
| `TVDB_API_KEY` | TVDB API for anime series season data (optional) |
| `SERPER_API_KEY` | Serper.dev for Google Images logo search (optional) |

---

## Key Implementation Details

- **ORM**: Drizzle ORM with postgres.js driver. `prepare: false` required for Supabase connection pooler (transaction mode).
- **Schema**: Defined in `lib/db/schema.ts` with relations in `lib/db/relations.ts`. Config in `drizzle.config.ts` with `casing: 'snake_case'` (snake_case DB columns, camelCase in TypeScript).
- **Auth**: Supabase Auth with cookie-based SSR sessions via `@supabase/ssr`. Session refreshed on every request in `middleware.ts`. MFA via Supabase TOTP.
- **Auth helpers**: `getUser()` returns current user with role, `requireAuth()` redirects if unauthenticated, `requireAdmin()` checks JANITOR+ role.
- **Forms**: React Hook Form + Zod with i18n error messages via `FormMessage`
- **Theme**: Light/dark mode via CSS variables, `@variant dark` in Tailwind v4, off-white light backgrounds (#fafaf9)
- **Admin access**: `requireAdmin()` checks role, `canEdit()`/`canDelete()` for permissions
- **CRUD factory**: `lib/admin/crud-factory.ts` -- generic create/update/delete/bulkDelete actions used by all entity types
- **Audit logging**: All admin actions logged with JSON diffs (before/after)
- **Duplicate detection**: Fuzzy matching on entity names before creation
- **Slug generation**: Auto-generated from name, editable, validated for uniqueness
- **i18n pattern**: English on main entity table, other locales in `*Translation` tables
- **Adding a new UI locale**: (1) Create `messages/{code}.json` with translations, (2) Add the code to the `locales` array in `i18n/routing.ts`, (3) Ensure a row exists in the `locales` DB table. The settings language dropdown auto-populates from the DB, filtered to locales present in the routing config.
- **Images**: Stored as external URLs (text fields). No upload service -- users paste URLs directly.

### Drizzle Query Patterns

```typescript
// Select
db.select().from(table).where(eq(table.id, id))

// Insert
db.insert(table).values({ ... }).returning()

// Update
db.update(table).set({ ... }).where(eq(table.id, id))

// Delete
db.delete(table).where(eq(table.id, id))

// Relational queries
db.query.table.findMany({ with: { relation: true } })
db.query.table.findFirst({ where: eq(table.id, id), with: { translations: true } })
```

---

## Email Infrastructure
- **SMTP Provider**: Resend (via Supabase Custom SMTP)
- **Domain**: `@resend.dev` (default, custom domain planned for production)
- **Configuration**: Supabase Dashboard → Project Settings → Authentication → SMTP
- **Templates**: Configured in Supabase Dashboard → Authentication → Email Templates
- **Flows using email**:
  - Sign-up email verification (`/auth/confirm?type=signup`)
  - Password reset (`/auth/confirm?type=recovery`)
  - Email change confirmation (`/auth/confirm?type=email_change`)
- **Callback route**: `app/auth/confirm/route.ts` (outside `[locale]` — fixed URL for Supabase redirects)

---

## Known Issues

1. **Dev Server Hangs**: Occasionally the Next.js dev server becomes unresponsive after PC reboot or long idle. Kill with `pkill -f "next"` and restart with `npm run dev`.

---

## Environment Setup

### Prerequisites
- Node.js 20+
- Supabase project (PostgreSQL + Auth)
- WSL2 Ubuntu
