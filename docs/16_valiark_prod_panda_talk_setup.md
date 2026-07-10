# valiark-prod: Panda Talk テスター配布（30人規模）

**目的:** テスターは **最初から `valiark-prod` のみ**を使う。質問の `user_id`（投稿者）を prod 上で正本にする。  
**やらない:** dev で遊ばせてから auth + DB を prod へ移行（投稿者付きデータのため非推奨）。

**関連:** [12_multi_app_supabase.md](./12_multi_app_supabase.md)（dev 共有の設計） / [05_auth.md](./05_auth.md) / [14_development_api_and_devices.md](./14_development_api_and_devices.md) / [valiark_client_secrets_playbook.md](./valiark_client_secrets_playbook.md)

---

## 役割分担

| 作業 | 誰 |
|------|-----|
| 手順書・スクリプト・`wrangler` prod 環境・seed ガード | リポジトリ（Agent 済み） |
| Dashboard（Auth Redirect、API キー控え） | あなた |
| `supabase login` / `link` / `db push` / Functions deploy | あなた（下記スクリプト実行） |
| `wrangler secret` / `deploy --env production` | あなた |
| TestFlight・テスター招待 | あなた |
| prod で初回16問（運営手動投稿） | あなた |

---

## Phase 1 — Supabase（valiark-prod）

### 1-1 Dashboard（あなた）

1. **Settings → API** で Project URL / `anon` / `service_role` を vault に保存（チャットに貼らない）。
2. **Authentication → URL Configuration**
   - Redirect URLs: `io.valiark.pandatalk://callback`
   - `--dart-define` で変える場合は **その URL も**登録。
3. Project ref を [scripts/valiark-project-refs.env.example](../scripts/valiark-project-refs.env.example) をコピーした `scripts/valiark-project-refs.env` に記入（gitignore 済み）。

### 1-2 DB migration

**空の valiark-prod** では、リポジトリの migration を **時系列どおり一括** `db push` する（Who eats / Terravera 用 **stub** は `select 1` のみで、Panda 用テーブルは別ファイルで作成される）。

```bash
# リポジトリルート
export VALIARK_PROD_PROJECT_REF='<prod の ref>'
./scripts/valiark-prod-supabase-setup.sh db
```

手動の場合:

```bash
supabase login
supabase link --project-ref "$VALIARK_PROD_PROJECT_REF"
supabase db push
```

**確認（Dashboard → Table Editor）:** `panda_profiles`, `panda_questions`, `panda_answers` など。  
**RPC:** `get_user_by_email`, `get_user_by_line_id`, `get_user_by_apple_id` が無いと LINE/Apple ログインが失敗する（[05_auth.md](./05_auth.md)）。

### 1-3 Edge Functions

```bash
./scripts/valiark-prod-supabase-setup.sh functions
```

Secrets / Functions:

```bash
./scripts/valiark-prod-set-edge-secrets.sh   # LINE_CHANNEL_ID のみ（SUPABASE_* は Edge に自動注入）
./scripts/valiark-prod-supabase-setup.sh functions
```

### CLI ログイン: `User can have up to 20 personal access tokens`

`supabase login` のブラウザ画面で **Unable to create CLI sign-in** と出る場合、Supabase アカウントの **Personal Access Token が20個上限**です。

1. https://supabase.com/dashboard/account/tokens を開く  
2. 使っていない古い **CLI_*** トークンを削除（10個程度空ける）  
3. ターミナルで `supabase login` をやり直す  

`supabase link` だけなら、すでにログイン済みなら不要なこともあります。

---

### `db push` が `connection refused` / `cli_login_postgres` で失敗するとき

CLI は **Session pooler（port 5432）** 経由で接続します。次を **上から順に**試す。

#### A. Network Bans（いちばん多い）

Dashboard → **Database → Settings** → **Network Bans** で自分の IP が **Banned** になっていないか確認 → **Unban**。

（CLI の `link` / `db push` を短時間に何度も叩くと Fail2ban で弾かれることがあります。30分で自動解除もされます。）

CLI（experimental）:

```bash
supabase network-bans get --project-ref "$VALIARK_PROD_PROJECT_REF" --experimental
# 必要なら unban（Dashboard の方が簡単）
```

#### B. Network Restrictions

**Database → Settings → Network Restrictions** で、開発マシンの IP を許可するか、移行作業中だけ制限を緩める。

#### C. DB パスワードを渡して link / push

Dashboard → **Database → Connection string** の **Database password** を使う:

