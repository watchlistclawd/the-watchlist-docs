# Email Infrastructure + Auth Flow Overhaul

## Phase 1: Resend + Supabase SMTP (User config)
- [x] Provide step-by-step instructions for Resend + Supabase SMTP setup

## Phase 2: Auth Callback Route
- [x] Create `app/auth/confirm/route.ts` — handles signup/recovery/email_change OTP verification

## Phase 3: Sign-Up with Email Verification
- [x] Rewrite sign-up action to use `supabase.auth.signUp()` (was admin API)
- [x] Add `resendConfirmationAction` for re-sending verification email
- [x] Update sign-up form to show "check your email" card on success
- [x] Add `?verified=true` and `?error=confirmation_failed` handling to sign-in form

## Phase 4: Password Reset via Email
- [x] Replace `resetPasswordSchema` with `forgotPasswordSchema` + `updatePasswordSchema`
- [x] Rewrite forgot-password action (email-only, sends reset link)
- [x] Rewrite `reset-password-form.tsx` → `ForgotPasswordForm` (email-only)
- [x] Create reset-password page + action + `UpdatePasswordForm` component

## Phase 5: Email Change Fix
- [x] Update `SecurityTab` to show "check your email" toast on email change
- [x] Handle `?email_changed=true` on settings page

## Phase 6: i18n + Cleanup + Docs
- [x] Add new auth i18n keys (EN + JA)
- [x] Update auth validation test file for new schemas
- [x] Update `docs/TECH.md` — email infrastructure section
- [x] Update `docs/USERS.md` — auth flow descriptions
- [x] Update `docs/SITEMAP.md` — new pages/routes/components

## Phase 7: Verification
- [x] TypeScript compilation — no new errors (pre-existing playwright issue unrelated)
- [x] Auth validation tests — 18/18 passing

## Review
All code changes complete. User needs to complete Phase 1 (Resend/Supabase SMTP configuration in browser) before testing the flows end-to-end.
