import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { FeedWindowQuestion, UUID } from '../../entities/index'

export class GetFeedWindowUseCase {
  constructor(private readonly questionRepo: IQuestionRepository) {}

  execute(
    userId: UUID,
    before = 10,
    after = 10,
    maxQuestionNumber?: number
  ): Promise<FeedWindowQuestion[]> {
    return this.questionRepo.getFeedWindow(userId, before, after, maxQuestionNumber)
  }
}
