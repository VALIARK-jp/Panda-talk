import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { Question } from '../../entities/index'

interface EditQuestionInput {
  id: string
  userId: string
  text?: string
  optionA?: string
  optionB?: string
  category?: string | null
}

export class EditQuestionUseCase {
  constructor(private questionRepo: IQuestionRepository) {}

  async execute(input: EditQuestionInput): Promise<Question> {
    const question = await this.questionRepo.findById(input.id)
    if (!question) {
      throw Object.assign(new Error('Question not found'), { code: 'NOT_FOUND' })
    }
    if (question.userId !== input.userId) {
      throw Object.assign(new Error('Forbidden'), { code: 'FORBIDDEN' })
    }
    return this.questionRepo.update(input.id, {
      text: input.text,
      optionA: input.optionA,
      optionB: input.optionB,
      category: input.category,
    })
  }
}
