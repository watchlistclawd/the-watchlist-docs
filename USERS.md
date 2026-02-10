# The Watchlist - User System

## Roles

| Role | Level | Permissions |
|------|-------|-------------|
| `USER` | 0 | Browse, create watchlists, receive notifications |
| `JANITOR` | 1 | All USER permissions + access admin panel |
| `MODERATOR` | 2 | All JANITOR permissions + edit/delete entities, manage users |
| `ADMIN` | 3 | Full access (all CRUD, user management, system settings) |

Roles are stored as a `user_role` pgEnum in `lib/db/schema.ts`.

Future: `COMPANY_MOD` -- company-specific moderation role.

---

## Permission Checks

| Function | Location | Description |
|----------|----------|-------------|
| `getUser()` | `lib/auth.ts` | Returns current authenticated user with role, or null |
| `requireAuth()` | `lib/auth.ts` | Returns user or redirects to sign-in |
| `requireAdmin()` | `lib/admin/role-check.ts` | Returns session if user has JANITOR+ role; redirects otherwise |
| `canEdit(role)` | `lib/admin/role-check.ts` | Returns true for MODERATOR, ADMIN |
| `canDelete(role)` | `lib/admin/role-check.ts` | Returns true for ADMIN only |

Admin panel is accessible to JANITOR+ roles. Users page is ADMIN-only.

---

## Authentication Flow

- **Provider**: Supabase Auth (email/password credentials)
- **Sessions**: Cookie-based SSR sessions via `@supabase/ssr`
- **Session refresh**: `middleware.ts` calls `supabase.auth.getUser()` on every request to refresh the session cookie
- **Password hashing**: Handled by Supabase (no bcryptjs)
- **Password requirements**: 8+ characters, uppercase, lowercase, number
- **2FA**: TOTP via Supabase MFA (Google Authenticator compatible)
  - Enroll: `supabase.auth.mfa.enroll({ factorType: 'totp' })`
  - Challenge/Verify: `supabase.auth.mfa.challenge()` / `supabase.auth.mfa.verify()`
  - Unenroll: `supabase.auth.mfa.unenroll()`
  - Enable/disable in Settings -> Security tab
  - Sign-in conditionally prompts for 2FA code when enabled

### Sign-Up Flow
1. User submits email + password on the sign-up page.
2. `supabase.auth.signUp()` creates the account and sends a verification email.
3. User clicks the verification link in the email.
4. Link goes to `/auth/confirm?type=signup`, which verifies the OTP token.
5. On success, redirects to `/auth/signin?verified=true`.
6. User can now sign in with their credentials.

**Note**: Users cannot sign in until they verify their email.

### Password Reset Flow
1. User clicks "Forgot password?" on the sign-in page, taken to `/auth/forgot-password`.
2. User enters their email address and submits.
3. Supabase sends a password reset email with a recovery link.
4. User clicks the link, which goes to `/auth/confirm?type=recovery`.
5. The confirm page verifies the OTP and redirects to `/auth/reset-password`.
6. User sets a new password using the active recovery session.
7. On success, redirected to the sign-in page.

### Email Change Flow
1. User changes their email in Settings -> Security tab.
2. A confirmation email is sent to the new email address.
3. User clicks the confirmation link in the email.
4. Link goes to `/auth/confirm?type=email_change`.
5. On success, redirects to `/settings?email_changed=true`.

### Supabase Clients

| Client | Location | Usage |
|--------|----------|-------|
| Server | `lib/supabase/server.ts` | Server Components/Actions (cookie-based, respects RLS) |
| Browser | `lib/supabase/client.ts` | Client Components (browser-side) |
| Admin | `lib/supabase/admin.ts` | Service-role client (bypasses RLS, server-side only) |

### God Admin

The email specified in `GOD_ADMIN_EMAIL` env var is automatically promoted to ADMIN role on sign-up. A DB trigger creates the user profile, then the sign-up action updates the role to ADMIN. The god admin still needs to verify their email before signing in (same flow as all users). The god admin's role cannot be changed by other admins.

### User Profile

Supabase manages `auth.users` (email, password, MFA). The app extends this with a `user_profiles` table (same UUID as PK) storing role and preferences. Profile is created on first sign-up.

---

## Account Settings

### Profile Tab
- Display name
- Theme toggle (light/dark)
- NSFW content toggle (hidden by default, opt-in only)
- Language selector (English/Japanese)

### Security Tab
- Change email (sends confirmation to new address; see Email Change Flow above)
- Change password (requires current password)
- Enable/disable 2FA

### Danger Zone Tab
- Account deletion with 3-step confirmation (type "DELETE" to confirm)

---

## NSFW Policy

- NSFW content is hidden site-wide by default
- Guest users never see NSFW products and are not informed of their existence
- Only registered users who explicitly enable "Show NSFW" in settings will see adult/mature content

---

## QA Test Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | moderator@test.com | TestPass1 |
| Janitor | janitor@test.com | TestPass1 |
| User | test2@test.com | Arbiter1821! |

QA tests live in `~/projects/the-watchlist-QA/` (separate project).
Run with dev server at :3000: `cd ~/projects/the-watchlist-QA && npm test`
