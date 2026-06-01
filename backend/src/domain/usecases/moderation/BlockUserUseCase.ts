import type { IModerationRepository } from '../../repositories/IModerationRepository'

export class BlockUserUseCase {
  constructor(private moderationRepo: IModerationRepository) {}

  async execute(blockerId: string, blockedId: string) {
    if (blockerId === blockedId) {
      const err = new Error('Cannot block yourself') as Error & { code?: string }
      err.code = 'BAD_REQUEST'
      throw err
    }

    await this.moderationRepo.blockUser(blockerId, blockedId)
    return { blocked: true }
  }
}
