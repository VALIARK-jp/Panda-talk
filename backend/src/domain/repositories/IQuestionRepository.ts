import type { UUID, Question, QuestionWithUser, HotQuestion, QuestionStats } from '../entities/index'

export interface IQuestionRepository {
  getFeed(userId: UUID, limit: number, cursor?: UUID): Promise<QuestionWithUser[]>
  getHotFeed(limit: number, cursor?: UUID): Promise<HotQuestion[]>
  findById(id: UUID): Promise<QuestionWithUser | null>
  getStats(questionId: UUID): Promise<QuestionStats>
  search(keyword: string, limit: number): Promise<QuestionWithUser[]>
  create(data: Omit<Question, 'id' | 'createdAt'>): Promise<Question>
  update(
    id: UUID,
    data: Partial<Pick<Question, 'text' | 'optionA' | 'optionB' | 'category'>>
  ): Promise<Question>
  delete(id: UUID): Promise<void>
}
