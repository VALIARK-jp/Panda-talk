# ドメイン定義

## Entity（エンティティ）

ビジネス上の「もの」を純粋なTypeScript型として定義する。
DBの都合・フレームワークの都合を一切含まない。

---

### 共通

```typescript
type UUID = string
type ISODateString = string
```

---

### User

```typescript
type User = {
  id: UUID                  // Supabase AuthのUIDと同一
  email: string | null      // Appleログインではnullの可能性あり
  username: string          // ユーザーが設定する一意のID（@username）
  name: string
  avatarUrl: string | null
  bio: string | null
  createdAt: ISODateString
}
```

---

### Question

```typescript
type Question = {
  id: UUID
  userId: UUID
  text: string
  optionA: string
  optionB: string
  category: string | null
  createdAt: ISODateString
}

// 統計（取得時に集計して付加する）
type QuestionStats = {
  questionId: UUID
  countA: number
  countB: number
}

// フィード表示用（投稿者情報付き）
type QuestionWithUser = Question & {
  poster: {
    id: UUID
    username: string
    avatarUrl: string | null
  }
}

// Hotタブ表示用（投稿者情報 + いいね+コメント数付き）
type HotQuestion = QuestionWithUser & {
  likeCount: number
  commentCount: number
}
```

---

### Answer

```typescript
type AnswerChoice = 'a' | 'b'

type Answer = {
  id: UUID
  userId: UUID
  questionId: UUID
  choice: AnswerChoice
  createdAt: ISODateString
}
```

---

### Friendship

```typescript
type FriendshipStatus = 'pending' | 'accepted'

type Friendship = {
  id: UUID
  userAId: UUID   // userAId < userBId で固定（DB側のCHECK制約と対応）
  userBId: UUID
  status: FriendshipStatus
  createdAt: ISODateString
}
```

---

### MatchScore

```typescript
type MatchScore = {
  id: UUID
  userAId: UUID
  userBId: UUID
  matchRate: number           // 0.0 ~ 1.0
  commonAnswerCount: number
  sameAnswerCount: number
  updatedAt: ISODateString
}

// マッチ画面表示用（displayScore付き）
type MatchResult = {
  user: User
  matchRate: number
  commonAnswerCount: number
  displayScore: number        // matchRate * (common / (common + 50))
}
```

---

### Comment

```typescript
type Comment = {
  id: UUID
  questionId: UUID
  userId: UUID               // 取得時は匿名表示・内部管理のみ使用
  choice: AnswerChoice       // どっち派のコメントか
  body: string
  likeCount: number          // 取得時に集計して付加
  createdAt: ISODateString
}
```

---

### QuestionLike

```typescript
type QuestionLike = {
  id: UUID
  userId: UUID
  questionId: UUID
  createdAt: ISODateString
}
```

---

### CommentLike

```typescript
type CommentLike = {
  id: UUID
  userId: UUID
  commentId: UUID
  createdAt: ISODateString
}
```

---

### Notification

```typescript
type NotificationType =
  | 'like'            // 自分の質問にいいね
  | 'comment'         // 自分の質問にコメント
  | 'friend_request'  // 友達申請
  | 'friend_accepted' // 友達申請承認
  | 'new_match'       // 高合致ユーザー出現
  | 'group_created'   // グループ生成

type Notification = {
  id: UUID
  userId: UUID        // 受信者
  actorId: UUID | null  // 通知を起こしたユーザー（nullはシステム通知）
  type: NotificationType
  targetId: UUID | null  // 対象レコードのID
  isRead: boolean
  createdAt: ISODateString
}
```

---

### Group

```typescript
type GroupType = 'high_match' | 'middle_match' | 'low_match'

type Group = {
  id: UUID
  name: string
  type: GroupType
  createdAt: ISODateString
}

type GroupMember = {
  id: UUID
  groupId: UUID
  userId: UUID
  createdAt: ISODateString
}
```

---

### Message（グループチャット）

```typescript
type Message = {
  id: UUID
  groupId: UUID
  userId: UUID
  body: string
  createdAt: ISODateString
}
```

---

### DirectMessage

```typescript
type DirectMessage = {
  id: UUID
  senderId: UUID
  receiverId: UUID
  body: string
  createdAt: ISODateString
}
```

---

### PushToken

```typescript
type Platform = 'ios' | 'android'

type PushToken = {
  id: UUID
  userId: UUID
  token: string
  platform: Platform
  updatedAt: ISODateString
}
```

---

## Repository Interface（リポジトリインターフェース）

UseCaseが「何の操作を必要とするか」だけを定義する。
実装（Supabase）には依存しない。

---

### IUserRepository

```typescript
interface IUserRepository {
  findById(id: UUID): Promise<User | null>
  findByIds(ids: UUID[]): Promise<User[]>
  findByUsername(username: string): Promise<User | null>              // プロフィール閲覧（完全一致）
  searchByUsername(prefix: string, limit: number): Promise<User[]>   // 友達検索（前方一致）
  isUsernameTaken(username: string): Promise<boolean>                 // 登録時の重複チェック
  create(data: Omit<User, 'id' | 'createdAt'>): Promise<User>
  update(id: UUID, data: Partial<Pick<User, 'name' | 'avatarUrl' | 'bio'>>): Promise<User>
  delete(id: UUID): Promise<void>
}
```

---

### IQuestionRepository

