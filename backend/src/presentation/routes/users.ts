import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import { createContainer } from '../../infrastructure/container'
import { SupabaseRestClient } from '../../infrastructure/supabase/SupabaseRestClient'
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

// PATCH /users/me - プロフィール更新（認証必要）
app.patch('/me', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const body = await c.req.json<{
      name?: string
      username?: string
      avatarUrl?: string | null
      bio?: string | null
      pandaTypeSlug?: string | null
      typeAffectionPct?: number | null
      typeThinkingPct?: number | null
      typeActionPct?: number | null
      typeLifePct?: number | null
      diagnosed16At?: string | null
    }>()
    const { updateProfileUseCase } = createContainer(c.env)
    const user = await updateProfileUseCase.execute({
      userId,
      name: body.name,
      username: body.username,
      avatarUrl: body.avatarUrl,
      bio: body.bio,
      pandaTypeSlug: body.pandaTypeSlug,
      typeAffectionPct: body.typeAffectionPct,
      typeThinkingPct: body.typeThinkingPct,
      typeActionPct: body.typeActionPct,
      typeLifePct: body.typeLifePct,
      diagnosed16At: body.diagnosed16At,
    })
    return c.json({ user })
  } catch (err) {
    return handleError(err, c)
  }
})

type NotificationSettings = {
  likesEnabled: boolean
  commentsEnabled: boolean
  friendRequestsEnabled: boolean
  friendAcceptedEnabled: boolean
}

type NotificationSettingsRow = {
  user_id: string
  likes_enabled: boolean
  comments_enabled: boolean
  friend_requests_enabled: boolean
  friend_accepted_enabled?: boolean
}

const defaultNotificationSettings: NotificationSettings = {
  likesEnabled: true,
  commentsEnabled: true,
  friendRequestsEnabled: true,
  friendAcceptedEnabled: true,
}

const mockSettings: Record<string, NotificationSettings> = {}

function createNotificationSettingsClient(env: Env) {
  if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) return null
  return new SupabaseRestClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY)
}

function toNotificationSettings(row: NotificationSettingsRow): NotificationSettings {
  return {
    likesEnabled: row.likes_enabled,
    commentsEnabled: row.comments_enabled,
    friendRequestsEnabled: row.friend_requests_enabled,
    friendAcceptedEnabled:
      row.friend_accepted_enabled ?? row.friend_requests_enabled,
  }
}

function toNotificationSettingsRow(
  userId: string,
  settings: NotificationSettings
): NotificationSettingsRow {
  return {
    user_id: userId,
    likes_enabled: settings.likesEnabled,
    comments_enabled: settings.commentsEnabled,
    friend_requests_enabled: settings.friendRequestsEnabled,
    friend_accepted_enabled: settings.friendAcceptedEnabled,
  }
}

// GET /users/me/settings - 通知設定取得（認証必要）
app.get('/me/settings', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const client = createNotificationSettingsClient(c.env)
    const settings = client
      ? await (async () => {
          try {
            const rows = await client.get<NotificationSettingsRow[]>(
              'panda_notification_settings',
              {
                select: '*',
                user_id: `eq.${userId}`,
                limit: 1,
              }
            )
            return toNotificationSettings(rows[0] ?? {
              user_id: userId,
              likes_enabled: defaultNotificationSettings.likesEnabled,
              comments_enabled: defaultNotificationSettings.commentsEnabled,
              friend_requests_enabled:
                defaultNotificationSettings.friendRequestsEnabled,
              friend_accepted_enabled:
                defaultNotificationSettings.friendAcceptedEnabled,
            })
          } catch {
            const rows = await client.get<NotificationSettingsRow[]>(
              'panda_notification_settings',
              {
                select: 'user_id,likes_enabled,comments_enabled,friend_requests_enabled',
                user_id: `eq.${userId}`,
                limit: 1,
              }
            )
            return toNotificationSettings(rows[0] ?? {
              user_id: userId,
              likes_enabled: defaultNotificationSettings.likesEnabled,
              comments_enabled: defaultNotificationSettings.commentsEnabled,
              friend_requests_enabled:
                defaultNotificationSettings.friendRequestsEnabled,
              friend_accepted_enabled:
                defaultNotificationSettings.friendAcceptedEnabled,
            })
          }
        })()
      : mockSettings[userId] ?? defaultNotificationSettings
    return c.json({ settings })
  } catch (err) {
    return handleError(err, c)
  }
})

// PATCH /users/me/settings - 通知設定更新（認証必要）
app.patch('/me/settings', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const body = await c.req.json<{ settings: NotificationSettings }>()
    const client = createNotificationSettingsClient(c.env)
    if (client) {
      const row = toNotificationSettingsRow(userId, body.settings)
      try {
        const existing = await client.get<NotificationSettingsRow[]>(
          'panda_notification_settings',
          {
            select: 'user_id',
            user_id: `eq.${userId}`,
            limit: 1,
          }
        )
        if (existing.length > 0) {
          await client.update(
            'panda_notification_settings',
            { user_id: `eq.${userId}` },
            row
          )
        } else {
          await client.insert('panda_notification_settings', row)
        }
      } catch {
        const legacyRow = {
          user_id: userId,
          likes_enabled: body.settings.likesEnabled,
          comments_enabled: body.settings.commentsEnabled,
          friend_requests_enabled:
            body.settings.friendRequestsEnabled ||
            body.settings.friendAcceptedEnabled,
        }
        const existing = await client.get<NotificationSettingsRow[]>(
          'panda_notification_settings',
          {
            select: 'user_id',
            user_id: `eq.${userId}`,
            limit: 1,
          }
        )
        if (existing.length > 0) {
          await client.update(
            'panda_notification_settings',
            { user_id: `eq.${userId}` },
            legacyRow
          )
        } else {
          await client.insert('panda_notification_settings', legacyRow)
        }
      }
      return c.json({ success: true, settings: body.settings })
    }
    mockSettings[userId] = body.settings
    return c.json({ success: true, settings: mockSettings[userId] })
  } catch (err) {
    return handleError(err, c)
  }
})

// GET /users/me/blocks - ブロック中ユーザー一覧（認証必要）
app.get('/me/blocks', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const { getBlockedUserIdsUseCase } = createContainer(c.env)
    const result = await getBlockedUserIdsUseCase.execute(userId)
    return c.json(result)
  } catch (err) {
    return handleError(err, c)
  }
})

// POST /users/:id/block - ユーザーをブロック（認証必要）
app.post('/:id/block', authMiddleware, async (c) => {
  try {
    const blockerId = c.get('userId')
    const blockedId = c.req.param('id')
    const { blockUserUseCase } = createContainer(c.env)
    const result = await blockUserUseCase.execute(blockerId, blockedId)
    return c.json(result, 201)
  } catch (err) {
    return handleError(err, c)
  }
})

// DELETE /users/:id/block - ブロック解除（認証必要）
app.delete('/:id/block', authMiddleware, async (c) => {
  try {
    const blockerId = c.get('userId')
    const blockedId = c.req.param('id')
    const { unblockUserUseCase } = createContainer(c.env)
    const result = await unblockUserUseCase.execute(blockerId, blockedId)
    return c.json(result)
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

// DELETE /users/me - アカウント削除（認証必要）
app.delete('/me', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const { deleteUserUseCase } = createContainer(c.env)
    await deleteUserUseCase.execute(userId)
    return c.body(null, 204)
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
