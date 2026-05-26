import type { Context } from 'hono'
import type { Env } from '../../infrastructure/env'

type AppError = Error & { code?: string }

export function handleError(err: unknown, c: Context) {
  const error = err as AppError
  switch (error.code) {
    case 'NOT_FOUND':
      return c.json({ error: 'NOT_FOUND', message: error.message }, 404)
    case 'FORBIDDEN':
      return c.json({ error: 'FORBIDDEN', message: error.message }, 403)
    case 'CONFLICT':
      return c.json({ error: 'CONFLICT', message: error.message }, 409)
    case 'BAD_REQUEST':
      return c.json({ error: 'BAD_REQUEST', message: error.message }, 400)
    default:
      console.error(err)
      const env = c.env as Env | undefined
      if (env?.APP_ENV !== 'production') {
        const message =
          error?.message && error.message.trim().isNotEmpty
            ? error.message
            : 'Internal server error'
        return c.json({ error: 'INTERNAL_ERROR', message }, 500)
      }
      return c.json({ error: 'INTERNAL_ERROR', message: 'Internal server error' }, 500)
  }
}
