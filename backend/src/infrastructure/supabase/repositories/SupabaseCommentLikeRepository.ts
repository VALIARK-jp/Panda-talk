import type { UUID, CommentLike } from '../../../domain/entities/index'
import type { ICommentLikeRepository } from '../../../domain/repositories/ICommentLikeRepository'
import { SupabaseRestClient } from '../SupabaseRestClient'

type LikeRow = {
  id: string
  user_id: string
  comment_id: string
  created_at: string
}

export class SupabaseCommentLikeRepository implements ICommentLikeRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  private readonly resource = 'panda_comment_likes'

  async find(userId: UUID, commentId: UUID): Promise<CommentLike | null> {
    const rows = await this.client.get<LikeRow[]>(this.resource, {
      select: '*',
      user_id: `eq.${userId}`,
      comment_id: `eq.${commentId}`,
      limit: 1,
    })
    return rows[0] ? mapLike(rows[0]) : null
  }

  async create(userId: UUID, commentId: UUID): Promise<CommentLike> {
    const rows = await this.client.insert<LikeRow>(this.resource, {
      user_id: userId,
      comment_id: commentId,
    })
    if (!rows[0]) throw new Error('Failed to create like')
    return mapLike(rows[0])
  }

  async delete(userId: UUID, commentId: UUID): Promise<void> {
    await this.client.delete(this.resource, {
      user_id: `eq.${userId}`,
      comment_id: `eq.${commentId}`,
    })
  }
}

function mapLike(row: LikeRow): CommentLike {
  return {
    id: row.id,
    userId: row.user_id,
    commentId: row.comment_id,
    createdAt: row.created_at,
  }
}
