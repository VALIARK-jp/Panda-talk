import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import {
  getNotificationsUseCase,
  markAsReadUseCase,
} from '../../infrastructure/mock/container'

type Variables = { userId: string }

const app = new Hono<{ Variables: Variables }>()

// GET /notifications - 通知一覧（認証必要）
app.get('/', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const limit = Number(c.req.query('limit') ?? '20')
    const cursor = c.req.query('cursor')
    const result = await getNotificationsUseCase.execute(userId, limit, cursor)
    return c.json(result)
  } catch (err) {
    return handleError(err, c)
  }
})

// PATCH /notifications/read - 通知既読（認証必要）
app.patch('/read', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    await markAsReadUseCase.markAll(userId)
    return c.json({ success: true })
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
