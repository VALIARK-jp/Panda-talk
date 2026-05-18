# Auth setup

**認証フローの設計・状態遷移の正本:** [13_auth_flow_spec.md](./13_auth_flow_spec.md)（本書は主に **構築・運用・トラブルシュート**）。

**Valiark 共通の秘密・オンボーディング:** [valiark_client_secrets_playbook.md](valiark_client_secrets_playbook.md)

Panda Talk のログイン方式:

- Email + password with Supabase Auth
- Google via Supabase Auth **`signInWithOAuth`** (browser OAuth + PKCE; same deep link as email confirmation)
- LINE native login via `flutter_line_sdk` and a Supabase Edge Function
- Apple native login via `sign_in_with_apple` and a Supabase Edge Function

Supabase Auth is a **shared identity layer** (one `auth.users` row per person across Valiark apps).
Panda Talk keeps **all app-facing profile fields** in `panda_profiles` (`name`, `username`, `avatar_url`, `bio`, …).

**Dashboard note:** With `line-auth-native` / `apple-auth-native`, Users → **Providers** often shows **Email** for everyone; **Provider type** can stay empty. **Display name** in Auth is not the product source of truth—use per-app profile tables and onboarding (see [12_multi_app_supabase.md](./12_multi_app_supabase.md#authusers-と-dashboard-の見え方edge-function-認証)).

## Supabase

Apply the auth helper migration（`get_user_by_email` と **service_role への EXECUTE 付与**を含む）:

`supabase db push` には **`--project-ref` は付けられない**。リモートに出すには、いったん **プロジェクトをリンク**してから `push` する。

```sh
# 未リンクのときのみ（ref は Dashboard の Project Settings → General）
supabase link --project-ref rothadmykmuxncagbwqd

supabase db push
```

（SQL だけ手早く当てたい場合は Dashboard → **SQL Editor** で  
`grant execute on function public.get_user_by_email(text) to service_role;`  
を実行してもよい。）

`get_user_by_email` は `anon` / `authenticated` から取り上げているため、**`service_role` に `grant execute` されていない**環境では Edge Function の `admin.rpc('get_user_by_email')` が `permission denied` で失敗し、LINE / Apple の新規登録・ログインができない。

**`get_user_by_apple_id` / `get_user_by_line_id` も同様に、リモートへマイグレーション未適用だと RPC が存在せず失敗する。** 例:  
`Failed to search user: Could not find the function public.get_user_by_line_id(line_uid) in the schema cache`  
→ **`supabase/migrations/20260516150000_get_user_by_provider_ids.sql` をリモートに当てる**（`supabase db push` または SQL Editor でファイル内容を実行）。反映後、数分で良いが直らない場合は Dashboard で **Project Settings → API → Restart** やスキーマ再読み込みを試す。

Deploy the native auth functions:

```sh
supabase functions deploy line-auth-native
supabase functions deploy apple-auth-native
```

**クライアント:** [AuthService](../lib/infrastructure/auth/auth_service.dart) は `line-auth-native` / `apple-auth-native` 呼び出しに **`Authorization: Bearer <anon>` と `apikey`** を付与する（Supabase Edge の既定 `verify_jwt` 用）。

**デプロイ（どちらかで可）:**

- **A（推奨・そのまま動く）:** 通常の `supabase functions deploy` + 上記ヘッダー（リモートが JWT 検証 ON でも 401 にならない）
- **B（pedal_share 同型）:** `--no-verify-jwt` でデプロイし、ヘッダーなし POST でも可

Set function secrets（**Flutter `.env` には書かない**）:

```sh
supabase secrets set LINE_CHANNEL_ID="2010102462"
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
supabase functions deploy line-auth-native --no-verify-jwt
supabase functions deploy apple-auth-native --no-verify-jwt
```

`LINE_CHANNEL_ID` は [valiark_auth_config.dart](../lib/features/auth/valiark_auth_config.dart) の `valiarkLineChannelId`（**`2010102462`**、valiark-dev 共通。**pedal_share のチャンネルとは別**）と同じ値に揃える。

### URL Configuration (Dashboard checklist)

In **Supabase Dashboard → Authentication → URL Configuration**, do the following for every environment (e.g. valiark-dev). The app sends `emailRedirectTo` / `redirectTo`, but **GoTrue only honors redirects that appear in the allow list**.

1. **Redirect URLs**  
   Add **exactly** (including scheme and path):

   ```text
   io.valiark.pandatalk://callback
   ```

   （他 Valiark アプリは別スキームを追加。例: `io.valiark.whoeats://callback`）

   If you override the build with `--dart-define=PANDA_TALK_AUTH_REDIRECT_URL=...`, add **that URL** here as well.

2. **Site URL**  
   If this is left as `http://localhost:3000` (common for local Next.js), then **when `redirect_to` is rejected or missing**, the confirmation flow falls back to Site URL. On a **physical phone**, `localhost` is the device itself, so the browser shows “cannot reach this site”.  
   After Redirect URLs are correct, new emails should use the app scheme; still, set Site URL to a sensible default (e.g. your production `https://…` origin or team policy) so any fallback is not stuck on localhost.

3. After changing settings, trigger a **new** signup confirmation or password-reset email. Old messages keep the old redirect target.

### Troubleshooting: email opens `localhost:3000`

- **Cause:** Supabase did not accept the app’s `redirect_to` (not in Redirect URLs), so the user is sent to **Site URL** (often `http://localhost:3000`).  
- **Fix:** Add `io.valiark.pandatalk://callback` to **Redirect URLs**, fix **Site URL** as above, resend the email.  
- **Verify:** In debug builds, check the console for `[AuthService] … authRedirectUrl=…` and confirm it matches a Dashboard entry.

### Troubleshooting: `Code verifier could not be found in local storage`

- **Cause (same device):** PKCE の code verifier は **サインアップ／リセットを開始したアプリ内** にだけ保存される。`supabase_flutter` の **`detectSessionInUri: true`** と [ValiarkDeeplinkHandler](../lib/infrastructure/auth/valiark_deeplink_handler.dart) が同じリンクで `getSessionFromUrl` を二度呼ぶと、1回目で消えた verifier で2回目が失敗することがある → **Panda Talk では `detectSessionInUri: false`** にし、Valiark ハンドラに一本化している。
- **Cause (別端末):** メールのリンクを **別の端末のメールアプリ** から開くと、その端末に verifier が無い。
- **Fix:** 同じ iPhone でサインアップ→同じ端末でメールのリンクを開く。必要なら `supabase db push` 後にアプリを再ビルドして再試行。

Each Valiark app uses its **own** redirect URL (`PANDA_TALK_AUTH_REDIRECT_URL` for Panda Talk). Register the **same** scheme in that app’s Android intent filter and iOS URL types (see `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`).

### Client behaviour (deeplinks and auth)

- **`lib/infrastructure/auth/valiark_deeplink_handler.dart`**: `AppLinks.getInitialLink` + `uriLinkStream` で PKCE の `code`（または implicit の fragment）付き URI だけ `getSessionFromUrl`。**同一 URI の二重処理を抑止**。
- **`AuthGate`**: starts the handler once after first frame.
- **`AuthService`**: Google OAuth launch, LINE / Apple platform errors, `signOut` retry, email sign-in blocked when `emailConfirmedAt` is null (then sign out), `requestPasswordReset` / `resendSignupEmail`, and `AuthException` messages for common failures.
- **`LoginScreen`**: email is **password only** (signup sends confirmation mail once; login uses password). `onAuthStateChange` → `popUntil(isFirst)` on `signedIn` after confirmation / reset links, plus password reset and resend confirmation.

## Flutter

### `.env` と dart-define

`lib/main.dart` で `flutter_dotenv` がルートの **`.env`** を読みます（`pubspec.yaml` の `assets` に含める）。**優先順位:** `--dart-define` → `.env` の該当キー →（API / redirect だけ）コード上のフォールバック。

- **初回:** `cp .env.example .env` でテンプレを作り、`PANDA_TALK_SUPABASE_URL` / `PANDA_TALK_SUPABASE_ANON_KEY` を必ず設定する（未設定だと起動時にエラー）。
- **CI / 本番:** 空の `.env` を置き、秘密は `--dart-define` のみ渡す運用でもよい。

### LINE（実装パターンは pedal_share 同型・チャンネルは valiark-dev 共通）

- **クライアント:** 既定は `valiarkLineChannelId`（`2010102462`）。上書きする場合のみ `.env` の `PANDA_TALK_LINE_CHANNEL_ID` または dart-define。
- **Edge:** Supabase Secret `LINE_CHANNEL_ID`（Dashboard 設定済みならそのまま）。チャンネル **シークレット**はクライアントに載せない。
- **Android:** `local.properties` の `lineChannelId` は省略可（未設定時 `2010102462`）。

### 実機での認証と「localhost」

- **メール / LINE / Apple / Google の認証**は `PANDA_TALK_SUPABASE_URL`（`https://….supabase.co`）向け。**実機からもそのまま届く**（Mac の LAN IP は不要）。
- メールリンクが **ブラウザで `localhost` に飛ぶ**のは、多くの場合 **Supabase Dashboard の Site URL が `http://localhost:3000` など**で、Redirect URLs に `io.valiark.pandatalk://callback` が無い／一致しないため（[URL Configuration](#url-configuration-dashboard-checklist)）。アプリの `emailRedirectTo` は `.env` の `PANDA_TALK_AUTH_REDIRECT_URL` と一致させる。
- **API（マッチ・質問・プロフィール等）** は baselink と同様、`.env` の **`PANDA_TALK_API_BASE_URL` にチームの dev 用 HTTPS** を入れる（例: `https://panda-talk-backend….workers.dev`）。**実機でスマホの IP に書き換える運用はしない。**
- `.env.example` の `localhost:8787` は **シミュレータ + Mac 上 wrangler dev** 専用。実機の `.env` が localhost のままだと API だけ届かない（認証の Supabase は届く）。
- **`localhost` のときだけ** プロフィールは Supabase 直にフォールバック。RLS: `20260518100000_panda_profiles_rls_self.sql` を `supabase db push`。

### Sign in with Google

1. **Google Cloud Console** で OAuth 同意画面を構成し、**OAuth 2.0 クライアント**（種類 **Web アプリケーション**）を作成する。取得した **Client ID と Client Secret** を控える。
2. 同じクライアントの **承認済みのリダイレクト URI** に、Supabase のコールバックを追加する（Dashboard の Google プロバイダー画面に表示される **`https://<project-ref>.supabase.co/auth/v1/callback`** 形式。プロジェクトごとに違う）。
3. **Supabase Dashboard → Authentication → Providers → Google** をオンにし、**Client ID / Client Secret** を設定する（秘密は Supabase 側のみ。Flutter の `.env` には **不要**）。
4. **Redirect URLs** に `io.valiark.pandatalk://callback` が含まれていること（[URL Configuration](#url-configuration-dashboard-checklist) と同じ）。

アプリは `AuthService.signInWithGoogle` → `signInWithOAuth(OAuthProvider.google, redirectTo: …)` で外部ブラウザを開く。Android では `supabase_flutter` が **外部ブラウザ** で開く実装になっている。認証後の戻りはメールの PKCE と同様に **`ValiarkDeeplinkHandler` が `getSessionFromUrl` で処理**する。

### Sign in with Apple

On **iOS**, Sign in with Apple requires `ios/Runner/Runner.entitlements` (included in this repo) and the same capability enabled for the App ID in **Apple Developer** (bundle id `com.valiark.pandaTalk`).

If the app shows *「Apple認証に失敗しました」*, that is `AuthorizationErrorCode.failed` from `sign_in_with_apple` **before** the Edge Function runs — check Xcode **Signing & Capabilities → Sign in with Apple**, provisioning profiles, and try a **physical device** if the simulator misbehaves.

### LINE / Apple: ネイティブは成功するがアプリに入れない

Edge Function `line-auth-native` / `apple-auth-native` は `hashed_token` と **`otp_type: "magiclink"`** を返す。[AuthService](../lib/infrastructure/auth/auth_service.dart) は pedal_share と同様 **`verifyOTP(tokenHash:, type: OtpType.email)`**（signup 時のみ `OtpType.signup`）。**`email` / `redirect_to` は付けない**（`Only the token_hash and type should be provided` 回避）。

### LINE / Apple: 既存メールなのに `createUser` で「already registered」

`apple_id` / `line_id` だけでは既存にヒットしないが、**同じメールのユーザーが GoTrue に既にある**（メール登録・過去の別表現など）場合、いまは **`get_user_by_email` で拾ってプロバイダ ID を付与**し、そのままマジックリンクでログインさせる。`createUser` が重複エラーになった場合は **`get_user_by_email` を再試行したうえで、まだ取れなければ Admin `listUsers` でメール一致ユーザーを探す**（RPC 未適用・不整合時の救済）。さらに **LINE は `accessToken` のみのときメールが `…@line.local` になり、実アドレスで保存された既存行とズレる**ことがあるため、`get_user_by_line_id` RPC が null のとき **`listUsers` で `app_metadata.line_id` を直接照合する**（Apple も `apple_id` で同様）。変更後は **`supabase functions deploy line-auth-native apple-auth-native`**。

**注意:** `Failed to create user` + `already registered` は **`createUser` を実行したあと**にだけ返る。`flow: login` で未登録なら **`createUser` は呼ばれず** 404 `account_not_found` になる。ログイン画面なのに前者が出る場合は **実際のリクエストが `signup` になっている**（別画面・`flow` 未送信で既定 signup）か、上記救済前の古い Edge を当てている可能性がある。デバッグ時は Flutter ログの `[AuthService] … flow=…` を確認。

- **`identity_conflict`（409）:** そのユーザーに **別の Apple / LINE ID がすでに紐づいている**ときはなりすまし連結を拒否。`details` を画面に出す。

### LINE / Apple: ログイン画面では新規ユーザーを作らない（`flow`）

アプリの **ログイン** と **新規登録** は同じ `signInWithLine` / `signInWithApple` を呼ぶが、リクエスト JSON の **`flow`** で Edge の挙動を分ける。

- **`flow: login`**: その LINE / Apple ID に紐づくユーザーのみログイン。いなければ **404 / `account_not_found`**（**`createUser` しない**）。
- **`flow: signup` または未指定**: いなければ **従来どおりユーザー作成**（旧クライアント互換のため未指定は signup 扱い）。

### LINE / Apple: 同一利用者の判定（プロバイダ ID・メール）

Apple は **JWT のメール表現が変わる**などがあり、**メールだけ**で既存ユーザーを探すと同じ人でも `createUser` に進むことがある。マイグレーション `20260516150000_get_user_by_provider_ids.sql` の **`get_user_by_apple_id` / `get_user_by_line_id`** と **`get_user_by_email` の大小無視**（`20260516140000`）をリモートに当て、**両 Edge Function を再デプロイ**すること。

### 利用規約・プライバシー URL

`.env` または dart-define で任意指定:

- `PANDA_TALK_TERMS_URL`（HTTPS）
- `PANDA_TALK_PRIVACY_URL`（HTTPS）

未設定のとき、画面上の「読む」は **掲載準備中** のスナックバーになる。

Android でチャンネル ID を上書きする場合のみ `android/local.properties`:

```properties
lineChannelId=2010102462
```

Flutter 起動（`.env` に Supabase URL / anon を書いたうえで）:

```sh
./scripts/flutter_run_dev.sh
```
