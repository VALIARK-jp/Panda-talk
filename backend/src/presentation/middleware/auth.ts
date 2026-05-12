import { createMiddleware } from 'hono/factory'

type Variables = {
  userId: string
}

export const authMiddleware = createMiddleware<{ Variables: Variables }>(async (c, next) => {
  const token = c.req.header('Authorization')?.replace('Bearer ', '')
  if (!token) return c.json({ error: 'UNAUTHORIZED' }, 401)
  // 開発中はトークンをそのままuserIdとして使う（Supabase実装時に本物の検証に置き換える）
  c.set('userId', token)
  await next()
})
