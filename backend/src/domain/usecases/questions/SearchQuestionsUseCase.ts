import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { QuestionWithUser } from '../../entities/index'

export class SearchQuestionsUseCase {
  constructor(private questionRepo: IQuestionRepository) {}

  async execute(keyword: string, limit: number): Promise<QuestionWithUser[]> {
    return this.questionRepo.search(keyword, limit)
  }
}
