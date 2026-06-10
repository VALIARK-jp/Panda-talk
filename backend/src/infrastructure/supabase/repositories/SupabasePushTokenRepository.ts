import type { Platform, PushToken, UUID } from '../../../domain/entities/index'
import type { IPushTokenRepository } from '../../../domain/repositories/IPushTokenRepository'
import { SupabaseRestClient } from '../SupabaseRestClient'

type PushTokenRow = {
  id: string
  user_id: string
  token: string
  platform: Platform
  updated_at: string
}

export class SupabasePushTokenRepository implements IPushTokenRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  private readonly resource = 'panda_push_tokens'

  async listByUser(userId: UUID): Promise<PushToken[]> {
    const rows = await this.client.get<PushTokenRow[]>(this.resource, {
      select: '*',
      user_id: `eq.${userId}`,
      order: 'updated_at.desc',
    })
    return rows.map(mapPushToken)
  }

  async saveForUser(
    userId: UUID,
    token: string,
    platform: Platform
  ): Promise<PushToken> {
    // 同じ端末トークンが別ユーザーに紐づいていた場合は移譲する。
    await this.client.delete(this.resource, { token: `eq.${token}` })
    const rows = await this.client.insert<PushTokenRow>(this.resource, {
      user_id: userId,
      token,
      platform,
    })
    if (!rows[0]) throw new Error('Failed to save push token')
    return mapPushToken(rows[0])
  }

  async deleteForUserToken(userId: UUID, token: string): Promise<void> {
    await this.client.delete(this.resource, {
      user_id: `eq.${userId}`,
      token: `eq.${token}`,
    })
  }
}

function mapPushToken(row: PushTokenRow): PushToken {
  return {
    id: row.id,
    userId: row.user_id,
    token: row.token,
    platform: row.platform,
    updatedAt: row.updated_at,
  }
}
