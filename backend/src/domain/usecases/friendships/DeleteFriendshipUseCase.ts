import type { IFriendshipRepository } from '../../repositories/IFriendshipRepository'

export class DeleteFriendshipUseCase {
  constructor(private friendshipRepo: IFriendshipRepository) {}

  async execute(userId: string, targetId: string): Promise<void> {
    const friendship = await this.friendshipRepo.findBetween(userId, targetId)
    if (!friendship) {
      throw Object.assign(new Error('Friendship not found'), { code: 'NOT_FOUND' })
    }
    await this.friendshipRepo.delete(friendship.userAId, friendship.userBId)
  }
}
