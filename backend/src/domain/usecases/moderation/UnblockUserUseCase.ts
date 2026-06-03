import type { IModerationRepository } from '../../repositories/IModerationRepository'

export class UnblockUserUseCase {
  constructor(private moderationRepo: IModerationRepository) {}

  async execute(blockerId: string, blockedId: string) {
    await this.moderationRepo.unblockUser(blockerId, blockedId)
    return { blocked: false }
  }
}
