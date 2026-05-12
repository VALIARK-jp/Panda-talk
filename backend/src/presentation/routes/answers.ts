import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import { handleError } from '../middleware/errorHandler'
import { answerQuestionUseCase } from '../../infrastructure/mock/container'
import type { AnswerChoice } from '../../domain/entities/index'

type Variables = { userId: string }

const app = new Hono<{ Variables: Variables }>()

// POST /answers - 回答（認証必要）
app.post('/', authMiddleware, async (c) => {
  try {
    const userId = c.get('userId')
    const body = await c.req.json<{
      questionId: string
      choice: AnswerChoice
    }>()
    const result = await answerQuestionUseCase.execute({
      userId,
      questionId: body.questionId,
      choice: body.choice,
    })
    return c.json({
      answer: {
        questionId: result.answer.questionId,
        choice: result.answer.choice,
        createdAt: result.answer.createdAt,
      },
      stats: result.stats,
    }, 201)
  } catch (err) {
    return handleError(err, c)
  }
})

export default app
