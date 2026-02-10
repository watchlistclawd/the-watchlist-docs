# Sitemap - Quick Reference Index

This file serves as a quick index for Claude to check whether a page, component, API route, or database table already exists before creating new ones.

**Last Updated:** 2026-02-06

For database models, see `docs/SCHEMA.md`.
For research system details, see `docs/RESEARCH.md`.

---

## Pages (`app/[locale]/`)

### Public Pages
| Route | File | Description |
|-------|------|-------------|
| `/` | `page.tsx` | Home page |
| `/auth/signin` | `auth/signin/page.tsx` | Sign in |
| `/auth/signup` | `auth/signup/page.tsx` | Sign up |
| `/auth/forgot-password` | `auth/forgot-password/page.tsx` | Password reset request |
| `/auth/reset-password` | `auth/reset-password/page.tsx` | Set new password (after clicking recovery email link) |
| `/auth/error` | `auth/error/page.tsx` | Auth error display |
| `/settings` | `settings/page.tsx` | User settings (profile, security, danger zone) |

### Admin Pages (`/admin/`)
| Route | File | Description |
|-------|------|-------------|
| `/admin` | `admin/page.tsx` | Admin dashboard |
| `/admin/mediums` | `admin/mediums/page.tsx` | Mediums list |
| `/admin/mediums/[id]` | `admin/mediums/[id]/page.tsx` | Medium edit/create |
| `/admin/franchises` | `admin/franchises/page.tsx` | Franchises list |
| `/admin/franchises/[id]` | `admin/franchises/[id]/page.tsx` | Franchise edit/create |
| `/admin/entries` | `admin/entries/page.tsx` | Entries list |
| `/admin/entries/[id]` | `admin/entries/[id]/page.tsx` | Entry edit/create |
| `/admin/characters` | `admin/characters/page.tsx` | Characters list |
| `/admin/characters/[id]` | `admin/characters/[id]/page.tsx` | Character edit/create |
| `/admin/creators` | `admin/creators/page.tsx` | Creators list |
| `/admin/creators/[id]` | `admin/creators/[id]/page.tsx` | Creator edit/create |
| `/admin/creator-roles` | `admin/creator-roles/page.tsx` | Creator roles list |
| `/admin/creator-roles/[id]` | `admin/creator-roles/[id]/page.tsx` | Creator role edit/create |
| `/admin/categories` | `admin/categories/page.tsx` | Product categories list |
| `/admin/categories/[id]` | `admin/categories/[id]/page.tsx` | Category edit/create |
| `/admin/subcategories` | `admin/subcategories/page.tsx` | Product subcategories list |
| `/admin/subcategories/[id]` | `admin/subcategories/[id]/page.tsx` | Subcategory edit/create |
| `/admin/products` | `admin/products/page.tsx` | Products list |
| `/admin/products/[id]` | `admin/products/[id]/page.tsx` | Product edit/create |
| `/admin/companies` | `admin/companies/page.tsx` | Companies list |
| `/admin/companies/[id]` | `admin/companies/[id]/page.tsx` | Company edit/create |
| `/admin/retailers` | `admin/retailers/page.tsx` | Retailers list |
| `/admin/retailers/[id]` | `admin/retailers/[id]/page.tsx` | Retailer edit/create |
| `/admin/users` | `admin/users/page.tsx` | Users management (ADMIN only) |

### Admin Error Boundary
| File | Description |
|------|-------------|
| `admin/error.tsx` | Error boundary for all admin pages |

---

## Route Handlers (outside `[locale]`)

| Route | File | Description |
|-------|------|-------------|
| `/auth/confirm` | `app/auth/confirm/route.ts` | Handles Supabase email link redirects (signup verification, password recovery, email change) |

---

## API Routes (`app/api/`)

