import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import {
  getCommentsUseCase,
  postCommentUseCase,
  deleteCommentUseCase,
} from '../../infrastructure/mock/container'
import type { AnswerChoice } from '../../domain/entities/index'

type Variables = { userId: string }

const app = new Hono<{ Variables: Variables }>()

// GET /questions/:id/comments - コメント一覧（認証なし）
// Note: このルートはquestionsルーター経由でマウントされる
app.get('/questions/:id/comments', async (c) => {
  try {
    const questionId = c.req.param('id')
    const choiceParam = c.req.query('choice')
    const choice =
      choiceParam === 'a' || choiceParam === 'b' ? (choiceParam as AnswerChoice) : undefined
    const comments = await getCommentsUseCase.execute(questionId, choice)
    return c.json({ comments })
  } catch (err) {
    return handleError(err, c)
  }
})

// POST /questions/:id/comments - コメント投稿（認証必要）
app.post('/questions/:id/comments', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const questionId = c.req.param('id')
    const body = await c.req.json<{
      choice: AnswerChoice
      body: string
    }>()
    const comment = await postCommentUseCase.execute({
      questionId,
      userId,
      choice: body.choice,
      body: body.body,
    })
    return c.json({ comment }, 201)
  } catch (err) {
    return handleError(err, c)
  }
})

// DELETE /comments/:id - コメント削除（認証必要）
app.delete('/comments/:id', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const commentId = c.req.param('id')
    await deleteCommentUseCase.execute(commentId, userId)
    return c.json({ success: true })
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
