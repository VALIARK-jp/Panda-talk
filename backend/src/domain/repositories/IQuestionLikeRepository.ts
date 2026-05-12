import type { UUID, QuestionLike } from '../entities/index'

export interface IQuestionLikeRepository {
  find(userId: UUID, questionId: UUID): Promise<QuestionLike | null>
  create(userId: UUID, questionId: UUID): Promise<QuestionLike>
  delete(userId: UUID, questionId: UUID): Promise<void>
}