| Route | Methods | Description |
|-------|---------|-------------|
| `/api/admin/categories/[id]` | GET | Fetch single category with subcategories |
| `/api/admin/subcategories/[id]` | GET | Fetch single subcategory |
| `/api/admin/companies/[id]` | GET | Fetch single company |
| `/api/admin/retailers/[id]` | GET | Fetch single retailer |
| `/api/admin/franchises` | GET | Fetch all franchises (for product form) |
| `/api/admin/characters` | GET | Fetch all characters (for product form) |
| `/api/admin/entries` | GET | Fetch all entries (for product form) |
| `/api/admin/research/franchise` | POST | Research franchise via Jikan + AniList + Groq LLM |
| `/api/admin/research/entry` | POST | Research entry via Jikan + AniList + TVDB + Groq LLM |
| `/api/admin/research/entry-anime-movies` | POST | Stage 1 anime movie title search via AniList |
| `/api/admin/research/entry-anime-series` | POST | Stage 1 anime series title search via TVDB |
| `/api/admin/research/character-anime` | POST | Stage 1 character search via AniList + Jikan |
| `/api/admin/research/character` | POST | Stage 2 character research via AniList + Jikan + Groq LLM |
| `/api/admin/research/creator-anime` | POST | Stage 1 creator search via AniList + Jikan |
| `/api/admin/research/creator` | POST | Stage 2 creator research via AniList + Jikan + Wikipedia + Groq LLM |
| `/api/admin/research/product` | POST | Stage 2: Full product research dispatch |

---

## Components

### UI Components (`components/ui/`)
Base Radix UI primitives - do not modify unless necessary.

| Component | Description |
|-----------|-------------|
| `alert-dialog.tsx` | Confirmation dialogs |
| `button.tsx` | Button variants |
| `card.tsx` | Card container |
| `checkbox.tsx` | Checkbox input |
| `dialog.tsx` | Modal dialogs |
| `dropdown-menu.tsx` | Dropdown menus |
| `form.tsx` | Form utilities (react-hook-form) |
| `input.tsx` | Text input |
| `label.tsx` | Form labels |
| `select.tsx` | Select dropdown |
| `switch.tsx` | Toggle switch |
| `table.tsx` | Table elements |
| `tabs.tsx` | Tab navigation |
| `textarea.tsx` | Multiline text input |
| `toast.tsx` | Toast notification |
| `toaster.tsx` | Toast container |
| `use-toast.ts` | Toast state management hook |
| `icons.tsx` | Centralized SVG icons (PlusIcon, RefreshIcon, XIcon, etc.) |

### Admin Components (`components/admin/`)
| Component | Description |
|-----------|-------------|
| `data-table.tsx` | Generic data table with sorting/filtering |
| `sidebar.tsx` | Admin navigation sidebar |
| `slug-input.tsx` | Slug field with auto-generate and refresh |
| `duplicate-warning.tsx` | Fuzzy duplicate detection warning |
| `image-upload.tsx` | Single image upload |
| `logo-picker-dialog.tsx` | Dialog carousel for picking from LLM-ranked logo options |
| `multi-image-upload.tsx` | Multiple image upload with reordering |
| `quick-add-dialog.tsx` | Inline entity creation dialog |
| `searchable-checkbox-list.tsx` | Filterable checkbox grid with +/refresh |
| `searchable-select.tsx` | Type-to-filter dropdown for entity selection |
| `research-search-bar.tsx` | Research agent search bar with medium dropdown |
| `title-picker-dialog.tsx` | Title picker dialog for two-stage research |
| `purchase-links-editor.tsx` | Purchase links table editor |
| `seasons-editor.tsx` | Entry seasons CRUD |
| `entry-relations-panel.tsx` | Entry characters/creators/products accordion |
| `appearances-editor.tsx` | Character appearances editor |
| `creator-entries-editor.tsx` | Creator-entry relationships |
| `franchise-entries-list.tsx` | Franchise entries display |
| `role-autocomplete.tsx` | Creator role autocomplete |
| `role-multi-select.tsx` | Multi-select for creator roles |
| `users-table.tsx` | Users table with role editing panel |

### Auth Components (`components/auth/`)
| Component | Description |
|-----------|-------------|
| `sign-in-form.tsx` | Sign in form |
| `sign-up-form.tsx` | Sign up form |
| `reset-password-form.tsx` | Forgot password form (exports `ForgotPasswordForm` — email-only form for requesting reset link) |
| `update-password-form.tsx` | New password form with strength meter (exports `UpdatePasswordForm`) |
| `auth-error-display.tsx` | Auth error messages |

### Settings Components (`components/settings/`)
| Component | Description |
|-----------|-------------|
| `profile-tab.tsx` | Profile settings (display name, theme, NSFW toggle) |
| `security-tab.tsx` | Security settings (password, 2FA) |
| `danger-zone-tab.tsx` | Account deletion |
| `theme-toggle.tsx` | Light/dark mode toggle |
| `two-factor-setup-dialog.tsx` | 2FA setup flow |
| `two-factor-disable-dialog.tsx` | 2FA disable confirmation |
| `delete-account-dialog.tsx` | Account deletion confirmation |

