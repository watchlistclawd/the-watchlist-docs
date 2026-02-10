# Tech Debt Report

**Generated:** 2026-02-03
**Branch:** `techdebt/2026-02-03`

---

## Summary

| Category | Issues Found | Auto-Fixed | Requires Approval |
|----------|--------------|------------|-------------------|
| Database Schema | 10 | 3 | 7 |
| Code Performance | 1 | 1 | 0 |
| Code Duplication | 13 | 4 | 9 |
| QA/Error Handling | 17 | 11 | 6 |
| Testing | Critical gap | 0 | (see below) |

---

## ✅ Implemented Fixes (This Branch)

### 1. Added Composite Database Indexes

**Impact:** Query performance improvement for common access patterns.

| Model | New Index | Use Case |
|-------|-----------|----------|
| `Watchlist` | `@@index([userId, enabled])` | Filter user's enabled watchlists |
| `EmailQueue` | `@@index([userId, status, scheduledFor])` | Batch email processing queries |
| `ScrapedProductCache` | `@@index([retailerId, lastScraped])` | Scraper change detection |

**File:** `lib/db/schema.ts`

### 2. Fixed N+1 Bulk Delete Performance

**Before:** Bulk delete of 100 items executed 200+ individual queries (N deletes + N audit logs).

**After:** Bulk delete uses 2 queries total:
- 1 `deleteMany` for all valid items
- 1 `createMany` for all audit logs

**File:** `lib/admin/crud-factory.ts:340-398`

### 3. Extracted Translation Builder Utility

Consolidated `buildTranslationRecords()` from 3 files into shared utility.

**Files:**
- New: `lib/admin/translation-builder.ts`
- Updated: `app/[locale]/admin/characters/actions.ts`
- Updated: `app/[locale]/admin/creators/actions.ts`
- Updated: `app/[locale]/admin/products/actions.ts`

### 4. Extracted Research Handler Validation Utility

Consolidated `validateAndReturnResult()` pattern from 5 research handlers.

**Files:**
- New: `lib/research/handlers/common.ts`
- Updated: `lib/research/handlers/character-anime.ts`
- Updated: `lib/research/handlers/creator-anime.ts`
- Updated: `lib/research/handlers/franchise-anime.ts`
- Updated: `lib/research/handlers/entry-anime-series.ts`
- Updated: `lib/research/handlers/entry-anime-movie.ts`

### 5. Added Error Logging to Silent Catch Blocks

Added `console.error()` to 11 catch blocks for better debugging.

**Files:**
- `components/admin/entry-relations-panel.tsx`
- `components/admin/quick-add-dialog.tsx`
- `components/admin/research-search-bar.tsx`
- `components/auth/sign-up-form.tsx`
- `app/[locale]/admin/characters/[id]/character-form.tsx`
- `app/[locale]/admin/products/[id]/product-form.tsx`

---

## 🔶 Requires Approval

### Database Schema Changes

#### ~~String Fields That Should Be Enums~~ FIXED

Converted 10 string fields to Prisma enums:
- SubscriptionTier, EntryType, ProductVisibility, PurchaseLinkStatus
- NotificationCadence, StorefrontFilter, RetentionTier, AuditAction
- EmailQueueType, EmailQueueStatus

Added VerificationToken expires index.

**Status:** Schema updated, TypeScript code updated. (Migrated to Drizzle enums since.)

#### ~~Array Fields That Should Be Join Tables~~ RESOLVED

~~These arrays store foreign key IDs but lack referential integrity.~~

**Status:** Removed unused fields. Join tables will be created when features are built.
- Removed `Watchlist.allowedStorefronts`
- Removed `Watchlist.excludedStorefronts`
- Removed `Manufacturer.managedFranchises`

---

### Code Duplication

#### ~~HIGH PRIORITY: Form Component Duplication~~ PARTIALLY FIXED

~~11 admin form files follow nearly identical patterns (~1500 lines duplicated).~~

**Status:** Created `lib/admin/entity-form-factory.tsx` and refactored 4 simple forms:
- `app/[locale]/admin/categories/[id]/category-form.tsx` (213 → 80 lines)
- `app/[locale]/admin/mediums/[id]/medium-form.tsx` (215 → 80 lines)
- `app/[locale]/admin/subcategories/[id]/subcategory-form.tsx` (236 → 90 lines)
- `app/[locale]/admin/creator-roles/[id]/creator-role-form.tsx` (166 → 60 lines)

**Savings:** ~500 lines reduced in 4 forms

**Remaining:** Complex forms (product, entry, character, creator, franchise, company, retailer) stay custom due to unique features (research integration, translations, tabs, image uploads).

#### ~~HIGH PRIORITY: Translation Builder Duplication~~ FIXED

~~`buildTranslationRecords()` implemented 3 times with identical logic.~~

**Status:** Extracted to `lib/admin/translation-builder.ts`

#### ~~MEDIUM PRIORITY: Image Upload Components~~ FIXED

~~70% duplication between:~~
~~- `components/admin/image-upload.tsx` (229 lines)~~
~~- `components/admin/multi-image-upload.tsx` (330 lines)~~

**Status:** Extracted to `hooks/use-image-upload.ts`

