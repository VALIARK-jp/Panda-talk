# Supabase DB

このディレクトリには、Supabase/PostgreSQL に適用する SQL migration を置く。

## valiark-dev プロジェクト

Valiark 組織の **`valiark-dev`** に Panda Talk（および将来の他アプリ）の DB を集約する。

1. Dashboard で `valiark-dev` を作成する（未作成の場合）。
2. **Settings → API** で Project URL・`anon`・`service_role` を控える。
3. ローカル CLI をそのプロジェクトに紐づける:

```sh
supabase link --project-ref <valiark-dev の project ref>
```

4. リポジトリ内の接続先を書き換える:
   - [backend/wrangler.toml](../backend/wrangler.toml) の `SUPABASE_URL` / `SUPABASE_ANON_KEY`
   - Flutter の `--dart-define=PANDA_TALK_SUPABASE_URL=...` と `PANDA_TALK_SUPABASE_ANON_KEY=...`（または [lib/config/app_config.dart](../lib/config/app_config.dart) のデフォルトを開発用に上書き）
5. スクリプト用に **`SUPABASE_PROJECT_REF`**（project ref のみ）を環境変数で渡すか、Dashboard の ref を `supabase link` と揃える。

## Panda Talk: DB と API を順に紐付ける

次の順でやると、DB → バックエンド → Flutter が一貫します（例: project ref `rothadmykmuxncagbwqd`）。

1. **Supabase に schema を載せる**（Panda 用 migration のみ）
   ```sh
   cd /path/to/panda_talk
   supabase login
   supabase link --project-ref rothadmykmuxncagbwqd
   supabase db push
   ```
2. **開発用データ投入**（任意・API の動作確認に便利）
   ```sh
   cd backend
   export SUPABASE_PROJECT_REF=rothadmykmuxncagbwqd
   npm run seed:dev
   ```
3. **バックエンドを実 DB モードで起動**
   - [backend/wrangler.toml](../backend/wrangler.toml) の `SUPABASE_ANON_KEY` を Dashboard の **anon public** に差し替える（`YOUR_VALIARK_DEV_ANON_KEY` のままでは起動はしても Auth 周りで不整合になり得る）。
   - 本番相当の Workers では `wrangler secret put SUPABASE_SERVICE_ROLE_KEY`（ローカル `npm run dev:db` は CLI から一時取得して渡す）。
   ```sh
   cd backend
   export SUPABASE_PROJECT_REF=rothadmykmuxncagbwqd
   npm run dev:db
   ```
4. **API 疎通**（別ターミナル）
   ```sh
   curl -sS "http://localhost:8787/questions?limit=2"
   curl -sS "http://localhost:8787/questions/hot?limit=2"
   ```
5. **Flutter**（Supabase 直ではなく **API URL** が主）
   - 実機・通常開発: `.env` の `PANDA_TALK_API_BASE_URL` は **デプロイ済み HTTPS**（baselink の dev API URL と同じ運用）。チームから配布。
   - `localhost:8787` は **シミュレータ + Mac で wrangler dev** するときだけ。
   - Supabase Auth / Edge Functions をアプリから使う場合だけ、`PANDA_TALK_SUPABASE_URL` と `PANDA_TALK_SUPABASE_ANON_KEY` を **Dashboard と同じ valiark-dev** に合わせる。

**共有 DB（valiark-dev）の注意**: Who eats / Terravera も同じプロジェクトに `db push` 済みだと、`panda_talk` だけで `supabase db push` を叩くと「remote にあって local にない migration」エラーになることがあります。対策として、このリポジトリの `supabase/migrations/` に **他アプリ由来の migration と同じファイル名の stub**（`select 1` のみ）を置き、履歴を揃えています。Panda だけの**新規** Supabase プロジェクトを `panda_talk` から作る場合は、それら stub を削除してから `db push` するか、先に Panda 用 4 本だけを適用する運用にしてください。

## 初回適用

Supabase CLI でプロジェクトを link 済みなら以下で適用する。

```sh
supabase db push
```

CLI を使わない場合は、`migrations/` 内の SQL を **時系列順に** Supabase Dashboard の SQL Editor で実行する。

## 方針

- `auth.users` は複数アプリ共通のログイン基盤として扱う。**1人1 `auth` ユーザーを目標**にし、LINE は**共通チャンネル**、Edge Function の **LINE / Apple ユーザー解決ルールは全アプリで同一**にする（詳細は [docs/12_multi_app_supabase.md](../docs/12_multi_app_supabase.md)）。
- Panda Talk 固有のプロフィールは `panda_profiles.id = auth.users.id` に分ける。
- Panda Talk のドメイン表は `panda_` 接頭辞（例: `panda_questions`, `panda_answers`）で他アプリと衝突しないようにする。
- Flutter は Supabase を直接叩かず、Hono API 経由で DB にアクセスする。
- Hono 側は Supabase service role key を使う前提なので、全テーブルで RLS を有効化し、クライアントからの直接アクセス用 policy はまだ作らない。
- ゲスト回答は登録前は端末ローカルに保持し、新規登録時に `panda_answers` へ移行する。

## Backend secrets

Hono から実DBを使うには、Cloudflare Workers に以下を設定する。

```sh
wrangler secret put SUPABASE_SERVICE_ROLE_KEY
```

`SUPABASE_URL` と `SUPABASE_ANON_KEY` は `backend/wrangler.toml` の `[vars]` に設定する。`SUPABASE_SERVICE_ROLE_KEY` がない環境では、backend は mock repository に戻る。

ローカルで実DBにつなぐときは、長い `--var` を直接打たずに以下を使う。

```sh
cd backend
export SUPABASE_PROJECT_REF=<valiark-dev の project ref>
npm run dev:db
```

`SUPABASE_PROJECT_REF` を省略した場合は `backend/wrangler.toml` の `SUPABASE_URL` から project ref を読み取る（`https://<ref>.supabase.co` 形式であること）。

## Dev seed

開発用データは **migration 適用後**に投入する。

```sh
cd backend
export SUPABASE_PROJECT_REF=<valiark-dev の project ref>
npm run seed:dev
```

旧プロジェクトから移す場合は下記「旧プロジェクトから dev データを引き継ぐ場合」を参照。

このスクリプトは Supabase CLI のログイン情報から service role key を取得し、開発用の Auth ユーザー、質問、回答、コメント、いいね、`panda_match_scores` を投入する。key はファイルには保存しない。

### 旧プロジェクトから dev データを引き継ぐ場合

- **簡便**: 上記 seed を **valiark-dev** に対して再実行する（Auth ユーザーは Admin API で作成済みなら upsert）。
- **丸ごと**: 旧 DB から `pg_dump` / `COPY` で移す。`auth.users` を含む場合は [Migrating to Supabase](https://supabase.com/docs/guides/platform/migrating-to-supabase) の手順とシーケンス・衝突に注意する。

## Edge Functions

ローカルで検証する場合は [Supabase CLI の Edge Functions](https://supabase.com/docs/guides/functions) を参照。

**valiark-dev へデプロイ**（事前に `supabase login` と `supabase link --project-ref <valiark-dev の ref>` が必要）:

```sh
cd /path/to/panda_talk
supabase secrets set LINE_CHANNEL_ID="2010102462"
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="<service-role>"
supabase functions deploy line-auth-native --no-verify-jwt
supabase functions deploy apple-auth-native --no-verify-jwt
```

pedal_share と同型: **LINE / Apple の秘密は Supabase Secrets のみ**。Flutter `.env` には載せない。`--no-verify-jwt` でクライアントは `Content-Type` のみで POST する。
