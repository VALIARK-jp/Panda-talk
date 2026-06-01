import type {
  UUID,
  AnsweredQuestion,
  FeedWindowQuestion,
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

type QuestionEngagementRow = {
  id: string
  like_count: number
  comment_count: number
}

function percentAFromCounts(countA: number, countB: number): number {
  const total = countA + countB
  if (total === 0) return 50
  return Math.round((countA / total) * 100)
}

type AnsweredQuestionRow = {
  choice: 'a' | 'b'
  panda_questions: QuestionWithUserRow | null
}

const QUESTION_SELECT =
  'id,question_number,user_id,text,option_a,option_b,category,created_at,panda_profiles(id,username,name,avatar_url)'

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)
}

export class SupabaseQuestionRepository implements IQuestionRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  async getDiagnosis16(userId?: UUID): Promise<QuestionWithUser[]> {
    const rows = await this.client.get<QuestionWithUserRow[]>('panda_questions', {
      select: QUESTION_SELECT,
      and: '(question_number.gte.1,question_number.lte.16)',
      order: 'question_number.asc',
      limit: 16,
    })
    const questions = rows
      .map(toQuestionWithUser)
      .filter((question) => question.questionNumber >= 1 && question.questionNumber <= 16)

    const withEngagement = await this.attachEngagementCounts(questions)
    if (!userId || !isUuid(userId)) return withEngagement

    const answerRows = await this.client.get<
      Array<{ question_id: string; choice: 'a' | 'b' }>
    >('panda_answers', {
      select: 'question_id,choice',
      user_id: `eq.${userId}`,
      limit: 32,
    })
    const choiceByQuestionId = new Map(
      answerRows.map((row) => [row.question_id, row.choice])
    )

