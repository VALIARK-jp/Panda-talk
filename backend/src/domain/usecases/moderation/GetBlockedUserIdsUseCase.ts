import type { IModerationRepository } from '../../repositories/IModerationRepository'

export class GetBlockedUserIdsUseCase {
  constructor(private moderationRepo: IModerationRepository) {}

  async execute(blockerId: string) {
    const blockedUserIds = await this.moderationRepo.listBlockedUserIds(blockerId)
    return { blockedUserIds }
  }
}
