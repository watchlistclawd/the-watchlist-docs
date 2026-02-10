# The Watchlist - QA Release Checklist

**Version:** 1.0
**Last Updated:** 2026-02-01
**Test Environment:** localhost:3000

---

## Pre-Release Checks

### Environment
- [ ] All environment variables set in `.env`
- [ ] Database migrations applied: `npm run db:push`
- [ ] Seed data loaded (if needed): `npm run db:seed`
- [ ] No console errors in browser dev tools
- [ ] All npm dependencies installed

### Code Quality
- [ ] `npm run build` completes successfully
- [ ] `npm run lint` passes with no errors
- [ ] TypeScript types check out

---

## Authentication Tests

### Sign Up
- [ ] Sign up with valid name, email, password
- [ ] Sign up with existing email (error shown)
- [ ] Sign up with weak password (validation error)
- [ ] Sign up with mismatched passwords (validation error)
- [ ] Sign up with empty fields (validation errors)
- [ ] Sign up redirects to home/dashboard
- [ ] Email verification flow (if applicable)

### Sign In
- [ ] Sign in with valid credentials
- [ ] Sign in with invalid email (error shown)
- [ ] Sign in with invalid password (error shown)
- [ ] Sign in redirects to intended page after
- [ ] "Remember me" functionality (if applicable)
- [ ] Forgot password flow

### Sign Out
- [ ] Sign out button works
- [ ] Session cleared after sign out
- [ ] Redirected to sign in page

### Two-Factor Authentication
- [ ] Enable 2FA with authenticator app
- [ ] Sign in requires 2FA when enabled
- [ ] Valid 2FA code allows access
- [ ] Invalid 2FA code shows error
- [ ] Disable 2FA works

### Password Reset
- [ ] Request password reset email
- [ ] Reset link expires correctly
- [ ] Set new password works
- [ ] Cannot reuse old password (if enforced)

---

## Account Settings Tests

### Profile
- [ ] View profile page
- [ ] Update name
- [ ] Update email (verify)
- [ ] Email change triggers confirmation
- [ ] Upload profile image
- [ ] Remove profile image
- [ ] Profile updates persist

### Security
- [ ] Change password with correct current password
- [ ] Change password with wrong current password (error)
- [ ] Password strength indicator
- [ ] View active sessions (if applicable)
- [ ] Revoke other sessions (if applicable)

### Danger Zone
- [ ] Delete account button present
- [ ] Confirmation dialog with typing "DELETE"
- [ ] Account deletion works
- [ ] Data cleaned up after deletion
- [ ] Cannot log in after deletion

---

## UI/UX Tests

### Dark Mode
- [ ] Dark mode toggle works
- [ ] Light mode toggle works
- [ ] Preference persists across sessions
- [ ] All pages respect dark mode
- [ ] No visual issues in dark mode (contrast, visibility)

### Language Switching
- [ ] Switch English → Japanese
- [ ] Switch Japanese → English
- [ ] Language persists across pages
- [ ] Language persists across sessions
- [ ] Admin panel translates correctly
- [ ] Auth pages translate correctly
- [ ] Error messages translate
- [ ] Toast notifications translate

### Responsive Design
- [ ] Desktop (1920px)
- [ ] Laptop (1366px)
- [ ] Tablet (768px)
- [ ] Mobile (375px)
- [ ] Navigation works on mobile
- [ ] Tables scroll horizontally on mobile
- [ ] Forms are usable on mobile

### Navigation
- [ ] Home link works
- [ ] Browse link works
- [ ] Watchlists link works
- [ ] Account settings link works
- [ ] Admin link visible for admins only
- [ ] Breadcrumbs work correctly
- [ ] 404 page shows for invalid routes

### Loading States
- [ ] Loading spinner on page transitions
- [ ] Loading skeleton on data fetch
- [ ] Buttons disable during form submission
- [ ] No infinite loading

### Error Handling
- [ ] 404 page shows for invalid URLs
- [ ] 500 page shows for server errors
- [ ] Form validation errors display correctly
- [ ] Toast notifications for success/error
- [ ] Network error handling

---

## Admin Panel Tests

