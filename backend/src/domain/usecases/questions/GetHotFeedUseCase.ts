import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { HotQuestion } from '../../entities/index'

export class GetHotFeedUseCase {
  constructor(private questionRepo: IQuestionRepository) {}

  async execute(limit: number, cursor?: string): Promise<HotQuestion[]> {
    return this.questionRepo.getHotFeed(limit, cursor)
  }
}
