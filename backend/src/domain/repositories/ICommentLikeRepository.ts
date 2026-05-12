import type { UUID, CommentLike } from '../entities/index'

export interface ICommentLikeRepository {
  find(userId: UUID, commentId: UUID): Promise<CommentLike | null>
  create(userId: UUID, commentId: UUID): Promise<CommentLike>
  delete(userId: UUID, commentId: UUID): Promise<void>
}
