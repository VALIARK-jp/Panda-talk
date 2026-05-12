import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import {
  getFeedUseCase,
  getHotFeedUseCase,
  postQuestionUseCase,
  editQuestionUseCase,
  deleteQuestionUseCase,
  searchQuestionsUseCase,
  getQuestionStatsUseCase,
} from '../../infrastructure/mock/container'

type Variables = { userId: string }

const app = new Hono<{ Variables: Variables }>()

// GET /questions - フィード取得（認証なし）
app.get('/', async (c) => {
  try {
    const limit = Number(c.req.query('limit') ?? '20')
    const cursor = c.req.query('cursor')
    const userId = c.req.header('Authorization')?.replace('Bearer ', '') ?? 'anonymous'
    const questions = await getFeedUseCase.execute(userId, limit, cursor)
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
    const questions = await searchQuestionsUseCase.execute(q, limit)
    return c.json({ questions })
  } catch (err) {
    return handleError(err, c)
  }
})

// GET /questions/:id/stats - 統計（認証なし）
app.get('/:id/stats', async (c) => {
  try {
    const id = c.req.param('id')
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
    await deleteQuestionUseCase.execute(id, userId)
    return c.json({ success: true })
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
