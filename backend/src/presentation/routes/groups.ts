import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import {
  getGroupsUseCase,
  getGroupMessagesUseCase,
  sendGroupMessageUseCase,
} from '../../infrastructure/mock/container'

type Variables = { userId: string }

const app = new Hono<{ Variables: Variables }>()

// GET /groups - グループ一覧（認証必要）
app.get('/', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const groups = await getGroupsUseCase.execute(userId)
    return c.json({ groups })
  } catch (err) {
    return handleError(err, c)
  }
})

// GET /groups/:id/messages - グループメッセージ一覧（認証必要）
app.get('/:id/messages', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const groupId = c.req.param('id')
    const limit = Number(c.req.query('limit') ?? '50')
    const cursor = c.req.query('cursor')
    const messages = await getGroupMessagesUseCase.execute(groupId, userId, limit, cursor)
    return c.json({ messages })
  } catch (err) {
    return handleError(err, c)
  }
})

// POST /groups/:id/messages - グループメッセージ送信（認証必要）
app.post('/:id/messages', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const groupId = c.req.param('id')
    const body = await c.req.json<{ body: string }>()
    const message = await sendGroupMessageUseCase.execute({
      groupId,
      userId,
      body: body.body,
    })
    return c.json({ message }, 201)
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
