import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import {
  getDirectMessagesUseCase,
  sendDirectMessageUseCase,
} from '../../infrastructure/mock/container'

type Variables = { userId: string }

const app = new Hono<{ Variables: Variables }>()

// GET /direct_messages/threads - DMスレッド一覧（認証必要）
app.get('/threads', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const threads = await getDirectMessagesUseCase.getThreads(userId)
    return c.json({ threads })
  } catch (err) {
    return handleError(err, c)
  }
})

// GET /direct_messages/:userId - DM会話（認証必要）
app.get('/:userId', authMiddleware, async (c) => {
  try {
    const myId = c.get('userId')
    const partnerId = c.req.param('userId')
    const limit = Number(c.req.query('limit') ?? '50')
    const cursor = c.req.query('cursor')
    const messages = await getDirectMessagesUseCase.getConversation(myId, partnerId, limit, cursor)
    return c.json({ messages })
  } catch (err) {
    return handleError(err, c)
  }
})

// POST /direct_messages - DM送信（認証必要）
app.post('/', authMiddleware, async (c) => {
  try {
    const senderId = c.get('userId')
    const body = await c.req.json<{
      receiverId: string
      body: string
    }>()
    const message = await sendDirectMessageUseCase.execute({
      senderId,
      receiverId: body.receiverId,
      body: body.body,
    })
    return c.json({ message }, 201)
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
