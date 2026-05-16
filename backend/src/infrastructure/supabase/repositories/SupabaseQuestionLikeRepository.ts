import type { UUID, QuestionLike } from '../../../domain/entities/index'
import type { IQuestionLikeRepository } from '../../../domain/repositories/IQuestionLikeRepository'
import { SupabaseRestClient } from '../SupabaseRestClient'

type LikeRow = {
  id: string
  user_id: string
  question_id: string
  created_at: string
}

export class SupabaseQuestionLikeRepository implements IQuestionLikeRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  private readonly resource = 'panda_question_likes'

  async find(userId: UUID, questionId: UUID): Promise<QuestionLike | null> {
    const rows = await this.client.get<LikeRow[]>(this.resource, {
      select: '*',
      user_id: `eq.${userId}`,
      question_id: `eq.${questionId}`,
      limit: 1,
    })
    return rows[0] ? mapLike(rows[0]) : null
  }

  async create(userId: UUID, questionId: UUID): Promise<QuestionLike> {
    const rows = await this.client.insert<LikeRow>(this.resource, {
      user_id: userId,
      question_id: questionId,
    })
    if (!rows[0]) throw new Error('Failed to create like')
    return mapLike(rows[0])
  }

  async delete(userId: UUID, questionId: UUID): Promise<void> {
    await this.client.delete(this.resource, {
      user_id: `eq.${userId}`,
      question_id: `eq.${questionId}`,
    })
  }
}

function mapLike(row: LikeRow): QuestionLike {
  return {
    id: row.id,
    userId: row.user_id,
    questionId: row.question_id,
    createdAt: row.created_at,
  }
}
