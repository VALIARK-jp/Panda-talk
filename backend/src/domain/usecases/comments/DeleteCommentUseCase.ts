import type { ICommentRepository } from '../../repositories/ICommentRepository'

export class DeleteCommentUseCase {
  constructor(private commentRepo: ICommentRepository) {}

  async execute(commentId: string, userId: string): Promise<void> {
    const comment = await this.commentRepo.findById(commentId)
    if (!comment) {
      throw Object.assign(new Error('Comment not found'), { code: 'NOT_FOUND' })
    }
    if (comment.userId !== userId) {
      throw Object.assign(new Error('Forbidden'), { code: 'FORBIDDEN' })
    }
    await this.commentRepo.delete(commentId)
  }
}