    return withEngagement.map((question) => {
      const choice = choiceByQuestionId.get(question.id)
      if (!choice) return question
      return {
        ...question,
        myAnswer: choice === 'a' ? question.optionA : question.optionB,
      }
    })
  }

  async getFeed(userId: UUID, limit: number, cursor?: UUID): Promise<QuestionWithUser[]> {
    let answeredIds: string[] = []
    if (isUuid(userId)) {
      const answeredRows = await this.client.get<Array<{ question_id: string }>>(
        'panda_answers',
        {
          select: 'question_id',
          user_id: `eq.${userId}`,
          limit: 10000,
        }
      )
      answeredIds = answeredRows.map((row) => row.question_id)
    }

    const query: Record<string, string | number> = {
      select: QUESTION_SELECT,
      order: 'question_number.asc,id.asc',
      limit,
    }

    if (answeredIds.length > 0) {
      query.id = `not.in.(${answeredIds.join(',')})`
    }

    if (cursor) {
      const cursorQuestion = await this.findQuestionRow(cursor)
      if (cursorQuestion) query.created_at = `gt.${cursorQuestion.created_at}`
    }

    const rows = await this.client.get<QuestionWithUserRow[]>('panda_questions', query)
    return this.attachEngagementCounts(rows.map(toQuestionWithUser))
  }

  async getFeedWindow(
    userId: UUID,
    before: number,
    after: number,
    maxQuestionNumber?: number
  ): Promise<FeedWindowQuestion[]> {
    const answeredByQuestionId = new Map<string, 'a' | 'b'>()
    if (isUuid(userId)) {
      const answeredRows = await this.client.get<
        Array<{ question_id: string; choice: 'a' | 'b' }>
      >('panda_answers', {
        select: 'question_id,choice',
        user_id: `eq.${userId}`,
        limit: 10000,
      })
      for (const row of answeredRows) {
        answeredByQuestionId.set(row.question_id, row.choice)
      }
    }

    const attachAnswers = <T extends QuestionWithUser>(questions: T[]): T[] =>
      questions.map((question) => {
        const choice = answeredByQuestionId.get(question.id)
        if (!choice) return question
        return {
          ...question,
          myAnswer: choice === 'a' ? question.optionA : question.optionB,
        }
      })

    // 16type 診断: Q1–max をすべて返す（表示の切り詰めはクライアントの clipFeedProgressView）。
    // ログイン後のゲスト回答アップロードで全問の question_id が必要なため、フロンティアで切らない。
    if (maxQuestionNumber != null && maxQuestionNumber > 0) {
      const rows = await this.client.get<QuestionWithUserRow[]>('panda_questions', {
        select: QUESTION_SELECT,
        and: `(question_number.gte.1,question_number.lte.${maxQuestionNumber})`,
        order: 'question_number.asc,id.asc',
        limit: maxQuestionNumber + 5,
      })
      return attachAnswers(
        await this.attachEngagementCounts(rows.map(toQuestionWithUser))
      )
    }

    const answeredIds = [...answeredByQuestionId.keys()]
    const frontierQuery: Record<string, string | number> = {
      select: 'question_number',
      order: 'question_number.asc',
      limit: 1,
    }
    if (answeredIds.length > 0) {
      frontierQuery.id = `not.in.(${answeredIds.join(',')})`
    }

    const frontierRows = await this.client.get<Array<{ question_number: number }>>(
      'panda_questions',
      frontierQuery
    )

    let frontier: number
    if (frontierRows.length > 0) {
      frontier = frontierRows[0].question_number
    } else if (answeredIds.length > 0) {
      const answeredQuestionRows = await this.client.get<
        Array<{ question_number: number }>
      >('panda_questions', {
        select: 'question_number',
        id: `in.(${answeredIds.join(',')})`,
        order: 'question_number.desc',
        limit: 1,
      })
      frontier = answeredQuestionRows[0]?.question_number ?? 1
    } else {
      return []
    }
    const minNum = Math.max(1, frontier - before)
    const maxNum = frontier + after

    const rows = await this.client.get<QuestionWithUserRow[]>('panda_questions', {
      select: QUESTION_SELECT,
      and: `(question_number.gte.${minNum},question_number.lte.${maxNum})`,
      order: 'question_number.asc,id.asc',
      limit: before + after + 5,
    })

    return attachAnswers(await this.attachEngagementCounts(rows.map(toQuestionWithUser)))
  }

  async getFeedWindowAround(
    userId: UUID,
    before: number,
    after: number,
    target: { questionId?: UUID; questionNumber?: number }
  ): Promise<FeedWindowQuestion[]> {
    let targetNumber = target.questionNumber
    if ((targetNumber == null || targetNumber < 1) && target.questionId) {
      const row = await this.findQuestionRow(target.questionId)
      targetNumber = row?.question_number
    }
    if (targetNumber == null || targetNumber < 1) {
      return this.getFeedWindow(userId, before, after)
    }

    const answeredByQuestionId = new Map<string, 'a' | 'b'>()
    if (isUuid(userId)) {
      const answeredRows = await this.client.get<
        Array<{ question_id: string; choice: 'a' | 'b' }>
      >('panda_answers', {
        select: 'question_id,choice',
        user_id: `eq.${userId}`,
        limit: 10000,
      })
      for (const row of answeredRows) {
        answeredByQuestionId.set(row.question_id, row.choice)
      }
    }

    const attachAnswers = <T extends QuestionWithUser>(questions: T[]): T[] =>
      questions.map((question) => {
        const choice = answeredByQuestionId.get(question.id)
        if (!choice) return question
        return {
          ...question,
          myAnswer: choice === 'a' ? question.optionA : question.optionB,
        }
      })

    const minNum = Math.max(1, targetNumber - before)
    const maxNum = targetNumber + after

    const rows = await this.client.get<QuestionWithUserRow[]>('panda_questions', {
      select: QUESTION_SELECT,
      and: `(question_number.gte.${minNum},question_number.lte.${maxNum})`,
      order: 'question_number.asc,id.asc',
      limit: before + after + 5,
    })

    return attachAnswers(await this.attachEngagementCounts(rows.map(toQuestionWithUser)))
  }

  async getHotFeed(limit: number, cursor?: UUID): Promise<HotQuestion[]> {
    const rows = await this.client.get<HotQuestionRow[]>('panda_hot_questions', {
      select: 'id,question_number,user_id,username,avatar_url,text,option_a,option_b,category,created_at,like_count,comment_count',
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
    const answered = rows
      .map((row) => {
        if (!row.panda_questions) return null
        const question = toQuestionWithUser(row.panda_questions)
        return {
          ...question,
          myAnswer: row.choice === 'a' ? question.optionA : question.optionB,
        }
      })
      .filter((question): question is AnsweredQuestion => question !== null)

    return this.attachEngagementCounts(answered)
  }

  async findById(id: UUID): Promise<QuestionWithUser | null> {
    const rows = await this.client.get<QuestionWithUserRow[]>('panda_questions', {
      select: QUESTION_SELECT,
      id: `eq.${id}`,
      limit: 1,
    })
    return rows[0] ? toQuestionWithUser(rows[0]) : null
  }

  async findByNumber(questionNumber: number): Promise<QuestionWithUser | null> {
    const rows = await this.client.get<QuestionWithUserRow[]>('panda_questions', {
      select: QUESTION_SELECT,
      question_number: `eq.${questionNumber}`,
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
    return this.attachEngagementCounts(rows.map(toQuestionWithUser))
  }

  async create(data: Omit<Question, 'id' | 'questionNumber' | 'createdAt'>): Promise<Question> {
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

  private async attachEngagementCounts<T extends QuestionWithUser>(
    questions: T[]
  ): Promise<T[]> {
    if (questions.length === 0) return questions

    const ids = questions.map((q) => q.id)
    const [engagementRows, statsRows] = await Promise.all([
      this.client.get<QuestionEngagementRow[]>('panda_hot_questions', {
        select: 'id,like_count,comment_count',
        id: `in.(${ids.join(',')})`,
      }),
      this.client.get<QuestionStatsRow[]>('panda_question_stats', {
        select: 'question_id,count_a,count_b',
        question_id: `in.(${ids.join(',')})`,
      }),
    ])
    const engagementById = new Map(
      engagementRows.map((row) => [
        row.id,
        { likeCount: row.like_count ?? 0, commentCount: row.comment_count ?? 0 },
      ])
    )
    const statsById = new Map(
      statsRows.map((row) => [
        row.question_id,
        {
          countA: row.count_a ?? 0,
          countB: row.count_b ?? 0,
          percentA: percentAFromCounts(row.count_a ?? 0, row.count_b ?? 0),
        },
      ])
    )

    return questions.map((question) => {
      const counts = engagementById.get(question.id)
      const stats = statsById.get(question.id)
      return {
        ...question,
        likeCount: counts?.likeCount ?? 0,
        commentCount: counts?.commentCount ?? 0,
        countA: stats?.countA ?? 0,
        countB: stats?.countB ?? 0,
        percentA: stats?.percentA ?? 50,
      }
    })
  }

  private async findQuestionRow(id: UUID): Promise<QuestionRow | null> {
    const rows = await this.client.get<QuestionRow[]>('panda_questions', {
      select: 'id,question_number,user_id,text,option_a,option_b,category,created_at',
      id: `eq.${id}`,
      limit: 1,
    })
    return rows[0] ?? null
  }
}
