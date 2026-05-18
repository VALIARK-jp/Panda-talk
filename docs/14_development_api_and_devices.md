# ローカル開発・実機・API の向き先（設計方針）

新メンバー向け。**「なぜ実機だけ API が繋がらないのか」「いつ deploy / ngrok が要るのか」** をここにまとめる。認証の詳細は [05_auth.md](./05_auth.md)、技術スタックは [06_tech.md](./06_tech.md)。

---

## 1. このプロジェクトは「2つのホスト」を見る

| 用途 | 向き先（`.env`） | 実体 |
|------|------------------|------|
| **認証**（メール / LINE / Apple / Google） | `PANDA_TALK_SUPABASE_URL` | Supabase Auth（valiark-dev） |
| **アプリ API**（マッチ・質問・友達・設定など） | `PANDA_TALK_API_BASE_URL` | Cloudflare Worker（`backend/` = Hono BFF） |

認証だけクラウド・API だけ `localhost` のように **混在させない**（テンプレの初期値がそうなっていたため混乱しやすい）。

```
【全体像】

  Flutter
    ├─ https://….supabase.co        … 認証・（一部）プロフィール救済
    └─ https://….workers.dev または localhost:8787
              └─ Worker (BFF) ──service_role──► Supabase DB
```

**「全部 Supabase だけ」のプロジェクト**（DB + RLS + Edge Functions のみ）では、アプリの向き先が **常に `https://….supabase.co` 1本** なので、実機でも `localhost` を考えなくてよい。  
**panda_talk** は [06_tech.md](./06_tech.md) の方針どおり **BFF（Worker）を挟む** ため、**API 用の第2の向き先** が発生する。

---

## 2. 開発中の向き先（メンバー全員共通の運用）

### ふつうのコーディング（シミュレータ）

| 項目 | 値 |
|------|-----|
| 端末 | iOS シミュレータ（Mac 上） |
| `PANDA_TALK_API_BASE_URL` | `http://localhost:8787` |
| Worker | Mac で `cd backend && npm run dev:db`（または `npm run dev`） |
| deploy / ngrok | **不要** |

**開発中は localhost で正しい。** Docker は不要（ローカル Supabase `supabase start` を使わない限り）。

### 実機が必要なとき（位置情報・カメラ・実デバイス挙動など）

| 項目 | 値 |
|------|-----|
| 端末 | 実機 iPhone / Android |
| `PANDA_TALK_API_BASE_URL` | **`https://panda-talk-backend.valiark.workers.dev`**（チーム dev デプロイ URL） |
| Worker（Mac） | 起動しなくてよい（API はクラウド） |
| deploy | **API を変えた日だけ** 再 deploy。毎コミット必須ではない |

**スマホの IP を `.env` に書く運用はしない**（baselink 等のクラウド dev API と同じ考え方）。

### 実機 × いま書いたばかりの Worker API をすぐ試す

| 方法 | いつ |
|------|------|
| **`npm run deploy`**（`backend/`） | チーム共有・dev URL を更新したいとき |
| **ngrok**（`ngrok http 8787` + ローカル `dev:db`） | 個人でサッと試すだけのとき |

どちらも **「ローカル専用の 8787 を、実機から見える URL に出す」** ための手段。毎日どちらかが必須という意味ではない。

---

## 3. 初回セットアップ（API dev URL）

Worker が未デプロイの場合（`wrangler deployments list` で *Worker does not exist*）:

```bash
cd backend
npx wrangler login
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY   # Supabase Dashboard → API → service_role
npm run deploy
```

表示された URL（例: `https://panda-talk-backend.valiark.workers.dev`）をルート `.env` に書く:

```env
PANDA_TALK_API_BASE_URL=https://panda-talk-backend.valiark.workers.dev
```

`workers.dev` のサブドメイン（例: `valiark`）は **Cloudflare アカウントで1回** 登録する。dev / prod の切り分けは **Worker 名・Supabase プロジェクト** で行い、サブドメインを2つ取る必要は通常ない。

---

## 4. 例外: プロフィールだけ Supabase 直（localhost 時）

`PANDA_TALK_API_BASE_URL` が `localhost` のとき、実機では API に届かない。  
その救済として **プロフィール取得・作成だけ** `panda_profiles` を Supabase から直接読む（`SupabaseProfileRepository`）。

- マッチ・質問などは **引き続き API 経由**
- RLS: `supabase/migrations/20260518100000_panda_profiles_rls_self.sql` をリモートに `db push` 済みであること

**方針上は BFF 経由が本線**（[06_tech.md](./06_tech.md)）。実機の通常開発では **deploy 済み HTTPS** を使えばプロフィールも API 一本になる。

---

## 5. よくある誤解

| 誤解 | 正しい理解 |
|------|------------|
| Docker を開いていないから繋がない | いいえ。リモート Supabase + 任意で Worker。Docker は `supabase start` 用 |
| 実機では常に LAN IP を `.env` に書く | しない。dev の **HTTPS URL**（deploy 済み） |
| API を足すたび deploy 必須 | シミュレータ + localhost で開発。実機・共有時だけ deploy / ngrok |
| pedal の LINE チャンネル ID と同じ | valiark-dev 共通は **`2010102462`**（`lib/features/auth/valiark_auth_config.dart`） |

---

## 6. 関連ドキュメント

- [.env.example](../.env.example) — キー名のテンプレ
- [valiark_client_secrets_playbook.md](./valiark_client_secrets_playbook.md) — 何を配布するか
- [12_multi_app_supabase.md](./12_multi_app_supabase.md) — valiark-dev 共有
- [backend/package.json](../backend/package.json) — `dev` / `dev:db` / `deploy` スクリプト
