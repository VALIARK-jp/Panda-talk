import type { UUID, Answer } from '../../../domain/entities/index'
import type { IAnswerRepository } from '../../../domain/repositories/IAnswerRepository'
import type { SupabaseRestClient } from '../SupabaseRestClient'
import { toAnswer, type AnswerRow } from './mappers'

export class SupabaseAnswerRepository implements IAnswerRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  async findByUserAndQuestion(userId: UUID, questionId: UUID): Promise<Answer | null> {
    const rows = await this.client.get<AnswerRow[]>('panda_answers', {
      select: 'id,user_id,question_id,choice,created_at',
      user_id: `eq.${userId}`,
      question_id: `eq.${questionId}`,
      limit: 1,
    })
    return rows[0] ? toAnswer(rows[0]) : null
  }

  async findByQuestion(questionId: UUID): Promise<Answer[]> {
    const rows = await this.client.get<AnswerRow[]>('panda_answers', {
      select: 'id,user_id,question_id,choice,created_at',
      question_id: `eq.${questionId}`,
    })
    return rows.map(toAnswer)
  }

  async findByUser(userId: UUID, limit: number, cursor?: UUID): Promise<Answer[]> {
    const query: Record<string, string | number> = {
      select: 'id,user_id,question_id,choice,created_at',
      user_id: `eq.${userId}`,
      order: 'created_at.desc,id.desc',
      limit,
    }

    if (cursor) {
      const cursorAnswer = await this.findById(cursor)
      if (cursorAnswer) query.created_at = `lt.${cursorAnswer.createdAt}`
    }

    const rows = await this.client.get<AnswerRow[]>('panda_answers', query)
    return rows.map(toAnswer)
  }

  async create(data: Omit<Answer, 'id' | 'createdAt'>): Promise<Answer> {
    const rows = await this.client.insert<AnswerRow>('panda_answers', {
      user_id: data.userId,
      question_id: data.questionId,
      choice: data.choice,
    })
    if (!rows[0]) throw new Error('Answer was not created')
    return toAnswer(rows[0])
  }

  private async findById(id: UUID): Promise<Answer | null> {
    const rows = await this.client.get<AnswerRow[]>('panda_answers', {
      select: 'id,user_id,question_id,choice,created_at',
      id: `eq.${id}`,
      limit: 1,
    })
    return rows[0] ? toAnswer(rows[0]) : null
  }
}
