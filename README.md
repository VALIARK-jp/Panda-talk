# パンダトーク（Panda Talk）

二択質問に答え続けることで価値観が可視化され、合致度で人とつながる SNS。  
**Web / iOS 公開済み:** https://valiark.jp/panda-talk

> 業務委託・受託案件（BtoB SaaS、動画SNS等）のコードは、契約上の権利・守秘義務の関係で公開できないため、GitHub の公開リポジトリは自社プロジェクトの一部のみです。

## 自分の役割

- **代表 / フルスタック開発** — ハッカソン優勝案から自社で 0→1 リリースまで一貫して担当
- **バックエンド設計・実装** — Hono + Cloudflare Workers 上の BFF、UseCase 層、Supabase 連携
- **認証** — Supabase Auth + Edge Functions（メール / LINE / Apple ネイティブフロー）
- **モバイル** — Flutter（iOS / Android）、App Store 提出・運用
- **インフラ** — Supabase（PostgreSQL / Auth / Storage）、Cloudflare Workers（dev / prod 分離）

## 技術スタック

| レイヤー | 技術 |
|---|---|
| クライアント | Flutter（iOS / Android / Web ビルド可） |
| API（BFF） | Hono + TypeScript / Cloudflare Workers |
| DB / Auth | Supabase（PostgreSQL + Auth + Storage） |
| プッシュ | Firebase Cloud Messaging |
| 認証連携 | LINE Login / Sign in with Apple（Edge Functions） |

## 設計のポイント

### 1. Supabase 直叩きではなく BFF を挟む

Flutter は Bearer JWT 付きで Cloudflare Workers（Hono）のみを呼び出す。合致度更新・プロフィール初期化・モデレーションなどのビジネスロジックは **UseCase 層** に集約し、Supabase は DB / Auth の基盤として利用する。将来のテスト追加や DB 差し替えに耐えるため、Presentation → UseCase → Domain ← Infrastructure の依存方向を守っている。

### 2. ネイティブ OAuth（LINE / Apple）のセッション確立

LINE / Apple は Edge Function でプロバイダ検証 → Admin API でユーザー upsert → `hashed_token` 経由でクライアントが `verifyOTP` しセッションを確立する。メール認証と異なる経路だが、ログイン後は同一の `auth.users` / `panda_profiles` フローに合流する。

### 3. dev / prod の環境分離

Supabase プロジェクト（valiark-dev / valiark-prod）と Cloudflare Worker（`panda-talk-backend` / `panda-talk-backend-prod`）を分離。Flutter は `--dart-define` で接続先を切り替え、秘密情報は `.env` / Wrangler secrets に閉じる。

## セットアップ

**アーキテクチャ参照用リポジトリ**として公開しています。全機能をローカルで動かすには Supabase プロジェクト・Cloudflare・LINE / Apple 開発者設定が必要です。

### 最小構成（Flutter + dev API）

```bash
cp .env.example .env
# PANDA_TALK_SUPABASE_URL / ANON_KEY / API_BASE_URL を設定

flutter pub get
flutter run
```

### バックエンド（ローカル）

```bash
cd backend
npm install
npm run sync:dev-vars   # ルート .env → backend/.dev.vars
npm run dev             # localhost:8787
```

### 詳細ドキュメント

| ドキュメント | 内容 |
|---|---|
| [docs/06_tech.md](docs/06_tech.md) | 技術構成・クリーンアーキテクチャ |
| [docs/13_auth_flow_spec.md](docs/13_auth_flow_spec.md) | 認証フロー設計仕様 |
| [docs/05_auth.md](docs/05_auth.md) | Supabase / Edge Functions 構築 |
| [docs/14_development_api_and_devices.md](docs/14_development_api_and_devices.md) | API 向き先・実機開発 |
| [docs/16_valiark_prod_panda_talk_setup.md](docs/16_valiark_prod_panda_talk_setup.md) | prod 環境セットアップ |

## ライセンス

Copyright © VALIARK LLC. All rights reserved.
