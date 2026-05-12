import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { Question } from '../../entities/index'

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
    return this.questionRepo.create({
      userId: input.userId,
      text: input.text,
      optionA: input.optionA,
      optionB: input.optionB,
      category: input.category ?? null,
    })
  }
}
