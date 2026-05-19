import type { UUID, Comment, AnswerChoice } from '../../domain/entities/index'
import type { ICommentRepository } from '../../domain/repositories/ICommentRepository'

const comments: Comment[] = [
  {
    id: 'comment-1',
    questionId: 'question-1',
    userId: 'user-1',
    choice: 'a',
    body: 'やっぱりご飯が一番！',
    likeCount: 3,
    createdAt: '2024-01-16T00:00:00.000Z',
  },
  {
    id: 'comment-2',
    questionId: 'question-1',
    userId: 'user-2',
    choice: 'b',
    body: 'パンの方が手軽でいいよ',
    likeCount: 1,
    createdAt: '2024-01-16T01:00:00.000Z',
  },
  {
    id: 'comment-3',
    questionId: 'question-2',
    userId: 'user-3',
    choice: 'a',
    body: '家でゆっくりするのが好き',
    likeCount: 5,
    createdAt: '2024-01-16T02:00:00.000Z',
  },
]

export class MockCommentRepository implements ICommentRepository {
  async findByQuestion(
    questionId: UUID,
    choice?: AnswerChoice,
    _viewerUserId?: UUID
  ): Promise<Comment[]> {
    return comments
      .filter(
        (c) =>
          c.questionId === questionId && (choice === undefined || c.choice === choice)
      )
      .map((c) => ({ ...c, likedByMe: false }))
  }

  async findById(id: UUID): Promise<Comment | null> {
    return comments.find((c) => c.id === id) ?? null
  }

  async create(data: Omit<Comment, 'id' | 'likeCount' | 'createdAt'>): Promise<Comment> {
    const comment: Comment = {
      id: crypto.randomUUID(),
      ...data,
      likeCount: 0,
      createdAt: new Date().toISOString(),
    }
    comments.push(comment)
    return comment
  }

  async delete(id: UUID): Promise<void> {
    const idx = comments.findIndex((c) => c.id === id)
    if (idx !== -1) comments.splice(idx, 1)
  }
}
