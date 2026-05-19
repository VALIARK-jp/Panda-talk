import type { UUID, Comment, AnswerChoice } from '../../../domain/entities/index'
import type { ICommentRepository } from '../../../domain/repositories/ICommentRepository'
import { SupabaseRestClient } from '../SupabaseRestClient'

type CommentRow = {
  id: string
  question_id: string
  user_id: string
  choice: AnswerChoice
  body: string
  like_count: number
  created_at: string
}

export class SupabaseCommentRepository implements ICommentRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  private readonly table = 'panda_comments'
  private readonly view = 'panda_comment_summaries'

  async findByQuestion(
    questionId: UUID,
    choice?: AnswerChoice,
    viewerUserId?: UUID
  ): Promise<Comment[]> {
    const query: Record<string, string> = {
      select: '*',
      question_id: `eq.${questionId}`,
      order: 'created_at.desc',
    }
    if (choice) {
      query.choice = `eq.${choice}`
    }

    const rows = await this.client.get<CommentRow[]>(this.view, query)
    const comments = rows.map(mapComment)
    if (!viewerUserId || comments.length === 0) {
      return comments.map((comment) => ({ ...comment, likedByMe: false }))
    }

    const commentIds = comments.map((comment) => comment.id).join(',')
    const likedRows = await this.client.get<Array<{ comment_id: string }>>(
      'panda_comment_likes',
      {
        select: 'comment_id',
        user_id: `eq.${viewerUserId}`,
        comment_id: `in.(${commentIds})`,
      }
    )
    const likedIds = new Set(likedRows.map((row) => row.comment_id))

    return comments.map((comment) => ({
      ...comment,
      likedByMe: likedIds.has(comment.id),
    }))
  }

  async findById(id: UUID): Promise<Comment | null> {
    const rows = await this.client.get<CommentRow[]>(this.view, {
      select: '*',
      id: `eq.${id}`,
      limit: 1,
    })
    return rows[0] ? mapComment(rows[0]) : null
  }

  async create(data: Omit<Comment, 'id' | 'likeCount' | 'createdAt'>): Promise<Comment> {
    const rows = await this.client.insert<CommentRow>(this.table, {
      question_id: data.questionId,
      user_id: data.userId,
      choice: data.choice,
      body: data.body,
    })
    if (!rows[0]) throw new Error('Failed to create comment')
    
    // Note: Inserting into table, but returning map from row (which might not have like_count yet)
    return {
      ...mapComment(rows[0]),
      likeCount: 0,
    }
  }

  async delete(id: UUID): Promise<void> {
    await this.client.delete(this.table, { id: `eq.${id}` })
  }
}

function mapComment(row: CommentRow): Comment {
  return {
    id: row.id,
    questionId: row.question_id,
    userId: row.user_id,
    choice: row.choice,
    body: row.body,
    likeCount: row.like_count || 0,
    createdAt: row.created_at,
  }
}
