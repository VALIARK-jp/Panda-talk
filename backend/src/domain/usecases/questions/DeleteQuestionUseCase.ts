import type { IQuestionRepository } from '../../repositories/IQuestionRepository'

export class DeleteQuestionUseCase {
  constructor(private questionRepo: IQuestionRepository) {}

  async execute(id: string, userId: string): Promise<void> {
    const question = await this.questionRepo.findById(id)
    if (!question) {
      throw Object.assign(new Error('Question not found'), { code: 'NOT_FOUND' })
    }
    if (question.userId !== userId) {
      throw Object.assign(new Error('Forbidden'), { code: 'FORBIDDEN' })
    }
    await this.questionRepo.delete(id)
  }
}
