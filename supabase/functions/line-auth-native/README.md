# line-auth-native (Supabase Edge Function)

pedal_share と同型。ネイティブ LINE ログイン → `hashed_token` を返し、クライアントが `verifyOTP(tokenHash)` でセッション化する。

## 環境変数（Supabase Secrets のみ。Flutter `.env` には載せない）

- `LINE_CHANNEL_ID` — valiark-dev 共通（`2010102462`。`lib/features/auth/valiark_auth_config.dart` と同値。pedal_share とは別チャンネル）
- `SUPABASE_URL` — プロジェクト URL（デプロイ時に自動）
- `SUPABASE_SERVICE_ROLE_KEY` — service_role

```bash
supabase secrets set LINE_CHANNEL_ID="2010102462"
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="<service-role>"
supabase functions deploy line-auth-native --no-verify-jwt
```

`--no-verify-jwt` は pedal_share と同様（クライアントは anon ヘッダーなしで POST）。

## リクエスト

```json
{ "accessToken": "<line access token>", "flow": "login" }
```

`flow`: `login`（未登録は 404） / `signup` または未指定（新規作成可）。
