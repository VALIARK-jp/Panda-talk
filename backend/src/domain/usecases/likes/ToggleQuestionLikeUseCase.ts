import type { INotificationRepository } from '../../repositories/INotificationRepository'
import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { IQuestionLikeRepository } from '../../repositories/IQuestionLikeRepository'

interface ToggleResult {
  liked: boolean
  created: boolean
}

export class ToggleQuestionLikeUseCase {
  constructor(
    private questionLikeRepo: IQuestionLikeRepository,
    private questionRepo: IQuestionRepository,
    private notificationRepo: INotificationRepository
  ) {}

  async like(userId: string, questionId: string): Promise<ToggleResult> {
    const existing = await this.questionLikeRepo.find(userId, questionId)
    if (existing) {
      return { liked: true, created: false }
    }
    await this.questionLikeRepo.create(userId, questionId)
    const question = await this.questionRepo.findById(questionId)
    if (question && question.userId !== userId) {
      await this.notificationRepo.create({
        userId: question.userId,
        actorId: userId,
        type: 'like',
        targetId: questionId,
      })
    }
    return { liked: true, created: true }
  }

  async unlike(userId: string, questionId: string): Promise<ToggleResult> {
    const existing = await this.questionLikeRepo.find(userId, questionId)
    if (!existing) {
      return { liked: false, created: false }
    }
    await this.questionLikeRepo.delete(userId, questionId)
    return { liked: false, created: false }
  }
}
