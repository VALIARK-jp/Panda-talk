import { Hono } from 'hono'
import { authMiddleware, resolveUserId } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import { createContainer } from '../../infrastructure/container'
import type { Env } from '../../infrastructure/env'

type Variables = { userId: string }

const app = new Hono<{ Bindings: Env; Variables: Variables }>()

// GET /questions - フィード取得（認証なし）
app.get('/', async (c) => {
  try {
    const limit = Number(c.req.query('limit') ?? '20')
    const cursor = c.req.query('cursor')
    const token = c.req.header('Authorization')?.replace('Bearer ', '')
    const userId = token ? await resolveUserId(c.env, token) : 'anonymous'
    const { getFeedUseCase } = createContainer(c.env)
    const questions = await getFeedUseCase.execute(userId ?? 'anonymous', limit, cursor)
    return c.json({ questions })
  } catch (err) {
    return handleError(err, c)
  }
})

// GET /questions/hot - ホットフィード（認証なし）
app.get('/hot', async (c) => {
  try {
    const limit = Number(c.req.query('limit') ?? '20')
    const cursor = c.req.query('cursor')
    const { getHotFeedUseCase } = createContainer(c.env)
    const questions = await getHotFeedUseCase.execute(limit, cursor)
    return c.json({ questions })
  } catch (err) {
    return handleError(err, c)
  }
})

// GET /questions/search - 検索（認証なし）
app.get('/search', async (c) => {
  try {
    const q = c.req.query('q') ?? ''
    const limit = Number(c.req.query('limit') ?? '20')
    const { searchQuestionsUseCase } = createContainer(c.env)
    const questions = await searchQuestionsUseCase.execute(q, limit)
    return c.json({ questions })
  } catch (err) {
    return handleError(err, c)
  }
})

// GET /questions/history - 回答済み履歴（認証必要）
app.get('/history', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const limit = Number(c.req.query('limit') ?? '20')
    const cursor = c.req.query('cursor')
    const { getAnsweredHistoryUseCase } = createContainer(c.env)
    const questions = await getAnsweredHistoryUseCase.execute(userId, limit, cursor)
    return c.json({ questions })
  } catch (err) {
    return handleError(err, c)
  }
})

// GET /questions/:id/stats - 統計（認証なし）
app.get('/:id/stats', async (c) => {
  try {
    const id = c.req.param('id')
    const { getQuestionStatsUseCase } = createContainer(c.env)
    const stats = await getQuestionStatsUseCase.execute(id)
    return c.json({ stats })
  } catch (err) {
    return handleError(err, c)
  }
})

// POST /questions - 質問投稿（認証必要）
app.post('/', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const body = await c.req.json<{
      text: string
      optionA: string
      optionB: string
      category?: string | null
    }>()
    const { postQuestionUseCase } = createContainer(c.env)
    const question = await postQuestionUseCase.execute({
      userId,
      text: body.text,
      optionA: body.optionA,
      optionB: body.optionB,
      category: body.category,
    })
    return c.json({ question }, 201)
  } catch (err) {
    return handleError(err, c)
  }
})

// PATCH /questions/:id - 質問編集（認証必要）
app.patch('/:id', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const id = c.req.param('id')
    const body = await c.req.json<{
      text?: string
      optionA?: string
      optionB?: string
      category?: string | null
    }>()
    const { editQuestionUseCase } = createContainer(c.env)
    const question = await editQuestionUseCase.execute({
      id,
      userId,
      ...body,
    })
    return c.json({ question })
  } catch (err) {
    return handleError(err, c)
  }
})

// DELETE /questions/:id - 質問削除（認証必要）
app.delete('/:id', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const id = c.req.param('id')
    const { deleteQuestionUseCase } = createContainer(c.env)
    await deleteQuestionUseCase.execute(id, userId)
    return c.json({ success: true })
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
