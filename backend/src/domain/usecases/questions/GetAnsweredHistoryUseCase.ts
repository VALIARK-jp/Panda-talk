import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { AnsweredQuestion } from '../../entities/index'

export class GetAnsweredHistoryUseCase {
  constructor(private questionRepo: IQuestionRepository) {}

  async execute(userId: string, limit: number, cursor?: string): Promise<AnsweredQuestion[]> {
    return this.questionRepo.getAnsweredHistory(userId, limit, cursor)
  }
}