### Layout Components (`components/layout/`)
| Component | Description |
|-----------|-------------|
| `header.tsx` | Site header with navigation |

### Provider Components (`components/providers/`)
| Component | Description |
|-----------|-------------|
| `session-provider.tsx` | Session context provider |
| `theme-provider.tsx` | Theme context provider |

---

## Hooks (`hooks/`)

| Hook | Description |
|------|-------------|
| `use-toast.ts` | Toast notification hook |
| `use-duplicate-check.ts` | Debounced duplicate name checking |
| `use-password-strength.ts` | Password strength calculation |
| `use-slug-generation.ts` | Auto-generate slug from name field |

---

## Library (`lib/`)

| File | Description |
|------|-------------|
| `auth.ts` | Auth helpers (getUser, requireAuth, requireAdmin) |
| `db/index.ts` | Drizzle client (exports `db`) |
| `db/schema.ts` | All table/enum definitions |
| `db/relations.ts` | Drizzle relational query config |
| `db/seed.ts` | Database seed script |
| `supabase/server.ts` | Server-side Supabase client (cookie-based) |
| `supabase/client.ts` | Browser-side Supabase client |
| `supabase/admin.ts` | Service-role client (bypasses RLS) |
| `utils.ts` | Utility functions (cn, etc.) |
| `i18n/config.ts` | i18n configuration |
| `admin/audit-log.ts` | Audit logging for admin actions |
| `admin/crud-factory.ts` | Generic CRUD action factory (create/update/delete/bulkDelete) |
| `admin/duplicate-check.ts` | Fuzzy duplicate detection |
| `admin/role-check.ts` | Admin role verification (requireAdmin, canEdit, canDelete) |
| `admin/get-creator-roles.ts` | Fetch creator roles utility |
| `research/` | ResearchBuddy system (see `docs/RESEARCH.md`) |
| `validations/admin.ts` | Zod schemas for admin forms |
| `validations/auth.ts` | Zod schemas for auth forms |
| `validations/settings.ts` | Zod schemas for settings forms |

---

## Scripts

| File | Description |
|------|-------------|
| `lib/db/seed.ts` | Database seed script |
| `migrations/001_schema_alignment.sql` | Schema alignment migration (DBML target) |

---

## Server Actions

Server actions are co-located with their pages in `actions.ts` files:

| Location | Actions |
|----------|---------|
| `admin/mediums/actions.ts` | createMediumAction, updateMediumAction, deleteMediumAction |
| `admin/franchises/actions.ts` | createFranchiseAction, updateFranchiseAction, deleteFranchiseAction |
| `admin/entries/actions.ts` | createEntryAction, updateEntryAction, deleteEntryAction |
| `admin/characters/actions.ts` | createCharacterAction, updateCharacterAction, deleteCharacterAction |
| `admin/creators/actions.ts` | createCreatorAction, updateCreatorAction, deleteCreatorAction |
| `admin/creator-roles/actions.ts` | createCreatorRoleAction, updateCreatorRoleAction, deleteCreatorRoleAction |
| `admin/categories/actions.ts` | createCategoryAction, updateCategoryAction, deleteCategoryAction, quickCreateCategoryAction |
| `admin/subcategories/actions.ts` | createSubcategoryAction, updateSubcategoryAction, deleteSubcategoryAction, quickCreateSubcategoryAction |
| `admin/products/actions.ts` | createProductAction, updateProductAction, deleteProductAction, getGeneratedSlugAction |
| `admin/companies/actions.ts` | createCompanyAction, updateCompanyAction, deleteCompanyAction, quickCreateCompanyAction |
| `admin/retailers/actions.ts` | createRetailerAction, updateRetailerAction, deleteRetailerAction, quickCreateRetailerAction |
| `admin/users/actions.ts` | updateUserRoleAction |
| `auth/reset-password/actions.ts` | updatePasswordAction |
| `settings/actions.ts` | updateProfileAction, updatePasswordAction, deleteAccountAction, setup2FAAction, verify2FAAction, disable2FAAction, updateNsfwPreferenceAction |
