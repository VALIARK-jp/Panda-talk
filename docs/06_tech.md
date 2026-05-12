# 技術構成

## スタック概要

| レイヤー | 技術 | 理由 |
|---|---|---|
| モバイル | Flutter | iOS/Android同時開発・アニメーション・MVP向き |
| Web | Next.js | SEO・新規流入・ゲスト体験の入口（フェーズ1.5） |
| バックエンド | Hono + TypeScript | 軽量・型安全・Cloudflare Workers対応 |
| 実行環境 | Cloudflare Workers | エッジ実行・無料枠が大きい・Hono親和性高い |
| DB | PostgreSQL（Supabase） | リレーション強い・合致度計算向き |
| 認証 | Supabase Auth | DBと同一基盤・メール/Apple対応 |
| インフラ | Supabase | Auth・DB・Storage・Realtimeを一元管理 |
| プッシュ通知 | Firebase Cloud Messaging（FCM） | iOS/Android共通・APNs対応 |

---

## アーキテクチャ方針

**バックエンドはHono + Cloudflare Workersを採用。Supabase直叩きはしない。**

理由:
- クリーンアーキテクチャを学びながら実装する
- 合致度更新・グループ生成などの複雑なビジネスロジックをUseCase層に閉じ込める
- 将来的なDB移行・テスト追加に耐えられる設計にする

```
Flutter / Next.js
    ↓ HTTP（Bearer JWT）
Hono API（Cloudflare Workers）
    ↓ Supabase JS Client
Supabase（PostgreSQL + Auth）
```

SupabaseはDBとAuthの基盤としてのみ使う。ビジネスロジックはHono側のUseCase層で書く。

---

## クリーンアーキテクチャ 4層構成

```
┌─────────────────────────────────┐
│  Presentation層                 │  Honoルート・ミドルウェア
│  （routes / middleware）        │  リクエスト受信・レスポンス返却のみ
├─────────────────────────────────┤
│  UseCase層                      │  ビジネスロジック
│  （usecases/）                  │  例: AnswerQuestionUseCase
├─────────────────────────────────┤
│  Domain層                       │  Entity型定義 + Repository interface
│  （entities / repositories/）  │  他の層に依存しない・純粋なTS型
├─────────────────────────────────┤
│  Infrastructure層               │  SupabaseによるRepository実装
│  （infrastructure/supabase/）  │  DBアクセスはここだけ
└─────────────────────────────────┘
```

**依存の向き:** Presentation → UseCase → Domain ← Infrastructure

Domain層だけが誰にも依存しない。InfrastructureはDomainのinterfaceを実装する。

---

## バックエンド ディレクトリ構成

```
backend/
  src/
    domain/
      entities/               # 純粋な型定義
        user.ts
        question.ts
        answer.ts
        match.ts
        comment.ts
        notification.ts
        group.ts
      repositories/           # interfaceのみ（実装なし）
        IUserRepository.ts
        IQuestionRepository.ts
        IAnswerRepository.ts
        IMatchRepository.ts
        ICommentRepository.ts
        INotificationRepository.ts
        IGroupRepository.ts
      usecases/
        questions/
          GetFeedUseCase.ts
          GetHotFeedUseCase.ts
          PostQuestionUseCase.ts
        answers/
          AnswerQuestionUseCase.ts   # 回答保存 + match_score更新
        matches/
          GetMatchesUseCase.ts
        users/
          MigrateGuestDataUseCase.ts
        comments/
          PostCommentUseCase.ts
        likes/
          ToggleQuestionLikeUseCase.ts
          ToggleCommentLikeUseCase.ts
        notifications/
          GetNotificationsUseCase.ts
          MarkAsReadUseCase.ts
        groups/
          GetGroupsUseCase.ts
          GenerateGroupsUseCase.ts   # 月次バッチ・新規登録時
    infrastructure/
      supabase/
        client.ts                    # Supabaseクライアント初期化
        repositories/                # IRepository実装
          SupabaseUserRepository.ts
          SupabaseQuestionRepository.ts
          SupabaseAnswerRepository.ts
          SupabaseMatchRepository.ts
          SupabaseCommentRepository.ts
          SupabaseNotificationRepository.ts
          SupabaseGroupRepository.ts
    presentation/
      routes/                        # Honoルート（薄く保つ・ロジックはUseCase）
        questions.ts
        answers.ts
        matches.ts
        users.ts
        comments.ts
        likes.ts
        notifications.ts
        groups.ts
      middleware/
        auth.ts                      # Supabase JWTトークン検証
    index.ts                         # Honoアプリ起動・ルート登録
  wrangler.toml                      # Cloudflare Workers設定
  package.json
  tsconfig.json
```

---

## Cloudflare Workers について

Cloudflare Workersはサーバーレス実行環境。Honoアプリをデプロイする場所。

```
ローカル開発: wrangler dev（ローカルでWorkers環境をエミュレート）
本番デプロイ: wrangler deploy → Cloudflareのエッジに自動配置
```

**メリット:**
- 無料枠: 1日10万リクエストまで無料
- コールドスタートなし（Workerは常時起動）
- 世界中のエッジに自動分散

---

## フロントエンド（Flutter）

状態管理は **Riverpod** を採用。フロントにDomain層は持たず、APIレスポンス（JSON）をそのまま扱う。

```
lib/
  core/
    design_tokens.dart
    router.dart              # GoRouter

  infrastructure/
    mock/                    # ダミーデータ実装（開発中）
      mock_question_repository.dart
      mock_answer_repository.dart
      mock_match_repository.dart
      mock_comment_repository.dart
      mock_notification_repository.dart
      mock_group_repository.dart
      mock_message_repository.dart
    api/                     # Hono APIを叩く実装（本番）
      api_question_repository.dart
      api_answer_repository.dart
      ...
    providers/
      repositories.dart      # モック/API切り替えを1箇所で管理

  presentation/
    screens/
      home/                  # 診断フィード
      match/                 # 合致度ランキング
      talk/                  # チャット
      post/                  # 質問投稿
      profile/               # プロフィール
      onboarding_screen.dart
      main_app.dart
    widgets/                 # 共通コンポーネント
    providers/               # 画面ごとのRiverpod Provider

  main.dart
```

**モック/API切り替え:**
```dart
// infrastructure/providers/repositories.dart
final questionRepositoryProvider = Provider((ref) {
  return MockQuestionRepository(); // → ApiQuestionRepository() に1行変えるだけ
});
```

---

## 認証フロー

```
1. Supabase Auth（メール+パスワード / Apple）でJWT取得
2. Flutter → Hono APIにBearer {token} で送信
3. HonoのauthMiddlewareがSupabase Auth.getUser()で検証
4. usersテーブルと紐付け（初回ログインはユーザー作成）
```

**登録方法:**
| プロバイダー | 方式 |
|---|---|
| メール | メールアドレス + パスワード |
| Apple | Sign in with Apple |
| LINE | フェーズ1.5以降にカスタムOAuthで追加 |

**登録フロー:**
```
① 認証（メール+PW / Apple）
② Supabase JWT取得
③ ユーザーネーム（ユニーク）を設定
④ POST /users でusersテーブルにレコード作成
⑤ 完了
```

---

## 環境変数

```env
# Cloudflare Workers（wrangler.toml or Cloudflare Dashboard）
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
FIREBASE_PROJECT_ID=      # FCM送信用（認証とは別）
```
