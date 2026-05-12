import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import { getMatchesUseCase } from '../../infrastructure/mock/container'

type Variables = { userId: string }

const app = new Hono<{ Variables: Variables }>()

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

export default app
