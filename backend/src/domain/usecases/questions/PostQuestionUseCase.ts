import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { Question } from '../../entities/index'
import { validateQuestionText } from './validation'

interface PostQuestionInput {
  userId: string
  text: string
  optionA: string
  optionB: string
  category?: string | null
}

export class PostQuestionUseCase {
  constructor(private questionRepo: IQuestionRepository) {}

  async execute(input: PostQuestionInput): Promise<Question> {
    const text = validateQuestionText(input.text)

    return this.questionRepo.create({
      userId: input.userId,
      text,
      optionA: input.optionA,
      optionB: input.optionB,
      category: input.category ?? null,
    })
  }
}
