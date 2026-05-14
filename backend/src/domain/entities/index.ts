export type UUID = string
export type ISODateString = string

export type User = {
  id: UUID
  email: string | null
  username: string
  name: string
  avatarUrl: string | null
  bio: string | null
  createdAt: ISODateString
  // Statistics and scores
  answerCount?: number
  postCount?: number
  friendCount?: number
  oddballScore?: number
  tags?: string[]
}

export type AnswerChoice = 'a' | 'b'

export type Question = {
  id: UUID
  userId: UUID
  text: string
  optionA: string
  optionB: string
  category: string | null
  createdAt: ISODateString
}

export type QuestionStats = {
  questionId: UUID
  countA: number
  countB: number
}

export type QuestionWithUser = Question & {
  poster: {
    id: UUID
    username: string
    avatarUrl: string | null
  }
}

export type HotQuestion = QuestionWithUser & {
  likeCount: number
  commentCount: number
}

export type AnsweredQuestion = QuestionWithUser & {
  myAnswer: string
}

export type Answer = {
  id: UUID
  userId: UUID
  questionId: UUID
  choice: AnswerChoice
  createdAt: ISODateString
}

export type FriendshipStatus = 'pending' | 'accepted'

export type Friendship = {
  id: UUID
  userAId: UUID
  userBId: UUID
  status: FriendshipStatus
  createdAt: ISODateString
}

export type MatchScore = {
  id: UUID
  userAId: UUID
  userBId: UUID
  matchRate: number
  commonAnswerCount: number
  sameAnswerCount: number
  updatedAt: ISODateString
}

export type MatchResult = {
  user: User
  matchRate: number
  commonAnswerCount: number
  displayScore: number
}

export type Comment = {
  id: UUID
  questionId: UUID
  userId: UUID
  choice: AnswerChoice
  body: string
  likeCount: number
  createdAt: ISODateString
}

export type QuestionLike = {
  id: UUID
  userId: UUID
  questionId: UUID
  createdAt: ISODateString
}

export type CommentLike = {
  id: UUID
  userId: UUID
  commentId: UUID
  createdAt: ISODateString
}

export type NotificationType =
  | 'like'
  | 'comment'
  | 'friend_request'
  | 'friend_accepted'
  | 'new_match'
  | 'group_created'

export type Notification = {
  id: UUID
  userId: UUID
  actorId: UUID | null
  type: NotificationType
  targetId: UUID | null
  isRead: boolean
  createdAt: ISODateString
}

export type GroupType = 'high_match' | 'middle_match' | 'low_match'

export type Group = {
  id: UUID
  name: string
  type: GroupType
  createdAt: ISODateString
}

export type GroupMember = {
  id: UUID
  groupId: UUID
  userId: UUID
  createdAt: ISODateString
}

export type Message = {
  id: UUID
  groupId: UUID
  userId: UUID
  body: string
  createdAt: ISODateString
}

export type DirectMessage = {
  id: UUID
  senderId: UUID
  receiverId: UUID
  body: string
  createdAt: ISODateString
}

export type Platform = 'ios' | 'android'

export type PushToken = {
  id: UUID
  userId: UUID
  token: string
  platform: Platform
  updatedAt: ISODateString
}
