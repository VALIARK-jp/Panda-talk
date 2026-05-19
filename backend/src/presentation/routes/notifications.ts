import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import { createContainer } from '../../infrastructure/container'
import type { Env } from '../../infrastructure/env'

type Variables = { userId: string }

const app = new Hono<{ Bindings: Env; Variables: Variables }>()

// GET /notifications - 通知一覧（認証必要）
app.get('/', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const limit = Number(c.req.query('limit') ?? '20')
    const cursor = c.req.query('cursor')
    const { getNotificationsUseCase } = createContainer(c.env)
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
    const { markAsReadUseCase } = createContainer(c.env)
    await markAsReadUseCase.markAll(userId)
    return c.json({ success: true })
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
