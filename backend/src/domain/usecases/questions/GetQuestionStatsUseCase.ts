import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { QuestionStats } from '../../entities/index'

export class GetQuestionStatsUseCase {
  constructor(private questionRepo: IQuestionRepository) {}

  async execute(questionId: string): Promise<QuestionStats> {
    return this.questionRepo.getStats(questionId)
  }
}
