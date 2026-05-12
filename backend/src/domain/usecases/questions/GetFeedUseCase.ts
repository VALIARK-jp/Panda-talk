import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { QuestionWithUser } from '../../entities/index'

export class GetFeedUseCase {
  constructor(private questionRepo: IQuestionRepository) {}

  async execute(userId: string, limit: number, cursor?: string): Promise<QuestionWithUser[]> {
    return this.questionRepo.getFeed(userId, limit, cursor)
  }
}
