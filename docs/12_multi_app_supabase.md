## Valiark: 1 Supabase（valiark-dev）に複数アプリを載せる運用

### 共有するもの（全アプリ共通）

- **Supabase Project URL**: `https://rothadmykmuxncagbwqd.supabase.co`
- **anon key**: `valiark-dev` の `anon`（各クライアントの env に同じ値を入れる）
- **Auth（auth.users）**: 1プロジェクトなので共通（アプリ別はプロフィール表で分ける）
- **メール / マジックリンク用リダイレクト URI**: valiark-dev の Dashboard に **1つだけ**登録（例: `io.valiark.auth://callback`）。各アプリの Android / iOS は **同じカスタム URL スキーム**を宣言してメール内リンクを受け取る。

### Auth 方針: 1人1ユーザー（`auth.users` は横断で共有）

**目的**: 同じ人が Panda Talk / Who eats など**別アプリ**から入っても、**OAuth 経路では原則同じ `auth.users` の1行**に収まるようにする（重複アカウントを作らない）。

- **LINE**
  - **共通の LINE Login チャンネル**を使う（各アプリの `LINE_CHANNEL_ID` / Flutter の `PANDA_TALK_LINE_CHANNEL_ID` 等は**同じ値**）。
  - そのチャンネルに、**各アプリの iOS / Android パッケージ**をチャネル設定で登録する。
  - **Edge Function** `line-auth-native` は valiark-dev 上に**1系統**デプロイし、全アプリが同じ URL を呼ぶ。**`line_user_id` → 擬似メール（例: `…@line.local`）→ `get_user_by_email` で引く**というロジックは、他アプリ用にコピーする場合も**同一**にする（別形式にすると同じ人で `auth` が二重になる）。
- **Apple**
  - 同じ **Apple Developer Team** まわりで、ネイティブ Sign in with Apple の **`sub` がアプリ間で一貫する**構成に寄せる（または既存の `apple-auth-native` と**同一のユーザー解決ルール**を共有する）。
- **メール＋パスワード**
  - メールはプロジェクト全体で一意。別アプリですでに登録済みのメールで「新規登録」すると衝突するため、**ログインへ誘導**する（Panda Talk クライアント側で対応済み）。
- **アプリ固有データ**
  - ログイン後は `panda_profiles` / `whoeats_profiles` など**アプリ別プロフィール表**で `id = auth.users.id` を1行ずつ用意する（`EnsureUserProfile` 相当）。

### 分けるもの（アプリごと）

- **プロフィール表**: `panda_profiles`, `linka_profiles`, `whoeats_profiles`, `terravera_profiles`（`id = auth.users.id`）
- **ドメイン表**: `panda_*`, `linka_*`, `whoeats_*`, `terravera_*`
- **RLS / policy**: 直接アクセスを許可する場合はアプリごとに設計（このリポジトリは server から service role を使う前提）
- **Edge Functions**: プロジェクトは共通。**OAuth 用（`line-auth-native` / `apple-auth-native`）は上記どおり原則共有デプロイ**し、関数名・シークレット・ユーザー解決ルールを揃える

### 絶対に共有しない（クライアントに入れない）

- **service role key**: backend / Edge Functions のみ。Flutter 等クライアントには入れない。

### 各リポジトリ（アプリ）側のやることチェックリスト

- **env**:
  - `SUPABASE_URL=https://rothadmykmuxncagbwqd.supabase.co`
  - `SUPABASE_ANON_KEY=<valiark-dev の anon>`
  - （backend があるなら）`SUPABASE_SERVICE_ROLE_KEY` を secret 管理に入れる
- **LINE / Apple（1人1 auth を守る）**:
  - LINE Login は **Valiark 共通チャンネル ID** を全アプリで使う（アプリごとに別チャンネルを切らない）
  - 各アプリから **`line-auth-native` / `apple-auth-native` の同じ Functions URL** を呼ぶ
  - Functions のシークレットに **`LINE_CHANNEL_ID`（共通値）**、`SUPABASE_SERVICE_ROLE_KEY` を設定
- **DB**:
  - 新しいアプリは `linka_*` / `whoeats_*` / `terravera_*` の接頭辞で migration を追加
  - `auth.users` を直接アプリ固有情報で汚さず、プロフィール表に寄せる

### Supabase CLI（DB / Functions 共通）

```sh
supabase login
supabase link --project-ref rothadmykmuxncagbwqd
supabase db push
supabase functions deploy <function-name>
```

