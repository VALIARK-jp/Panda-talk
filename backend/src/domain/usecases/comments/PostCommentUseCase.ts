import type { ICommentRepository } from '../../repositories/ICommentRepository'
import type { Comment, AnswerChoice } from '../../entities/index'

interface PostCommentInput {
  questionId: string
  userId: string
  choice: AnswerChoice
  body: string
}

export class PostCommentUseCase {
  constructor(private commentRepo: ICommentRepository) {}

  async execute(input: PostCommentInput): Promise<Comment> {
    return this.commentRepo.create({
      questionId: input.questionId,
      userId: input.userId,
      choice: input.choice,
      body: input.body,
    })
  }
}