```bash
export SUPABASE_DB_PASSWORD='<your-db-password>'
./scripts/valiark-prod-supabase-setup.sh db
```

#### D. `IPv6 is not supported on your current network`（**`DB_PUSH_SKIP_POOLER` をやめる**）

`--skip-pooler` は **`db.<ref>.supabase.co`（IPv6 直結）** 向けです。自宅 Wi‑Fi など **IPv4 のみ** だとタイムアウトします。

```bash
unset DB_PUSH_SKIP_POOLER
export SUPABASE_DB_PASSWORD='<Dashboard → Database password>'
./scripts/valiark-prod-supabase-setup.sh db
```

まだ **pooler で `connection refused`** なら → **Network Bans で Unban**（上記 A）が先。

CLI を新しくして link し直す:

```bash
brew upgrade supabase
rm -rf supabase/.temp
export SUPABASE_DB_PASSWORD='<password>'
supabase link --project-ref "$VALIARK_PROD_PROJECT_REF" -p "$SUPABASE_DB_PASSWORD"
supabase db push -p "$SUPABASE_DB_PASSWORD"
```

#### E. Pooler の接続文字列を直接渡す（確実）

Dashboard → **Connect** → **Session pooler** → URI をコピー（`aws-1-ap-northeast-1.pooler.supabase.com:5432`、IPv4）。

```bash
export SUPABASE_DB_URL='postgresql://postgres.<YOUR_VALIARK_PROD_PROJECT_REF>:[PASSWORD]@aws-1-ap-northeast-1.pooler.supabase.com:5432/postgres'
./scripts/valiark-prod-supabase-setup.sh db
```

（`[PASSWORD]` は Database password。特殊文字は URL エンコード。）

#### F. `--skip-pooler` を使う場合

IPv6 対応ネットワーク（または Supabase の IPv4 add-on）があるときだけ。

#### E. それでもダメなとき

