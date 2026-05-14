import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import { createContainer } from '../../infrastructure/container'
import type { Env } from '../../infrastructure/env'

type Variables = { userId: string }

const app = new Hono<{ Bindings: Env; Variables: Variables }>()

// POST /users/me - ログイン後に Panda Talk 用プロフィール行を作成/更新
app.post('/me', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const body = await c.req.json<{
      email?: string | null
      username?: string | null
      name?: string | null
      avatarUrl?: string | null
      bio?: string | null
    }>()
    const { ensureUserProfileUseCase } = createContainer(c.env)
    const user = await ensureUserProfileUseCase.execute({ userId, ...body })
    return c.json({ user })
  } catch (err) {
    return handleError(err, c)
  }
})

// GET /users/me - 自分のプロフィール（認証必要）
app.get('/me', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const { getProfileUseCase } = createContainer(c.env)
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
    const { searchUsersUseCase } = createContainer(c.env)
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
    const { getProfileUseCase } = createContainer(c.env)
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
    const { updateProfileUseCase } = createContainer(c.env)
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

// In-memory settings storage for mock API
const mockSettings: Record<string, any> = {}

// GET /users/me/settings - 通知設定取得（認証必要）
app.get('/me/settings', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const settings = mockSettings[userId] ?? {
      friendRequests: true,
      questionLikes: true,
      messages: true,
      groupUpdates: false,
    }
    return c.json({ settings })
  } catch (err) {
    return handleError(err, c)
  }
})

// PATCH /users/me/settings - 通知設定更新（認証必要）
app.patch('/me/settings', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const body = await c.req.json<{ settings: any }>()
    mockSettings[userId] = body.settings
    return c.json({ success: true, settings: mockSettings[userId] })
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