### General Admin
- [ ] Admin panel accessible by admin role only
- [ ] Sidebar navigation works
- [ ] Pagination works
- [ ] Search/filter functionality
- [ ] Bulk actions (if applicable)
- [ ] Save & New resets form state on all admin forms (Mediums, Franchises, Entries, Characters, Creators, Creator Roles, Categories, Subcategories, Companies, Retailers)

---

### Franchises
- [ ] View franchises list
- [ ] Create franchise (name, slug, description)
- [ ] Create franchise with logo
- [ ] Create franchise with parent (hierarchy)
- [ ] Edit franchise name
- [ ] Edit franchise slug
- [ ] Edit franchise description
- [ ] Edit franchise logo
- [ ] Edit franchise parent
- [ ] Delete franchise (with confirmation)
- [ ] Cannot delete franchise with entries (error)
- [ ] Search franchises
- [ ] Filter by medium
- [ ] Pagination
- [ ] Multi-locale translations (add/edit/remove via TranslationsEditor)
- [ ] Research search bar: type query → populates name, description, translations (JA + Romaji)
- [ ] Research search bar: logo picker dialog appears with up to 12 images in 4x3 grid
- [ ] Research search bar: each image shows native resolution in bottom-right corner
- [ ] Research search bar: selecting an image → URL stored → appears in ImageUpload
- [ ] Research search bar: clicking Skip → no logo set, other fields still populated
- [ ] Research search bar: empty input falls back to Name field value
- [ ] Research search bar: both empty → nothing happens
- [ ] Research search bar: image proxy failure → toast warning, other fields populated
- [ ] Research search bar: medium dropdown shows Anime/Manga, Music, Movies/TV, General
- [ ] Research search bar: switching medium and searching sends medium to API
- [ ] Research search bar: with SERPER_API_KEY, logo search returns franchise logos
- [ ] Research search bar: without SERPER_API_KEY, works as before (no logo search)

---

### Entries
- [ ] View entries list
- [ ] Create entry (title, slug, description)
- [ ] Create entry with franchise
- [ ] Create entry with medium
- [ ] Create entry with entry type (series/movie/etc)
- [ ] Create entry with seasons
- [ ] Create entry with creators/roles
- [ ] Create entry with characters
- [ ] Edit entry title
- [ ] Edit entry metadata
- [ ] Edit entry seasons
- [ ] Edit entry creators
- [ ] Edit entry characters
- [ ] Delete entry
- [ ] Duplicate entry detection
- [ ] Search entries
- [ ] Filter by franchise
- [ ] Filter by medium
- [ ] Multi-locale translations (add/edit/remove via TranslationsEditor)
- [ ] Research button: popout with anime-series / anime-movie / other options
- [ ] Research anime-series: title picker dialog opens with TVDB results sorted by relevance
- [ ] Research anime-series: picker shows English names (not native language) with year and thumbnail
- [ ] Research anime-series: selecting a series populates title, description, translations, release date, seasons
- [ ] Research anime-series: existing DB entries shown with green checkmark in picker
- [ ] Research anime-movie: title picker dialog opens with AniList results
- [ ] Research anime-movie: selecting a movie populates title, description, translations, release date (no seasons)
- [ ] Research: cover image auto-populated from API (no logo picker)
- [ ] Research: populated fields visually highlighted
- [ ] Research: empty search bar falls back to title field value
- [ ] Franchise dropdown: type-to-filter (SearchableSelect) works correctly
- [ ] Type dropdown disabled until Medium is selected
- [ ] All dropdowns sorted alphabetically (A-Z)
- [ ] Save & New: form fully resets (fields cleared, not just navigation)

---

### Products
- [ ] View products list
- [ ] Create product (name, slug, description)
- [ ] Create product with category
- [ ] Create product with subcategory
- [ ] Create product with release date
- [ ] Create product with MSRP
- [ ] Create product with UPC
- [ ] Create product with images
- [ ] Create product with purchase links
- [ ] Create product with retailers
- [ ] Create product with franchises
- [ ] Create product with entries
- [ ] Create product with characters
- [ ] Edit product
- [ ] Edit product images
- [ ] Edit product purchase links
- [ ] Delete product
- [ ] Search products
- [ ] Filter by category
- [ ] Filter by subcategory
- [ ] Filter by release date
- [ ] Translations (EN/JA)

---