**Savings:** ~120 lines (components reduced from 559 total to ~438 total)

#### ~~MEDIUM PRIORITY: Research Handler Validation~~ FIXED

~~5 handlers repeat identical result validation pattern.~~

**Status:** Extracted to `lib/research/handlers/common.ts`

---

### QA & Error Handling

#### ~~Silent Error Catches (11 instances)~~ FIXED

~~These catch blocks swallow errors without logging, making debugging difficult.~~

**Status:** Added `console.error()` to all identified catch blocks.

#### ~~Silent Fetch Fallbacks (4 instances)~~ FIXED

~~`.catch(() => null)` hides fetch failures from users.~~

**Status:** Refactored to use proper try/catch with error logging.

---

### ~~Testing Gap (Critical)~~ ADDRESSED

~~The codebase has ZERO test coverage.~~

**Status:** Vitest configured with initial test suite:
- `lib/validations/auth.test.ts` - 14 tests
- `lib/validations/admin.test.ts` - 31 tests
- Run with: `npm test` or `npm run test:run`

#### Highest Priority Testing Targets

| Module | Lines | Criticality | Why |
|--------|-------|-------------|-----|
| `lib/admin/crud-factory.ts` | 389 | 🔴 CRITICAL | All CRUD operations, slug handling, audit logging |
| `lib/validations/admin.ts` | 220 | 🔴 CRITICAL | 12+ Zod schemas for all entities |
| `lib/validations/auth.ts` | 55 | 🔴 CRITICAL | Password/auth validation rules |
| `lib/admin/duplicate-check.ts` | 80 | 🔴 CRITICAL | Fuzzy matching logic |
| `lib/auth.ts` | 107 | 🟡 HIGH | Supabase Auth helpers, session management |
| `lib/research/groq.ts` | 74 | 🟡 HIGH | LLM API error handling |
| `lib/research/sources/mfc/*.ts` | 200+ | 🟡 HIGH | Web scraper (fragile) |

**Recommendation:** Add Vitest with @testing-library/react. Start with unit tests for validation schemas and CRUD factory.

---

## 📋 Prioritized Action Items

### Quick Wins (< 1 hour each)
1. ✅ Add composite database indexes (DONE)
2. ✅ Fix N+1 bulk delete (DONE)
3. ✅ Extract `buildTranslationRecords()` utility (DONE)
4. ✅ Add error logging to silent catch blocks (DONE)
5. ✅ Extract research handler validation utility (DONE)

### Medium Effort (1-3 hours each)
6. ✅ Create `useImageUpload()` hook (DONE)
7. ✅ Convert string fields to Prisma enums (DONE)
8. ✅ Add error notifications for silent fetch failures (DONE)

### Strategic Refactors (3+ hours)
9. ✅ Create generic `EntityForm` component factory (DONE - 4 forms refactored)
10. ✅ Removed unused array FK fields (DONE)
11. ✅ Set up Vitest and add initial test suite (45 tests)

---

## Files Changed in This Branch

### Phase 1: Quick Wins
- `lib/admin/translation-builder.ts` - New shared utility
- `lib/research/handlers/common.ts` - New shared utility
- `app/[locale]/admin/characters/actions.ts` - Use shared translation builder
- `app/[locale]/admin/creators/actions.ts` - Use shared translation builder
- `lib/research/handlers/*.ts` (5 files) - Use shared validation utility
- `components/admin/*.tsx` (4 files) - Add error logging
- `components/auth/sign-up-form.tsx` - Add error logging
- `app/[locale]/admin/characters/[id]/character-form.tsx` - Add error logging
- `app/[locale]/admin/products/[id]/product-form.tsx` - Add error logging, fix fetch fallbacks

### Phase 2: Database Schema
- `prisma/schema.prisma` - Added 10 enums, 3 composite indexes, VerificationToken expires index
- `lib/admin/crud-factory.ts` - Fixed N+1 bulk delete, use enum types
- `lib/admin/audit-log.ts` - Use Prisma enum types
- `app/[locale]/admin/entries/actions.ts` - Use EntryType enum
- `app/[locale]/admin/products/actions.ts` - Use ProductVisibility, PurchaseLinkStatus enums

### Phase 3: Code Consolidation
- `hooks/use-image-upload.ts` - New shared hook for Cloudinary uploads
- `components/admin/image-upload.tsx` - Refactored to use shared hook
- `components/admin/multi-image-upload.tsx` - Refactored to use shared hook
- `lib/admin/entity-form-factory.tsx` - New generic form component for simple CRUD forms
- `app/[locale]/admin/categories/[id]/category-form.tsx` - Refactored to use EntityForm
- `app/[locale]/admin/mediums/[id]/medium-form.tsx` - Refactored to use EntityForm
- `app/[locale]/admin/subcategories/[id]/subcategory-form.tsx` - Refactored to use EntityForm
- `app/[locale]/admin/creator-roles/[id]/creator-role-form.tsx` - Refactored to use EntityForm
- `hooks/use-duplicate-check.ts` - Added EntityType re-export

### Documentation
- `docs/TECHDEBT.md` - This report
- `docs/TODO.md` - Task tracking
