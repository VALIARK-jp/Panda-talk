import type { Platform, PushToken, UUID } from '../entities/index'

export interface IPushTokenRepository {
  listByUser(userId: UUID): Promise<PushToken[]>
  saveForUser(userId: UUID, token: string, platform: Platform): Promise<PushToken>
  deleteForUserToken(userId: UUID, token: string): Promise<void>
}