### Characters
- [ ] View characters list
- [ ] Create character (name, slug, description)
- [ ] Create character with image
- [ ] Create character with primary franchise
- [ ] Edit character
- [ ] Delete character
- [ ] Search characters
- [ ] Translations (EN/JA)

---

### Creators
- [ ] View creators list
- [ ] Create creator (name, slug, bio)
- [ ] Create creator with image
- [ ] Create creator with website
- [ ] Edit creator
- [ ] Delete creator
- [ ] Search creators
- [ ] Translations (EN/JA)

---

### Categories
- [ ] View categories list
- [ ] Create category (name, slug)
- [ ] Create category with description
- [ ] Edit category
- [ ] Delete category (check subcategories)
- [ ] Delete category with products (error)

---

### Subcategories
- [ ] View subcategories list
- [ ] Create subcategory
- [ ] Create subcategory with category
- [ ] Edit subcategory
- [ ] Delete subcategory

---

### Mediums
- [ ] View mediums list
- [ ] Create medium (name, slug)
- [ ] Create medium with description
- [ ] Edit medium
- [ ] Delete medium (check entries)

---

### Retailers
- [ ] View retailers list
- [ ] Create retailer (name, slug, website)
- [ ] Create retailer with logo
- [ ] Edit retailer
- [ ] Delete retailer (check purchase links)

---

### Creator Roles
- [ ] View roles list
- [ ] Create role (name, slug)
- [ ] Edit role
- [ ] Delete role (check assignments)

---

### Users (ADMIN Only)
- [ ] Users page accessible by ADMIN role only
- [ ] MODERATOR/JANITOR cannot access users page
- [ ] View users list with role badges
- [ ] Search users by name/email
- [ ] Click user row opens side panel
- [ ] Change user role via radio selection
- [ ] Save button disabled when role unchanged
- [ ] Role update persists after refresh
- [ ] Cannot change own role (self-edit prevention)
- [ ] Cannot change god admin's role
- [ ] Audit log created for role changes
- [ ] Toast notification on success/error

---

## Watchlist Tests (If Applicable)

### Create Watchlist
- [ ] Create new watchlist
- [ ] Name watchlist
- [ ] Set notification preferences
- [ ] Add mediums to watchlist
- [ ] Add franchises to watchlist
- [ ] Add entries to watchlist
- [ ] Add characters to watchlist
- [ ] Add creators to watchlist
- [ ] Add categories to watchlist
- [ ] Add subcategories to watchlist

### Watchlist Settings
- [ ] Edit watchlist name
- [ ] Change notification cadence
- [ ] Filter by storefront
- [ ] Include/exclude pre-orders
- [ ] Include/exclude in-stock items

### Watchlist Deletion
- [ ] Delete watchlist

---

## Edge Cases & Additional Tests

### Data Integrity
- [ ] Unique constraints (email, slug, UPC)
- [ ] Foreign key constraints
- [ ] Cascade deletes work correctly
- [ ] Soft deletes (if applicable)

### Performance
- [ ] Page load time < 2s
- [ ] Search returns results quickly
- [ ] No memory leaks on SPA navigation

### Security
- [ ] Protected routes require auth
- [ ] Admin routes require admin role
- [ ] No sensitive data in URLs
- [ ] CSRF protection works
- [ ] XSS prevention (no script injection)

### Accessibility
- [ ] Keyboard navigation works
- [ ] Focus indicators visible
- [ ] Alt text on images
- [ ] ARIA labels where needed
- [ ] Color contrast sufficient

### Browser Compatibility
- [ ] Chrome latest
- [ ] Firefox latest
- [ ] Safari latest
- [ ] Edge latest

---

## Test Data Cleanup

After testing, ensure:
- [ ] Test user accounts deleted or marked
- [ ] Test franchises/entries/products deleted
- [ ] No orphaned test data in database
- [ ] Seed data intact

---

## Sign-off Checklist

### Developer
- [ ] All tests passing locally
- [ ] No console errors
- [ ] Code review approved
- [ ] Documentation updated

### QA
- [ ] All checklist items verified
- [ ] No critical bugs
- [ ] No high-priority bugs
- [ ] Performance acceptable
- [ ] Security review passed

### Product
- [ ] Feature works as specified
- [ ] UX acceptable
- [ ] Edge cases handled
