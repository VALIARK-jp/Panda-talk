import type { UUID, QuestionLike } from '../../domain/entities/index'
import type { IQuestionLikeRepository } from '../../domain/repositories/IQuestionLikeRepository'

const questionLikes: QuestionLike[] = []

export class MockQuestionLikeRepository implements IQuestionLikeRepository {
  async find(userId: UUID, questionId: UUID): Promise<QuestionLike | null> {
    return questionLikes.find((l) => l.userId === userId && l.questionId === questionId) ?? null
  }

  async create(userId: UUID, questionId: UUID): Promise<QuestionLike> {
    const like: QuestionLike = {
      id: crypto.randomUUID(),
      userId,
      questionId,
      createdAt: new Date().toISOString(),
    }
    questionLikes.push(like)
    return like
  }

  async delete(userId: UUID, questionId: UUID): Promise<void> {
    const idx = questionLikes.findIndex((l) => l.userId === userId && l.questionId === questionId)
    if (idx !== -1) questionLikes.splice(idx, 1)
  }
}
