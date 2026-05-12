import type { UUID, Answer } from '../entities/index'

export interface IAnswerRepository {
  findByUserAndQuestion(userId: UUID, questionId: UUID): Promise<Answer | null>
  findByQuestion(questionId: UUID): Promise<Answer[]>
  findByUser(userId: UUID, limit: number, cursor?: UUID): Promise<Answer[]>
  create(data: Omit<Answer, 'id' | 'createdAt'>): Promise<Answer>
}
