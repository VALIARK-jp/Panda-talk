import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import { createContainer } from '../../infrastructure/container'
import type { Env } from '../../infrastructure/env'

type Variables = { userId: string }

const app = new Hono<{ Bindings: Env; Variables: Variables }>()

// GET /matches?type=similar|opposite|middle&limit=20&cursor=... （認証必要）
app.get('/', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const typeParam = c.req.query('type') ?? 'similar'
    const limit = Number(c.req.query('limit') ?? '20')
    const cursor = c.req.query('cursor')

    if (typeParam !== 'similar' && typeParam !== 'opposite' && typeParam !== 'middle') {
      return c.json(
        { error: 'BAD_REQUEST', message: 'type must be similar, opposite, or middle' },
        400
      )
    }

    const { getMatchesUseCase } = createContainer(c.env)
    const matches = await getMatchesUseCase.execute({
      userId,
      type: typeParam,
      limit,
      cursor,
    })
    return c.json({ matches })
  } catch (err) {
    return handleError(err, c)
  }
})

// GET /matches/:userId/answers - 2人の共通回答比較（認証必要）
app.get('/:userId/answers', authMiddleware, async (c) => {
  try {
    const myId = c.get('userId')
    const partnerId = c.req.param('userId')
    const { getCompareAnswersUseCase } = createContainer(c.env)
    const answers = await getCompareAnswersUseCase.execute(myId, partnerId)
    return c.json({ answers })
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
