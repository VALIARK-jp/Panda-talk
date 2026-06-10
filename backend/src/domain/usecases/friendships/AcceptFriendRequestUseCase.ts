import type { IFriendshipRepository } from '../../repositories/IFriendshipRepository'
import type { INotificationRepository } from '../../repositories/INotificationRepository'
import type { Friendship } from '../../entities/index'

export class AcceptFriendRequestUseCase {
  constructor(
    private friendshipRepo: IFriendshipRepository,
    private notificationRepo: INotificationRepository
  ) {}

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

    const accepted = await this.friendshipRepo.accept(friendship.userAId, friendship.userBId)
    await this.notificationRepo.create({
      userId: requesterId,
      actorId: acceptorId,
      type: 'friend_accepted',
      targetId: accepted.id,
    })
    return accepted
  }
}
