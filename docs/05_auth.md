# Auth setup

Panda Talk uses the same three login patterns as **`pedal_share`** (repo: `pedal_share`, email / LINE / Apple):

- Email + password with Supabase Auth
- LINE native login via `flutter_line_sdk` and a Supabase Edge Function
- Apple native login via `sign_in_with_apple` and a Supabase Edge Function

Supabase Auth is treated as a shared account base for future apps. Panda Talk
stores app-specific profile data in `panda_profiles`, not in a generic `users`
table.

## Supabase

Apply the auth helper migration:

```sh
supabase db push
```

Deploy the native auth functions:

```sh
supabase functions deploy line-auth-native
supabase functions deploy apple-auth-native
```

Set function secrets:

```sh
supabase secrets set LINE_CHANNEL_ID=<line-channel-id>
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

### URL Configuration (Dashboard checklist)

In **Supabase Dashboard → Authentication → URL Configuration**, do the following for every environment (e.g. valiark-dev). This matches the idea behind `pedal_share`’s `APP_AUTH_REDIRECT_URL`: the app sends `emailRedirectTo` / `redirectTo`, but **GoTrue only honors redirects that appear in the allow list**.

1. **Redirect URLs**  
   Add **exactly** (including scheme and path):

   ```text
   io.valiark.auth://callback
   ```

   If you override the build with `--dart-define=VALIARK_AUTH_REDIRECT_URL=...`, add **that URL** here as well.

2. **Site URL**  
   If this is left as `http://localhost:3000` (common for local Next.js), then **when `redirect_to` is rejected or missing**, the confirmation flow falls back to Site URL. On a **physical phone**, `localhost` is the device itself, so the browser shows “cannot reach this site”.  
   After Redirect URLs are correct, new emails should use the app scheme; still, set Site URL to a sensible default (e.g. your production `https://…` origin or team policy) so any fallback is not stuck on localhost.

3. After changing settings, trigger a **new** signup confirmation or password-reset email. Old messages keep the old redirect target.

### Troubleshooting: email opens `localhost:3000`

- **Cause:** Supabase did not accept the app’s `redirect_to` (not in Redirect URLs), so the user is sent to **Site URL** (often `http://localhost:3000`). Same pattern as `pedal_share` if `APP_AUTH_REDIRECT_URL` were missing from the allow list.  
- **Fix:** Add `io.valiark.auth://callback` to **Redirect URLs**, fix **Site URL** as above, resend the email.  
- **Verify:** In debug builds, check the console for `[AuthService] … authRedirectUrl=…` and confirm it matches a Dashboard entry.

Each mobile app that handles signup confirmation or password-reset deep links must register the same URL scheme (`io.valiark.auth`) in its Android intent filter and iOS URL types, as in this repo.

### Behaviour aligned with `pedal_share`

- **`lib/infrastructure/auth/valiark_deeplink_handler.dart`**: same role as `pedal_share/lib/shared/services/deeplink_handler.dart` — `AppLinks.getInitialLink` + `uriLinkStream` and `getSessionFromUrl` for the shared redirect (plus `login-callback` path substring for older links).
- **`AuthGate`**: starts the handler once after first frame (pedal starts it from `AuthWrapper.didChangeDependencies`).
- **`AuthService`**: stricter LINE / Apple platform errors, `signOut` retry, email sign-in blocked when `emailConfirmedAt` is null (then sign out), `requestPasswordReset` / `resendSignupEmail`, richer `AuthException` messages (see `pedal_share` `handleAuthException`).
- **`LoginScreen`**: email is **password only** (signup sends confirmation mail once; login uses password). `onAuthStateChange` → `popUntil(isFirst)` on `signedIn` after confirmation / reset links, plus password reset and resend confirmation.

## Flutter

On **iOS**, Sign in with Apple requires `ios/Runner/Runner.entitlements` (included in this repo) and the same capability enabled for the App ID in **Apple Developer** (bundle id `com.pandatalk.pandaTalk`).

For LINE on Android, add this to `android/local.properties`:

```properties
lineChannelId=<line-channel-id>
```

Run the app with the same channel id for Dart-side SDK setup:

```sh
flutter run --dart-define=PANDA_TALK_LINE_CHANNEL_ID=<line-channel-id>
```

The app defaults to the dev Supabase project and local backend. Override with:

```sh
flutter run \
  --dart-define=PANDA_TALK_API_BASE_URL=http://localhost:8787 \
  --dart-define=PANDA_TALK_SUPABASE_URL=<supabase-url> \
  --dart-define=PANDA_TALK_SUPABASE_ANON_KEY=<anon-key> \
  --dart-define=VALIARK_AUTH_REDIRECT_URL=io.valiark.auth://callback \
  --dart-define=PANDA_TALK_LINE_CHANNEL_ID=<line-channel-id>
```
