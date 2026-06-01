import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { QuestionWithUser } from '../../entities/index'

/**
 * 共有URL `/q/:number` から呼ばれる、questionNumber 単発取得ユースケース。
 */
export class GetQuestionByNumberUseCase {
  constructor(private questionRepo: IQuestionRepository) {}

  async execute(questionNumber: number): Promise<QuestionWithUser | null> {
    return this.questionRepo.findByNumber(questionNumber)
  }
}
