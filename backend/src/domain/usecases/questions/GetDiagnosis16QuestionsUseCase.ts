import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { QuestionWithUser, UUID } from '../../entities/index'

export class GetDiagnosis16QuestionsUseCase {
  constructor(private readonly questionRepo: IQuestionRepository) {}

  async execute(userId?: UUID): Promise<QuestionWithUser[]> {
    return this.questionRepo.getDiagnosis16(userId)
  }
}
