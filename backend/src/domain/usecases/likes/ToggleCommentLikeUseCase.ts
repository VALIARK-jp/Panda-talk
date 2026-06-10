import type { ICommentRepository } from '../../repositories/ICommentRepository'
import type { ICommentLikeRepository } from '../../repositories/ICommentLikeRepository'
import type { INotificationRepository } from '../../repositories/INotificationRepository'

interface ToggleResult {
  liked: boolean
  created: boolean
}

export class ToggleCommentLikeUseCase {
  constructor(
    private commentLikeRepo: ICommentLikeRepository,
    private commentRepo: ICommentRepository,
    private notificationRepo: INotificationRepository
  ) {}

  async like(userId: string, commentId: string): Promise<ToggleResult> {
    const existing = await this.commentLikeRepo.find(userId, commentId)
    if (existing) {
      return { liked: true, created: false }
    }
    await this.commentLikeRepo.create(userId, commentId)
    const comment = await this.commentRepo.findById(commentId)
    if (comment && comment.userId !== userId) {
      await this.notificationRepo.create({
        userId: comment.userId,
        actorId: userId,
        type: 'like',
        targetId: commentId,
      })
    }
    return { liked: true, created: true }
  }

  async unlike(userId: string, commentId: string): Promise<ToggleResult> {
    const existing = await this.commentLikeRepo.find(userId, commentId)
    if (!existing) {
      return { liked: false, created: false }
    }
    await this.commentLikeRepo.delete(userId, commentId)
    return { liked: false, created: false }
  }
}
