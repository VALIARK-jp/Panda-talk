import type { UUID, Comment, AnswerChoice } from '../entities/index'

export interface ICommentRepository {
  findByQuestion(
    questionId: UUID,
    choice?: AnswerChoice,
    viewerUserId?: UUID
  ): Promise<Comment[]>
  create(data: Omit<Comment, 'id' | 'likeCount' | 'createdAt'>): Promise<Comment>
  delete(id: UUID): Promise<void>
  findById(id: UUID): Promise<Comment | null>
}
