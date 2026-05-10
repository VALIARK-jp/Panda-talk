# 技術構成

## スタック概要

| レイヤー | 技術 | 理由 |
|---|---|---|
| モバイル | Flutter | iOS/Android同時開発・アニメーション・MVP向き |
| Web | Next.js | SEO・新規流入・ゲスト体験の入口 |
| バックエンド | Hono + TypeScript | 軽量・API開発高速・型安全 |
| DB | PostgreSQL（Supabase） | リレーション強い・合致度計算向き |
| 認証 | Supabase Auth | DBと同一基盤・Google/Appleログイン対応 |
| インフラ | Supabase + Cloudflare | Auth・DB・Storageを一元管理 |

## クライアント共通API

FlutterもNext.jsも同一のHono APIを叩く。DBは共通のSupabase。

```
Flutter  ──┐
            ├──→ Hono API ──→ Supabase (PostgreSQL)
Next.js  ──┘
```

## API認証設計

| エンドポイント | 認証 | 理由 |
|---|---|---|
| GET /questions | 不要 | 全員が閲覧可能 |
| GET /questions/:id/stats | 不要 | 統計は未登録でも見せる |
| POST /answers | 必要 | DB書き込みは登録後のみ |
| GET /matches | 必要 | 登録ユーザーのみ |
| POST /users/migrate | 必要 | ゲストデータのDB移行 |

## ゲストモードのデータフロー

```
未登録ユーザー
  ↓ 質問に回答
  ↓ ローカルストレージに保存（Flutter: SharedPreferences / Web: localStorage）
  ↓ 統計APIから各質問の回答比率を取得
  ↓ クライアントで異端児スコアを計算・表示
  ↓ 登録ボタンタップ
  ↓ Supabase Authで登録
  ↓ POST /users/migrate でローカルデータをDBに一括送信
  ↓ 以降は通常ユーザーとして機能解放
```

---

## フロントエンド（Flutter）

```
lib/
  screens/
    home/         # 二択フィード
    match/        # 合致度ランキング
    group/        # コミュニティ
    profile/      # プロフィール
    auth/         # ログイン
  widgets/        # 共通コンポーネント
  models/         # データモデル
  services/       # API通信
  theme/          # カラー・スタイル定義
```

---

## バックエンド（Hono + TypeScript）

```
src/
  routes/
    auth.ts
    questions.ts
    answers.ts
    matches.ts
    groups.ts
    messages.ts
    direct_messages.ts
    comments.ts
  middleware/
    auth.ts
  db/
    schema.ts
    migrations/
  services/
    matchCalculator.ts   # インクリメンタル合致度更新
    groupGenerator.ts    # 3人グループ自動生成
```

---

## 認証フロー

1. Supabase Auth（Google/Apple）でトークン取得
2. バックエンドでトークン検証
3. usersテーブルと紐付け（初回はユーザー作成）

---

## 環境変数

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```
