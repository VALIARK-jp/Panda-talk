import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import { createContainer } from '../../infrastructure/container'
import type { Env } from '../../infrastructure/env'
import type { ReportTargetType } from '../../domain/entities/moderation'

type Variables = { userId: string }

const app = new Hono<{ Bindings: Env; Variables: Variables }>()

// POST /moderation/reports - UGC通報（認証必要）
app.post('/reports', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const body = await c.req.json<{
      targetType?: ReportTargetType
      targetId?: string
      reason?: string
      detail?: string | null
    }>()
    const { reportContentUseCase } = createContainer(c.env)
    const result = await reportContentUseCase.execute({
      reporterId: userId,
      targetType: body.targetType ?? 'question',
      targetId: body.targetId ?? '',
      reason: body.reason ?? '',
      detail: body.detail,
    })
    return c.json(result, 201)
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
