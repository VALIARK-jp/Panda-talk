import type { ICommentLikeRepository } from '../../repositories/ICommentLikeRepository'

interface ToggleResult {
  liked: boolean
}

export class ToggleCommentLikeUseCase {
  constructor(private commentLikeRepo: ICommentLikeRepository) {}

  async like(userId: string, commentId: string): Promise<ToggleResult> {
    const existing = await this.commentLikeRepo.find(userId, commentId)
    if (existing) {
      return { liked: true }
    }
    await this.commentLikeRepo.create(userId, commentId)
    return { liked: true }
  }

  async unlike(userId: string, commentId: string): Promise<ToggleResult> {
    const existing = await this.commentLikeRepo.find(userId, commentId)
    if (!existing) {
      return { liked: false }
    }
    await this.commentLikeRepo.delete(userId, commentId)
    return { liked: false }
  }
}
