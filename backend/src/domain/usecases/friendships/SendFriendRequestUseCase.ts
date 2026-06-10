import type { IFriendshipRepository } from '../../repositories/IFriendshipRepository'
import type { INotificationRepository } from '../../repositories/INotificationRepository'
import type { Friendship } from '../../entities/index'

export class SendFriendRequestUseCase {
  constructor(
    private friendshipRepo: IFriendshipRepository,
    private notificationRepo: INotificationRepository
  ) {}

  async execute(senderId: string, targetId: string): Promise<Friendship> {
    if (senderId === targetId) {
      throw Object.assign(new Error('Cannot send request to yourself'), { code: 'BAD_REQUEST' })
    }

    const [userAId, userBId] = senderId < targetId ? [senderId, targetId] : [targetId, senderId]

    const existing = await this.friendshipRepo.findBetween(userAId, userBId)
    if (existing) {
      throw Object.assign(new Error('Friendship already exists'), { code: 'CONFLICT' })
    }

    const friendship = await this.friendshipRepo.sendRequest(userAId, userBId, senderId)
    await this.notificationRepo.create({
      userId: targetId,
      actorId: senderId,
      type: 'friend_request',
      targetId: friendship.id,
    })
    return friendship
  }
}
