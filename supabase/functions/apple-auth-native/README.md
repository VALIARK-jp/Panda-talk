# apple-auth-native (Supabase Edge Function)

pedal_share と同型。identityToken を検証し `hashed_token` を返す。Apple Team ID / Key は **クライアントに置かない**（JWT デコード＋既存ユーザー解決）。

## 環境変数

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="<service-role>"
supabase functions deploy apple-auth-native --no-verify-jwt
```

## リクエスト

```json
{
  "identityToken": "...",
  "authorizationCode": "...",
  "flow": "signup",
  "email": null,
  "givenName": null,
  "familyName": null
}
```
