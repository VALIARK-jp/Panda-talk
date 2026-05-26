import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { FeedWindowQuestion, UUID } from '../../entities/index'

export class GetFeedWindowAroundUseCase {
  constructor(private readonly questionRepo: IQuestionRepository) {}

  execute(
    userId: UUID,
    before = 16,
    after = 16,
    target: {
      questionId?: UUID
      questionNumber?: number
      currentQuestionNumber?: number
    }
  ): Promise<FeedWindowQuestion[]> {
    const center = target.questionNumber ?? target.currentQuestionNumber
    return this.questionRepo.getFeedWindowAround(userId, before, after, {
      questionId: target.questionId,
      questionNumber: center,
    })
  }
}
