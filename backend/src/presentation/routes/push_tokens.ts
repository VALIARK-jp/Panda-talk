import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import { createContainer } from '../../infrastructure/container'
import type { Env } from '../../infrastructure/env'

type Variables = { userId: string }

type RegisterBody = {
  token?: string
  platform?: 'ios' | 'android'
}

type DeleteBody = {
  token?: string
}

const app = new Hono<{ Bindings: Env; Variables: Variables }>()

app.post('/current', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const body = (await c.req.json().catch(() => ({}))) as RegisterBody
    const token = body.token?.trim()
    const platform = body.platform
    if (!token || !platform) {
      return c.json({ error: 'BAD_REQUEST' }, 400)
    }

    const { pushTokenRepo } = createContainer(c.env)
    if (!pushTokenRepo) {
      return c.json({ error: 'PUSH_NOT_AVAILABLE' }, 501)
    }
    const saved = await pushTokenRepo.saveForUser(userId, token, platform)
    return c.json({ success: true, pushToken: saved })
  } catch (err) {
    return handleError(err, c)
  }
})

app.delete('/current', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const body = (await c.req.json().catch(() => ({}))) as DeleteBody
    const token = body.token?.trim()
    if (!token) {
      return c.json({ error: 'BAD_REQUEST' }, 400)
    }

    const { pushTokenRepo } = createContainer(c.env)
    if (!pushTokenRepo) {
      return c.json({ error: 'PUSH_NOT_AVAILABLE' }, 501)
    }
    await pushTokenRepo.deleteForUserToken(userId, token)
    return c.json({ success: true })
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
