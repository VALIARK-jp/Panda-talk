# API設計・アーキテクチャ

## アーキテクチャ方針

クリーンアーキテクチャに従い、依存の向きを外 → 内に統一する。

```
Presentation（Honoルート）
    ↓ DTOで受け渡し
UseCase（ビジネスロジック）
    ↓ Repository interfaceに依存
Domain（Entity + IRepository）
    ↑ 実装を注入
Infrastructure（Supabase実装）
```

**依存ルール:**
- Domain層は他の層に依存しない
- UseCase層はDomain層のinterfaceにのみ依存する
- Infrastructure層はDomain層のinterfaceを実装する
- Presentation層はUseCaseを呼ぶだけ

---

## ディレクトリ構成

```
src/
  domain/
    entities/               # 型定義（純粋なオブジェクト）
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
  usecases/               # ビジネスロジック
      questions/
        GetFeedUseCase.ts        # 診断タブ: 未回答・投稿順
        GetHotFeedUseCase.ts     # Hotタブ: いいね+コメント数順
        PostQuestionUseCase.ts
      answers/
        AnswerQuestionUseCase.ts  # 回答保存 + match_score更新
      matches/
        GetMatchesUseCase.ts      # 合致度一覧（similar/opposite/middle）
      users/
        MigrateGuestDataUseCase.ts  # ゲスト→登録時のデータ移行
        GetProfileUseCase.ts
      comments/
        GetCommentsUseCase.ts
        PostCommentUseCase.ts
      likes/
        ToggleQuestionLikeUseCase.ts
        ToggleCommentLikeUseCase.ts
      notifications/
        GetNotificationsUseCase.ts
        MarkAsReadUseCase.ts
      groups/
        GetGroupsUseCase.ts

  infrastructure/
    supabase/
      client.ts               # Supabase clientの初期化・シングルトン
      repositories/           # IRepository実装
        SupabaseUserRepository.ts
        SupabaseQuestionRepository.ts
        SupabaseAnswerRepository.ts
        SupabaseMatchRepository.ts
        SupabaseCommentRepository.ts
        SupabaseNotificationRepository.ts
        SupabaseGroupRepository.ts

  presentation/
    routes/                   # Honoルート（薄く保つ・ロジックはUseCaseへ）
      questions.ts
      answers.ts
      matches.ts
      users.ts
      comments.ts
      likes.ts
      notifications.ts
      groups.ts
    middleware/
      auth.ts                 # JWTトークン検証（Supabase Auth）

  index.ts                    # Honoアプリ起動・ルート登録
```

---

## エンティティ定義例

```typescript
// domain/entities/question.ts
export type Question = {
  id: string
  userId: string
  text: string
  optionA: string
  optionB: string
  category: string | null
  createdAt: Date
}

// domain/entities/answer.ts
export type AnswerChoice = 'a' | 'b'

export type Answer = {
  userId: string
  questionId: string
  choice: AnswerChoice
  createdAt: Date
}
```

---

## Repository Interface例

```typescript
// domain/repositories/IQuestionRepository.ts
export interface IQuestionRepository {
  getFeed(userId: string, limit: number, cursor?: string): Promise<Question[]>
  getHotFeed(limit: number, cursor?: string): Promise<Question[]>
  findById(id: string): Promise<Question | null>
  create(question: Omit<Question, 'id' | 'createdAt'>): Promise<Question>
  getStats(questionId: string): Promise<{ countA: number; countB: number }>
}
```

---

## APIエンドポイント一覧

### 認証不要

| メソッド | パス | 説明 |
|---|---|---|
| GET | /questions | 診断フィード（未回答・投稿順） |
| GET | /questions/hot | Hotフィード（いいね+コメント数順） |
| GET | /questions/:id/stats | 回答比率取得 |
| GET | /questions/:id/comments | コメント一覧 |

### 認証必要（Bearer JWT）

