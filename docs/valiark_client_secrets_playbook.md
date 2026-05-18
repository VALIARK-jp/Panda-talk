# Valiark クライアント秘密・オンボーディング運用ガイド

**目的:** Panda Talk、Who eats、その他 Valiark のクライアント（主にモバイル）で **「何を誰に渡すか」「リポジトリに何を書いてよいか」** を揃え、オンボーディングとインシデントを減らす。  
**位置づけ:** 各リポジトリの実装（`flutter_dotenv` の有無、dart-define 専用か、など）は **アプリごとに異なってよい**。この文書は **ルールと分類** を共有するためのものである。

他アプリの UI やディレクトリ構成をそのまま踏襲する必要はない。認証画面のボタン配置など **見た目の参考** と、ここに書く **秘密の扱い** は切り離して考える。

---

## 1. 秘密の分類（共通言語）

| 区分 | 例 | クライアントに渡す | Git にコミット |
|------|-----|-------------------|----------------|
| **公開してよいクライアント用** | Supabase **anon** key、公開 API の base URL、アプリの redirect URL（スキーム含む） | メール / 1Password / オンボーディング手順で **可** | **原則不可**（`.env.example` には **キー名のみ**、値は空） |
| **ソースに固定（valiark-dev 共通）** | LINE **チャンネル ID** `2010102462`（Login SDK 用・pedal_share とは別） | リポジトリにコミット可 | `lib/features/auth/valiark_auth_config.dart` |
| **Supabase Edge Secrets のみ** | `LINE_CHANNEL_ID`（Edge 検証用・上記と同値）、`SUPABASE_SERVICE_ROLE_KEY`、LINE **チャンネルシークレット**（必要なら）、Apple サーバー鍵（将来 JWT 検証を厳格化する場合） | **Dashboard / `supabase secrets set` のみ** | **絶対不可** |
| **サーバー・CI のみ** | Webhook 署名、決済秘密鍵など | **クライアント開発者に渡さない** | **絶対不可** |
| **個人・端末ローカル** | 上記「公開してよい」値のコピーを開発者が **`.env`**（gitignore）に置く | 各自のマシンのみ | `.gitignore` で除外 |

**anon と service_role:** anon は Row Level Security の前提で「クライアントに埋め込まれる」設計だが、**リポジトリの履歴に残さない**運用を推奨する。service_role は RLS をバイパスするため **Flutter・モバイル・フロントのビルド引数・`.env` に一切入れない**。

---

## 2. ジョイン時にメール等で渡してよいもの（チェックリスト）

オンボーディング担当が新メンバーに渡す想定:

- [ ] 開発用 Supabase プロジェクトの **URL**
- [ ] 同プロジェクトの **anon** key（本番用は別チケット・別 vault で）
- [ ] （参考）LINE チャンネル ID はリポジトリの `valiark_auth_config.dart` に固定。Edge には `supabase secrets set LINE_CHANNEL_ID=...` で **同じ値**
- [ ] **Panda Talk API の dev base URL**（`https://….workers.dev` 等。baselink の `VITE_API_BASE_URL=https://…-dev.azurewebsites.net` と同じ。実機向けに localhost は配らない）
- [ ] 認証リダイレクトに使う **許可済み URL**（Panda Talk: `io.valiark.pandatalk://callback` / `PANDA_TALK_AUTH_REDIRECT_URL`）と、ダッシュボードで許可する手順へのリンク（[05_auth.md](05_auth.md)）
- [ ] Google ログインを使う環境では **Supabase の Google プロバイダー** をオンにしたこと（Client Secret は **ダッシュボードのみ**、クライアントに埋めない）

**渡さない:** service_role、LINE channel secret、Apple 秘密鍵、本番のみの鍵、他社・他プロジェクトの秘密。  
**`.env` に書かせない:** `PANDA_TALK_LINE_CHANNEL_*`、`PANDA_TALK_APPLE_*`（pedal_share に無いものは Panda Talk でも不要）。

---

## 3. リポジトリに書いてよいもの

- **キー名の列挙**（`README` や `.env*.example`）: 可
- **anon の実値をソースの `defaultValue` に置く習慣:** 避ける。どうしてもチーム方針で「開発用のみソースに置く」場合は **公開前提の anon のみ** に限定し、本番キーは禁止。移行時は env / dart-define に寄せ、デフォルトは空にする。

---

## 4. ローカル開発での置き方（実装は各アプリ任せ）

次のいずれか（または併用）でよい。重要なのは **git に乗らないこと** と **上の分類を守ること**。

- **`flutter_dotenv` + ルートの `.env`**（このリポはこの方式。テンプレは [`.env.example`](../.env.example)）
- **シェル環境変数** + `--dart-define`（本番ビルドや CI で `.env` を空にして上書きする用途でも可）
- **IDE の入力プロンプト**（値をディスクに保存しない）

他リポジトリで `flutter_dotenv` を使わなくてもよい。このプレイブックは **ルール** の共有が主目的。

---

## 5. CI / 本番ビルド

- **service_role** や LINE **secret** は CI の **encrypted secrets** や Supabase の **Function secrets** にのみ置く。
- クライアント向けビルド（TestFlight、Play 内部テスト等）には **anon とチャンネル ID** まで。ビルドログに秘密が出ないようマスクする。

---

## 6. 他リポジトリへの展開

- Who eats、Panda Talk など **同じ内容のファイルをコピー**してもよい。あるいは社内 Notion / Drive に **単一の正本** を置き、各 README からリンクする。
- アプリ固有のプレフィックス（例: `PANDA_TALK_*`）はそのままでよい。**分類ルール（この文書の表）** を共有することが主目的。

---

## 7. 関連ドキュメント（このリポジトリ）

- 認証の技術手順（Supabase、LINE、Apple、ダッシュボード）: [05_auth.md](05_auth.md)
