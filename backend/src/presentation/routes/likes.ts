import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import {
  toggleQuestionLikeUseCase,
  toggleCommentLikeUseCase,
} from '../../infrastructure/mock/container'

type Variables = { userId: string }

const app = new Hono<{ Variables: Variables }>()

// POST /questions/:id/likes - 質問いいね（認証必要）
app.post('/questions/:id/likes', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const questionId = c.req.param('id')
    const result = await toggleQuestionLikeUseCase.like(userId, questionId)
    return c.json(result, 201)
  } catch (err) {
    return handleError(err, c)
  }
})

// DELETE /questions/:id/likes - 質問いいね取り消し（認証必要）
app.delete('/questions/:id/likes', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const questionId = c.req.param('id')
    const result = await toggleQuestionLikeUseCase.unlike(userId, questionId)
    return c.json(result)
  } catch (err) {
    return handleError(err, c)
  }
})

// POST /comments/:id/likes - コメントいいね（認証必要）
app.post('/comments/:id/likes', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const commentId = c.req.param('id')
    const result = await toggleCommentLikeUseCase.like(userId, commentId)
    return c.json(result, 201)
  } catch (err) {
    return handleError(err, c)
  }
})

// DELETE /comments/:id/likes - コメントいいね取り消し（認証必要）
app.delete('/comments/:id/likes', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const commentId = c.req.param('id')
    const result = await toggleCommentLikeUseCase.unlike(userId, commentId)
    return c.json(result)
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