| メソッド | パス | 説明 |
|---|---|---|
| POST | /questions | 質問投稿 |
| PATCH | /questions/:id | 質問を編集する（投稿者本人のみ） |
| DELETE | /questions/:id | 質問を削除する（投稿者本人のみ・連鎖削除） |
| POST | /answers | 回答送信（match_score更新を内包） |
| POST | /users/migrate | ゲストデータ一括移行 |
| GET | /users/me | 自分のプロフィール |
| GET | /users/:id | 他ユーザーのプロフィール |
| GET | /users/search?q=:prefix&limit=20 | usernameの前方一致でユーザーを検索する |
| GET | /matches | 合致度一覧 |
| POST | /friendships/:userId | 友達申請を送る |
| PATCH | /friendships/:userId/accept | 友達申請を承認する |
| DELETE | /friendships/:userId | 友達申請を断る・友達を解除する |
| GET | /friendships | 友達一覧を取得する |
| POST | /questions/:id/comments | コメント投稿 |
| DELETE | /comments/:id | コメントを削除する（投稿者本人のみ・連鎖削除） |
| POST | /questions/:id/likes | 質問いいね |
| DELETE | /questions/:id/likes | 質問いいね解除 |
| POST | /comments/:id/likes | コメントいいね |
| DELETE | /comments/:id/likes | コメントいいね解除 |
| GET | /notifications | お知らせ一覧 |
| PATCH | /notifications/read | 一括既読 |
| GET | /groups | 自分のグループ一覧 |
| GET | /direct_messages/:userId | DM一覧 |
| POST | /direct_messages | DM送信 |

---

## リクエスト/レスポンス例

### POST /answers
```json
// Request
{
  "questionId": "uuid",
  "choice": "a"
}

// Response 200
{
  "answer": {
    "questionId": "uuid",
    "choice": "a",
    "createdAt": "2026-05-10T00:00:00Z"
  },
  "stats": {
    "countA": 632,
    "countB": 381
  }
}
```

### GET /matches
```json
// Query: ?type=similar&limit=20&cursor=uuid

// Response 200
{
  "users": [
    {
      "id": "uuid",
      "name": "こうたろう",
      "avatarUrl": "...",
      "matchRate": 0.92,
      "commonAnswerCount": 128,
      "displayScore": 0.87
    }
  ],
  "nextCursor": "uuid"
}
```

### GET /questions（診断フィード）
```json
// Query: ?limit=10&cursor=uuid

// Response 200
{
  "questions": [
    {
      "id": "uuid",
      "text": "朝型？夜型？",
      "optionA": "朝型",
      "optionB": "夜型",
      "category": "生活",
      "number": 1256,
      "createdAt": "2026-01-01T00:00:00Z"
    }
  ],
  "nextCursor": "uuid"
}
```

---

## ページネーション方針

カーソルベース（cursor-based）を採用。オフセット方式は投稿が増えたとき位置ズレが起きる。

```
初回: GET /questions?limit=10
次頁: GET /questions?limit=10&cursor=<最後のレコードのid>
```

内部実装:
```sql
WHERE created_at < (SELECT created_at FROM questions WHERE id = :cursor)
ORDER BY created_at ASC
LIMIT :limit
```

---

## 認証ミドルウェア

Supabase Auth のJWTを検証し、usersテーブルのidをコンテキストにセットする。

```typescript
// presentation/middleware/auth.ts
import { createMiddleware } from 'hono/factory'
import { createClient } from '@supabase/supabase-js'

export const authMiddleware = createMiddleware(async (c, next) => {
  const token = c.req.header('Authorization')?.replace('Bearer ', '')
  if (!token) return c.json({ error: 'Unauthorized' }, 401)

  const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_ANON_KEY!
  )
  const { data: { user }, error } = await supabase.auth.getUser(token)
  if (error || !user) return c.json({ error: 'Unauthorized' }, 401)

  c.set('userId', user.id)
  await next()
})
```

---

## エラーレスポンス形式

```json
{
  "error": "NOT_FOUND",
  "message": "Question not found"
}
```

| コード | HTTPステータス |
|---|---|
| UNAUTHORIZED | 401 |
| FORBIDDEN | 403 |
| NOT_FOUND | 404 |
| CONFLICT | 409 |
| INTERNAL_ERROR | 500 |
