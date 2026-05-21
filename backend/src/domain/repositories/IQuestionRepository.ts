import type {
  UUID,
  Question,
  QuestionWithUser,
  HotQuestion,
  QuestionStats,
  AnsweredQuestion,
  FeedWindowQuestion,
} from '../entities/index'

export interface IQuestionRepository {
  getDiagnosis16(userId?: UUID): Promise<QuestionWithUser[]>
  getFeedWindow(
    userId: UUID,
    before: number,
    after: number,
    maxQuestionNumber?: number
  ): Promise<FeedWindowQuestion[]>
  getFeed(userId: UUID, limit: number, cursor?: UUID): Promise<QuestionWithUser[]>
  getHotFeed(limit: number, cursor?: UUID): Promise<HotQuestion[]>
  getAnsweredHistory(userId: UUID, limit: number, cursor?: UUID): Promise<AnsweredQuestion[]>
  findById(id: UUID): Promise<QuestionWithUser | null>
  getStats(questionId: UUID): Promise<QuestionStats>
  search(keyword: string, limit: number): Promise<QuestionWithUser[]>
  create(data: Omit<Question, 'id' | 'questionNumber' | 'createdAt'>): Promise<Question>
  update(
    id: UUID,
    data: Partial<Pick<Question, 'text' | 'optionA' | 'optionB' | 'category'>>
  ): Promise<Question>
  delete(id: UUID): Promise<void>
}
