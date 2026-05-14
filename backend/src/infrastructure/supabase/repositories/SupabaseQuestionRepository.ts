import type {
  UUID,
  AnsweredQuestion,
  HotQuestion,
  Question,
  QuestionStats,
  QuestionWithUser,
} from '../../../domain/entities/index'
import type { IQuestionRepository } from '../../../domain/repositories/IQuestionRepository'
import type { SupabaseRestClient } from '../SupabaseRestClient'
import {
  toHotQuestion,
  toQuestion,
  toQuestionWithUser,
  type HotQuestionRow,
  type QuestionRow,
  type QuestionWithUserRow,
} from './mappers'

type QuestionStatsRow = {
  question_id: string
  count_a: number
  count_b: number
}

type AnsweredQuestionRow = {
  choice: 'a' | 'b'
  panda_questions: QuestionWithUserRow | null
}

const QUESTION_SELECT =
  'id,user_id,text,option_a,option_b,category,created_at,panda_profiles(id,username,avatar_url)'

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)
}

export class SupabaseQuestionRepository implements IQuestionRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  async getFeed(userId: UUID, limit: number, cursor?: UUID): Promise<QuestionWithUser[]> {
    const query: Record<string, string | number> = {
      select: QUESTION_SELECT,
      order: 'created_at.asc,id.asc',
      limit: Math.max(limit * 3, limit),
    }

    if (cursor) {
      const cursorQuestion = await this.findQuestionRow(cursor)
      if (cursorQuestion) query.created_at = `gt.${cursorQuestion.created_at}`
    }

    const rows = await this.client.get<QuestionWithUserRow[]>('panda_questions', query)
    let questions = rows.map(toQuestionWithUser)

    if (isUuid(userId)) {
      const answeredRows = await this.client.get<Array<{ question_id: string }>>('panda_answers', {
        select: 'question_id',
        user_id: `eq.${userId}`,
      })
      const answeredIds = new Set(answeredRows.map((row) => row.question_id))
      questions = questions.filter((question) => !answeredIds.has(question.id))
    }

    return questions.slice(0, limit)
  }

  async getHotFeed(limit: number, cursor?: UUID): Promise<HotQuestion[]> {
    const rows = await this.client.get<HotQuestionRow[]>('panda_hot_questions', {
      select: 'id,user_id,username,avatar_url,text,option_a,option_b,category,created_at,like_count,comment_count',
      order: 'heat_score.desc,created_at.desc',
      limit: Math.max(limit * 3, limit),
    })

    let questions = rows.map((row) =>
      toHotQuestion({
        ...row,
        panda_profiles: {
          id: row.user_id,
          username: row.username ?? 'unknown',
          avatar_url: row.avatar_url ?? null,
        },
      })
    )

    if (cursor) {
      const index = questions.findIndex((question) => question.id === cursor)
      if (index !== -1) questions = questions.slice(index + 1)
    }

    return questions.slice(0, limit)
  }

  async getAnsweredHistory(
    userId: UUID,
    limit: number,
    cursor?: UUID
  ): Promise<AnsweredQuestion[]> {
    const query: Record<string, string | number> = {
      select: `choice,panda_questions(${QUESTION_SELECT})`,
      user_id: `eq.${userId}`,
      order: 'created_at.desc',
      limit,
    }

    if (cursor) {
      const cursorAnswerRows = await this.client.get<Array<{ created_at: string }>>('panda_answers', {
        select: 'created_at',
        question_id: `eq.${cursor}`,
        user_id: `eq.${userId}`,
        limit: 1,
      })
      const cursorAnswer = cursorAnswerRows[0]
      if (cursorAnswer) query.created_at = `lt.${cursorAnswer.created_at}`
    }

    const rows = await this.client.get<AnsweredQuestionRow[]>('panda_answers', query)
    return rows
      .map((row) => {
        if (!row.panda_questions) return null
        const question = toQuestionWithUser(row.panda_questions)
        return {
          ...question,
          myAnswer: row.choice === 'a' ? question.optionA : question.optionB,
        }
      })
      .filter((question): question is AnsweredQuestion => question !== null)
  }

  async findById(id: UUID): Promise<QuestionWithUser | null> {
    const rows = await this.client.get<QuestionWithUserRow[]>('panda_questions', {
      select: QUESTION_SELECT,
      id: `eq.${id}`,
      limit: 1,
    })
    return rows[0] ? toQuestionWithUser(rows[0]) : null
  }

  async getStats(questionId: UUID): Promise<QuestionStats> {
    const rows = await this.client.get<QuestionStatsRow[]>('panda_question_stats', {
      select: 'question_id,count_a,count_b',
      question_id: `eq.${questionId}`,
      limit: 1,
    })
    const stats = rows[0]
    return {
      questionId,
      countA: stats?.count_a ?? 0,
      countB: stats?.count_b ?? 0,
    }
  }

  async search(keyword: string, limit: number): Promise<QuestionWithUser[]> {
    const trimmedKeyword = keyword.trim()
    if (!trimmedKeyword) return []

    const rows = await this.client.get<QuestionWithUserRow[]>('panda_questions', {
      select: QUESTION_SELECT,
      or: `(text.ilike.*${trimmedKeyword}*,option_a.ilike.*${trimmedKeyword}*,option_b.ilike.*${trimmedKeyword}*)`,
      order: 'created_at.desc',
      limit,
    })
    return rows.map(toQuestionWithUser)
  }

  async create(data: Omit<Question, 'id' | 'createdAt'>): Promise<Question> {
    const rows = await this.client.insert<QuestionRow>('panda_questions', {
      user_id: data.userId,
      text: data.text,
      option_a: data.optionA,
      option_b: data.optionB,
      category: data.category,
    })
    if (!rows[0]) throw new Error('Question was not created')
    return toQuestion(rows[0])
  }

  async update(
    id: UUID,
    data: Partial<Pick<Question, 'text' | 'optionA' | 'optionB' | 'category'>>
  ): Promise<Question> {
    const body: Record<string, string | null> = {}
    if (data.text !== undefined) body.text = data.text
    if (data.optionA !== undefined) body.option_a = data.optionA
    if (data.optionB !== undefined) body.option_b = data.optionB
    if (data.category !== undefined) body.category = data.category

    const rows = await this.client.update<QuestionRow>('panda_questions', { id: `eq.${id}` }, body)
    if (!rows[0]) throw Object.assign(new Error('Question not found'), { code: 'NOT_FOUND' })
    return toQuestion(rows[0])
  }

  async delete(id: UUID): Promise<void> {
    await this.client.delete('panda_questions', { id: `eq.${id}` })
  }

  private async findQuestionRow(id: UUID): Promise<QuestionRow | null> {
    const rows = await this.client.get<QuestionRow[]>('panda_questions', {
      select: 'id,user_id,text,option_a,option_b,category,created_at',
      id: `eq.${id}`,
      limit: 1,
    })
    return rows[0] ?? null
  }
}
