import type { IFriendshipRepository } from '../../repositories/IFriendshipRepository'
import type { Friendship } from '../../entities/index'

export class AcceptFriendRequestUseCase {
  constructor(private friendshipRepo: IFriendshipRepository) {}

  async execute(acceptorId: string, requesterId: string): Promise<Friendship> {
    const [userAId, userBId] =
      requesterId < acceptorId ? [requesterId, acceptorId] : [acceptorId, requesterId]

    const friendship = await this.friendshipRepo.findBetween(userAId, userBId)
    if (!friendship) {
      throw Object.assign(new Error('Friend request not found'), { code: 'NOT_FOUND' })
    }
    if (friendship.status === 'accepted') {
      throw Object.assign(new Error('Already friends'), { code: 'CONFLICT' })
    }

    return this.friendshipRepo.accept(friendship.userAId, friendship.userBId)
  }
}
