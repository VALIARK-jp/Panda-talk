import type {
  Answer,
  AnswerChoice,
  HotQuestion,
  MatchResult,
  MatchScore,
  Question,
  QuestionWithUser,
  User,
} from '../../../domain/entities/index'

export type UserRow = {
  id: string
  email: string | null
  username: string
  name: string
  avatar_url: string | null
  bio: string | null
  created_at: string
}

export type QuestionRow = {
  id: string
  question_number: number
  user_id: string
  text: string
  option_a: string
  option_b: string
  category: string | null
  created_at: string
}

export type QuestionWithUserRow = QuestionRow & {
  panda_profiles?: Pick<UserRow, 'id' | 'username' | 'avatar_url'> | null
}

export type HotQuestionRow = QuestionWithUserRow & {
  username?: string
  avatar_url?: string | null
  like_count: number
  comment_count: number
}

export type AnswerRow = {
  id: string
  user_id: string
  question_id: string
  choice: AnswerChoice
  created_at: string
}

export type MatchScoreRow = {
  id: string
  user_a_id: string
  user_b_id: string
  match_rate: number
  common_answer_count: number
  same_answer_count: number
  updated_at: string
}

export function toUser(row: UserRow): User {
  return {
    id: row.id,
    email: row.email,
    username: row.username,
    name: row.name,
    avatarUrl: row.avatar_url,
    bio: row.bio,
    createdAt: row.created_at,
  }
}

export function toQuestion(row: QuestionRow): Question {
  return {
    id: row.id,
    questionNumber: row.question_number,
    userId: row.user_id,
    text: row.text,
    optionA: row.option_a,
    optionB: row.option_b,
    category: row.category,
    createdAt: row.created_at,
  }
}

export function toQuestionWithUser(row: QuestionWithUserRow): QuestionWithUser {
  const profile = row.panda_profiles
  return {
    ...toQuestion(row),
    poster: {
      id: profile?.id ?? row.user_id,
      username: profile?.username ?? 'unknown',
      avatarUrl: profile?.avatar_url ?? null,
    },
  }
}

export function toHotQuestion(row: HotQuestionRow): HotQuestion {
  return {
    ...toQuestionWithUser(row),
    likeCount: row.like_count,
    commentCount: row.comment_count,
  }
}

export function toAnswer(row: AnswerRow): Answer {
  return {
    id: row.id,
    userId: row.user_id,
    questionId: row.question_id,
    choice: row.choice,
    createdAt: row.created_at,
  }
}

export function toMatchScore(row: MatchScoreRow): MatchScore {
  return {
    id: row.id,
    userAId: row.user_a_id,
    userBId: row.user_b_id,
    matchRate: row.match_rate,
    commonAnswerCount: row.common_answer_count,
    sameAnswerCount: row.same_answer_count,
    updatedAt: row.updated_at,
  }
}

export function toMatchResult(
  score: MatchScoreRow,
  user: UserRow
): MatchResult {
  return {
    user: toUser(user),
    matchRate: score.match_rate,
    commonAnswerCount: score.common_answer_count,
    displayScore: score.match_rate * (score.common_answer_count / (score.common_answer_count + 50)),
  }
}
