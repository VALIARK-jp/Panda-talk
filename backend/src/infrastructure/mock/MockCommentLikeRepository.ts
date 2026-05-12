import type { UUID, CommentLike } from '../../domain/entities/index'
import type { ICommentLikeRepository } from '../../domain/repositories/ICommentLikeRepository'

const commentLikes: CommentLike[] = []

export class MockCommentLikeRepository implements ICommentLikeRepository {
  async find(userId: UUID, commentId: UUID): Promise<CommentLike | null> {
    return commentLikes.find((l) => l.userId === userId && l.commentId === commentId) ?? null
  }

  async create(userId: UUID, commentId: UUID): Promise<CommentLike> {
    const like: CommentLike = {
      id: crypto.randomUUID(),
      userId,
      commentId,
      createdAt: new Date().toISOString(),
    }
    commentLikes.push(like)
    return like
  }

  async delete(userId: UUID, commentId: UUID): Promise<void> {
    const idx = commentLikes.findIndex((l) => l.userId === userId && l.commentId === commentId)
    if (idx !== -1) commentLikes.splice(idx, 1)
  }
}
