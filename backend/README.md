# Panda Talk API (Cloudflare Worker)

## 環境変数の置き場所

| 環境 | Supabase URL / anon | service_role |
|------|---------------------|--------------|
| ローカル `wrangler dev` | `backend/.dev.vars`（`npm run sync:dev-vars` で root `.env` から生成） | `npm run dev` が Supabase CLI から一時注入 |
| dev デプロイ | root `.env` の `PANDA_TALK_SUPABASE_*` | `wrangler secret put SUPABASE_SERVICE_ROLE_KEY` |
| prod デプロイ | root `.env.prod` | `wrangler secret put SUPABASE_SERVICE_ROLE_KEY --env production` |

FCM 送信用に `FIREBASE_PROJECT_ID` と `FIREBASE_SERVICE_ACCOUNT_JSON` も Cloudflare Workers 側の secret として設定する。

`wrangler.toml` には **秘密・URL を書かない**（`npm run deploy` / `deploy:prod` が env ファイルから `--var` で渡す）。

## コマンド

```bash
npm run sync:dev-vars   # .env → backend/.dev.vars
npm run dev             # valiark-dev + ローカル API
npm run deploy          # panda-talk-backend（.env）
npm run deploy:prod     # panda-talk-backend-prod（.env.prod）
```

手順: [docs/16_valiark_prod_panda_talk_setup.md](../docs/16_valiark_prod_panda_talk_setup.md)
