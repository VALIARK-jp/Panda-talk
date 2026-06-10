import type { ICommentRepository } from '../../repositories/ICommentRepository'
import type { INotificationRepository } from '../../repositories/INotificationRepository'
import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { Comment, AnswerChoice } from '../../entities/index'

interface PostCommentInput {
  questionId: string
  userId: string
  choice: AnswerChoice
  body: string
}

export class PostCommentUseCase {
  constructor(
    private commentRepo: ICommentRepository,
    private questionRepo: IQuestionRepository,
    private notificationRepo: INotificationRepository
  ) {}

  async execute(input: PostCommentInput): Promise<Comment> {
    const comment = await this.commentRepo.create({
      questionId: input.questionId,
      userId: input.userId,
      choice: input.choice,
      body: input.body,
    })
    const question = await this.questionRepo.findById(input.questionId)
    if (question && question.userId !== input.userId) {
      await this.notificationRepo.create({
        userId: question.userId,
        actorId: input.userId,
        type: 'comment',
        targetId: comment.id,
      })
    }
    return comment
  }
}