1. CLI を更新: `brew upgrade supabase` または [最新 CLI](https://supabase.com/docs/guides/cli/getting-started#updating-the-supabase-cli)
2. **Dashboard → SQL Editor** で `supabase/migrations/` を時系列で手動実行（最終手段）
3. [Connection refused トラブルシュート](https://supabase.com/docs/guides/troubleshooting/error-connection-refused-when-trying-to-connect-to-supabase-database-hwG0Dr)

### 1-4 初回16問・seed

| やる | やらない |
|------|----------|
| 運営アカウントで prod にログインし、アプリから Q1–16 を手動投稿（[supabase/README.md](../supabase/README.md)） | `npm run seed:dev` を prod に向けて実行 |

`seed:dev` は **valiark-dev の ref のみ**許可（誤爆防止）。prod で試す場合のみ `ALLOW_DEV_SEED_ON_PROJECT=<ref>` で明示。

---

## Phase 2 — Cloudflare Worker（prod）

`wrangler.toml` には **URL/anon を書かない**（`.env.prod` からデプロイ時に注入）。

### 0. Cloudflare にログイン（先に1回）

`secret:service-role:prod` / `deploy:prod` の前に **Wrangler が Cloudflare を認識**している必要がある。

**ターミナル（対話）:**

```bash
cd backend
npx wrangler login
```

ブラウザで Cloudflare アカウントを許可する。

**CI / 非対話** では [API Token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/) を作成し、少なくとも **Account → Cloudflare Workers → Edit** を付与して:

```bash
export CLOUDFLARE_API_TOKEN='<token>'
```

`Failed to fetch auth token` / `CLOUDFLARE_API_TOKEN` と出たら、上記が未設定。

---

1. ルート **`.env.prod`** に prod の `PANDA_TALK_SUPABASE_URL` / `PANDA_TALK_SUPABASE_ANON_KEY` があること。

2. prod の service role（1回）:

```bash
cd backend
npm run secret:service-role:prod
# または対話: npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY --env production
```

3. デプロイ（`.env.prod` を読む）:

```bash
cd backend
npm run deploy:prod
```

表示 URL（例: `https://panda-talk-backend-prod.<account>.workers.dev`）を **`.env.prod`** の `PANDA_TALK_API_BASE_URL` に書く。

**日常 dev:** ルート `.env` → `cd backend && npm run sync:dev-vars` → `backend/.dev.vars`。`npm run deploy` は `.env` から dev Worker へ。

**dev Worker**（`panda-talk-backend`）は引き続き valiark-dev のまま。日常開発は dev を壊さない。

---

## dev / prod の切り替え（Flutter）

| 目的 | コマンド | 向き先 |
|------|----------|--------|
| 日常開発 | `flutter run`（`.env` = dev） | valiark-dev |
| **prod が再現できているか確認** | `./scripts/flutter_run_prod.sh` | valiark-prod（`.env.prod` → `--dart-define`） |
| テスター配布 | `flutter build ipa` + **同じ dart-define**（下記 Phase 3） | valiark-prod |

- アプリは起動時に **`.env` だけ**読み込む（`lib/main.dart`）。**`.env.prod` は自動では読まない**（手元用の値メモ + スクリプトが define に変換）。
- `AppConfig` の優先順位: **`--dart-define` > `.env`**。だから `flutter_run_prod.sh` では `.env` が dev のままでも prod に繋がる。
- `flutter build ipa` を define なしで打っても **prod にはならない**（同梱 `.env` の内容 = だいたい dev）。

**注意（prod で `flutter run` するとき）:** prod DB にレコードが増える。運営用・検証用アカウント推奨。`npm run seed:dev` は prod 向けに使わない。

---

## Phase 3 — テスター用 Flutter ビルド

1. `.env.prod.example` → `.env.prod`（gitignore）にコピーし、prod の URL / anon / API URL を入れる。
2. TestFlight / 内部配布ビルドでは **dart-define で上書き**するか、CI で `.env.prod` を注入（[valiark_client_secrets_playbook.md](./valiark_client_secrets_playbook.md) §5）。

```bash
# 例（値は vault から）
flutter build ipa \
  --dart-define=PANDA_TALK_SUPABASE_URL=https://<prod-ref>.supabase.co \
  --dart-define=PANDA_TALK_SUPABASE_ANON_KEY=<prod-anon> \
  --dart-define=PANDA_TALK_API_BASE_URL=https://panda-talk-backend-prod.<account>.workers.dev \
  --dart-define=PANDA_TALK_AUTH_REDIRECT_URL=io.valiark.pandatalk://callback
```

3. iOS / Android の URL scheme が Redirect URL と一致していること。

---

## Phase 4 — 通し確認（テスター募集前）

**起動（TestFlight と同じ接続先で試す）:**

```bash
# .env.prod を用意済みであること
node scripts/check-prod-config.mjs
./scripts/flutter_run_prod.sh
```

シミュレータでも実機でも可。`npm run deploy:prod` 済みで、`.env.prod` の `PANDA_TALK_API_BASE_URL` が prod Worker を指していること。

自分のアカウントで **prod のみ**:

1. ゲストで診断（Q1–16 が prod にあること）
2. 登録（メール or LINE or Apple）
3. プロフィール設定
4. **質問を1件投稿** → Dashboard で `panda_questions.user_id` と投稿者プロフィールが一致
5. 別アカウントで回答
6. ログアウト → 再ログイン

OK ならテスター配布。**dev ビルド・dev URL は配らない。**

---

## Phase 5 — テスター運用

- 募集・TestFlight 招待
- 不具合報告チャンネル
- **dev へのテスター登録を禁止**（投稿者 ID が dev に残ると移行が必要になる）

---

## トラブルシュート

| 症状 | 確認 |
|------|------|
| LINE/Apple ログイン失敗 | prod に `db push` 済みか、Functions + secrets、Redirect URL |
| 質問は出るが投稿者がおかしい | API と Supabase が **同じ prod** を向いているか |
| `db push` で migration 不整合 | 空 prod なら stub 込み一括 push。既に手動 SQL した場合は Dashboard の migration 履歴 |
| seed を流した | prod では手動16問のみ。テスト用 Auth が混ざったら整理 |

---

## 設定の事前確認

prod の URL / ref を入れたあと:

```bash
node scripts/check-prod-config.mjs
```

（`wrangler.toml` production・`.env.prod`・`scripts/valiark-project-refs.env` が揃っているか）

---

## チェックリスト（印刷用）

- [ ] prod Project ref / キーを vault に保存
- [ ] Auth Redirect URL 登録
- [ ] `db push` 完了
- [ ] Edge Functions + secrets デプロイ
- [ ] 運営で Q1–16 投稿（prod）
- [ ] `wrangler.toml` production vars 更新
- [ ] `wrangler secret` + `deploy:prod`
- [ ] `.env.prod` 作成
- [ ] `./scripts/flutter_run_prod.sh` で通し確認
- [ ] `flutter build ipa` + dart-define で prod 固定ビルド
- [ ] TestFlight 配布