```typescript
interface IQuestionRepository {
  // 診断タブ: 未回答・投稿順（投稿者情報付き）
  getFeed(userId: UUID, limit: number, cursor?: UUID): Promise<QuestionWithUser[]>
  // Hotタブ: いいね+コメント数順（投稿者情報付き）
  getHotFeed(limit: number, cursor?: UUID): Promise<HotQuestion[]>
  findById(id: UUID): Promise<QuestionWithUser | null>
  getStats(questionId: UUID): Promise<QuestionStats>
  search(keyword: string, limit: number): Promise<QuestionWithUser[]>
  create(data: Omit<Question, 'id' | 'createdAt'>): Promise<Question>
  update(id: UUID, data: Partial<Pick<Question, 'text' | 'optionA' | 'optionB' | 'category'>>): Promise<Question>
  delete(id: UUID): Promise<void>
}
```

---

### IAnswerRepository

```typescript
interface IAnswerRepository {
  findByUserAndQuestion(userId: UUID, questionId: UUID): Promise<Answer | null>
  findByQuestion(questionId: UUID): Promise<Answer[]>
  findByUser(userId: UUID, limit: number, cursor?: UUID): Promise<Answer[]>
  create(data: Omit<Answer, 'id' | 'createdAt'>): Promise<Answer>
}
```

---

### IFriendshipRepository

```typescript
interface IFriendshipRepository {
  // 申請を送る（UseCase側でuserAId < userBIdに並び替え済みで渡す）
  sendRequest(userAId: UUID, userBId: UUID): Promise<Friendship>
  // 承認する
  accept(userAId: UUID, userBId: UUID): Promise<Friendship>
  // 断る・解除する
  delete(userAId: UUID, userBId: UUID): Promise<void>
  // 友達一覧（accepted のみ）
  findFriends(userId: UUID): Promise<Friendship[]>
  // 受信した申請一覧（pending かつ自分がuserB側）
  findPendingReceived(userId: UUID): Promise<Friendship[]>
  // 2ユーザー間の関係を取得（並び替えはRepository側で吸収）
  findBetween(userAId: UUID, userBId: UUID): Promise<Friendship | null>
}
```

---

### IMatchRepository

```typescript
interface IMatchRepository {
  // 合致度一覧（表示用スコアでソート済み）
  getSimilar(userId: UUID, limit: number, cursor?: UUID): Promise<MatchResult[]>
  getOpposite(userId: UUID, limit: number, cursor?: UUID): Promise<MatchResult[]>
  getMiddle(userId: UUID, limit: number, cursor?: UUID): Promise<MatchResult[]>
  // 特定ペアのスコアを取得
  findBetween(userAId: UUID, userBId: UUID): Promise<MatchScore | null>
  // インクリメンタル更新
  upsert(userAId: UUID, userBId: UUID, isSame: boolean): Promise<void>
}
```

---

### ICommentRepository

```typescript
interface ICommentRepository {
  findByQuestion(questionId: UUID, choice?: AnswerChoice): Promise<Comment[]>
  create(data: Omit<Comment, 'id' | 'likeCount' | 'createdAt'>): Promise<Comment>
  delete(id: UUID): Promise<void>
}
```

---

### IQuestionLikeRepository

```typescript
interface IQuestionLikeRepository {
  find(userId: UUID, questionId: UUID): Promise<QuestionLike | null>
  create(userId: UUID, questionId: UUID): Promise<QuestionLike>
  delete(userId: UUID, questionId: UUID): Promise<void>
}
```

---

### ICommentLikeRepository

```typescript
interface ICommentLikeRepository {
  find(userId: UUID, commentId: UUID): Promise<CommentLike | null>
  create(userId: UUID, commentId: UUID): Promise<CommentLike>
  delete(userId: UUID, commentId: UUID): Promise<void>
}
```

---

### INotificationRepository

```typescript
interface INotificationRepository {
  findByUser(userId: UUID, limit: number, cursor?: UUID): Promise<Notification[]>
  countUnread(userId: UUID): Promise<number>
  markAllAsRead(userId: UUID): Promise<void>
  markAsRead(notificationId: UUID): Promise<void>
  create(data: Omit<Notification, 'id' | 'isRead' | 'createdAt'>): Promise<Notification>
}
```

---

### IGroupRepository

```typescript
interface IGroupRepository {
  findByUser(userId: UUID): Promise<Group[]>
  findById(id: UUID): Promise<Group | null>
  findMembers(groupId: UUID): Promise<GroupMember[]>
  create(data: Omit<Group, 'id' | 'createdAt'>): Promise<Group>
  addMember(groupId: UUID, userId: UUID): Promise<GroupMember>
  removeMember(groupId: UUID, userId: UUID): Promise<void>
}
```

---

### IMessageRepository

```typescript
interface IMessageRepository {
  findByGroup(groupId: UUID, limit: number, cursor?: UUID): Promise<Message[]>
  create(data: Omit<Message, 'id' | 'createdAt'>): Promise<Message>
}
```

---

### IDirectMessageRepository

```typescript
interface IDirectMessageRepository {
  findBetween(userAId: UUID, userBId: UUID, limit: number, cursor?: UUID): Promise<DirectMessage[]>
  // DM一覧（直近メッセージ付き）
  findThreads(userId: UUID): Promise<{ partner: User; lastMessage: DirectMessage }[]>
  create(data: Omit<DirectMessage, 'id' | 'createdAt'>): Promise<DirectMessage>
}
```

---

### IPushTokenRepository

```typescript
interface IPushTokenRepository {
  findByUser(userId: UUID): Promise<PushToken[]>
  upsert(userId: UUID, token: string, platform: Platform): Promise<void>
  delete(userId: UUID, token: string): Promise<void>
}
```
