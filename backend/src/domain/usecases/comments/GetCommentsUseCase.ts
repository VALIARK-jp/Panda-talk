import type { ICommentRepository } from '../../repositories/ICommentRepository'
import type { Comment, AnswerChoice } from '../../entities/index'

export class GetCommentsUseCase {
  constructor(private commentRepo: ICommentRepository) {}

  async execute(questionId: string, choice?: AnswerChoice): Promise<Comment[]> {
    return this.commentRepo.findByQuestion(questionId, choice)
  }
}
