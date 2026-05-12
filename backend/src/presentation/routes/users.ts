import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import {
  getProfileUseCase,
  updateProfileUseCase,
  searchUsersUseCase,
} from '../../infrastructure/mock/container'

type Variables = { userId: string }

const app = new Hono<{ Variables: Variables }>()

// GET /users/me - 自分のプロフィール（認証必要）
app.get('/me', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const user = await getProfileUseCase.execute(userId)
    return c.json({ user })
  } catch (err) {
    return handleError(err, c)
  }
})

// GET /users/search - ユーザー検索（認証必要）
app.get('/search', authMiddleware, async (c) => {
  try {
    const q = c.req.query('q') ?? ''
    const limit = Number(c.req.query('limit') ?? '20')
    const users = await searchUsersUseCase.execute(q, limit)
    return c.json({ users })
  } catch (err) {
    return handleError(err, c)
  }
})

// GET /users/:id - ユーザープロフィール（認証必要）
app.get('/:id', authMiddleware, async (c) => {
  try {
    const id = c.req.param('id')
    const user = await getProfileUseCase.execute(id)
    return c.json({ user })
  } catch (err) {
    return handleError(err, c)
  }
})

// PATCH /users/me - プロフィール更新（認証必要）
app.patch('/me', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const body = await c.req.json<{
      name?: string
      avatarUrl?: string | null
      bio?: string | null
    }>()
    const user = await updateProfileUseCase.execute({
      userId,
      name: body.name,
      avatarUrl: body.avatarUrl,
      bio: body.bio,
    })
    return c.json({ user })
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
