import type { ICommentLikeRepository } from '../../repositories/ICommentLikeRepository'

interface ToggleResult {
  liked: boolean
}

export class ToggleCommentLikeUseCase {
  constructor(private commentLikeRepo: ICommentLikeRepository) {}

  async like(userId: string, commentId: string): Promise<ToggleResult> {
    const existing = await this.commentLikeRepo.find(userId, commentId)
    if (existing) {
      throw Object.assign(new Error('Already liked'), { code: 'CONFLICT' })
    }
    await this.commentLikeRepo.create(userId, commentId)
    return { liked: true }
  }

  async unlike(userId: string, commentId: string): Promise<ToggleResult> {
    await this.commentLikeRepo.delete(userId, commentId)
    return { liked: false }
  }
}
