import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import {
  sendFriendRequestUseCase,
  acceptFriendRequestUseCase,
  deleteFriendshipUseCase,
  getFriendsUseCase,
} from '../../infrastructure/mock/container'

type Variables = { userId: string }

const app = new Hono<{ Variables: Variables }>()

// GET /friendships - フレンド一覧（認証必要）
app.get('/', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const [friends, pendingReceived] = await Promise.all([
      getFriendsUseCase.getFriends(userId),
      getFriendsUseCase.getPendingReceived(userId),
    ])
    return c.json({ friends, pendingReceived })
  } catch (err) {
    return handleError(err, c)
  }
})

// POST /friendships/:userId - フレンドリクエスト送信（認証必要）
app.post('/:userId', authMiddleware, async (c) => {
  try {
    const senderId = c.get('userId')
    const targetId = c.req.param('userId')
    const friendship = await sendFriendRequestUseCase.execute(senderId, targetId)
    return c.json({ friendship }, 201)
  } catch (err) {
    return handleError(err, c)
  }
})

// PATCH /friendships/:userId/accept - フレンドリクエスト承認（認証必要）
app.patch('/:userId/accept', authMiddleware, async (c) => {
  try {
    const acceptorId = c.get('userId')
    const requesterId = c.req.param('userId')
    const friendship = await acceptFriendRequestUseCase.execute(acceptorId, requesterId)
    return c.json({ friendship })
  } catch (err) {
    return handleError(err, c)
  }
})

// DELETE /friendships/:userId - フレンドシップ削除（認証必要）
app.delete('/:userId', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const targetId = c.req.param('userId')
    await deleteFriendshipUseCase.execute(userId, targetId)
    return c.json({ success: true })
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
