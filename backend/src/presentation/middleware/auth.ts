import { createMiddleware } from 'hono/factory'
import type { Env } from '../../infrastructure/env'

type Variables = {
  userId: string
}

type SupabaseAuthUserResponse = {
  id: string
}

export async function resolveUserId(env: Env, token: string): Promise<string | null> {
  if (!env.SUPABASE_URL || !env.SUPABASE_ANON_KEY) {
    return token
  }

  const response = await fetch(`${env.SUPABASE_URL.replace(/\/$/, '')}/auth/v1/user`, {
    headers: {
      apikey: env.SUPABASE_ANON_KEY,
      Authorization: `Bearer ${token}`,
    },
  })

  if (!response.ok) return null

  const user = await response.json<SupabaseAuthUserResponse>()
  return user.id
}

export const authMiddleware = createMiddleware<{ Bindings: Env; Variables: Variables }>(async (c, next) => {
  const token = c.req.header('Authorization')?.replace('Bearer ', '')
  if (!token) return c.json({ error: 'UNAUTHORIZED' }, 401)

  const userId = await resolveUserId(c.env, token)
  if (!userId) return c.json({ error: 'UNAUTHORIZED' }, 401)

  c.set('userId', userId)
  await next()
})
