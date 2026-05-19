import { Hono } from 'hono'
import { authMiddleware, resolveUserId } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import { createContainer } from '../../infrastructure/container'
import type { Env } from '../../infrastructure/env'
import type { AnswerChoice } from '../../domain/entities/index'

type Variables = { userId: string }

const app = new Hono<{ Bindings: Env; Variables: Variables }>()

// GET /questions/:id/comments - コメント一覧
app.get('/questions/:id/comments', async (c) => {
  try {
    const questionId = c.req.param('id')
    const choiceParam = c.req.query('choice')
    const choice =
      choiceParam === 'a' || choiceParam === 'b' ? (choiceParam as AnswerChoice) : undefined
    const token = c.req.header('Authorization')?.replace('Bearer ', '')
    const viewerUserId = token ? await resolveUserId(c.env, token) : undefined
    const { getCommentsUseCase } = createContainer(c.env)
    const comments = await getCommentsUseCase.execute(
      questionId,
      choice,
      viewerUserId ?? undefined
    )
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
    const { postCommentUseCase } = createContainer(c.env)
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
    const { deleteCommentUseCase } = createContainer(c.env)
    await deleteCommentUseCase.execute(commentId, userId)
    return c.json({ success: true })
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
