import type { IFriendshipRepository } from '../../repositories/IFriendshipRepository'
import type { IUserRepository } from '../../repositories/IUserRepository'
import type { Friendship, User } from '../../entities/index'

export class GetFriendsUseCase {
  constructor(
    private friendshipRepo: IFriendshipRepository,
    private userRepo: IUserRepository
  ) {}

  async getFriends(userId: string): Promise<{ friendship: Friendship; user: User }[]> {
    const friendships = await this.friendshipRepo.findFriends(userId)
    const partnerIds = friendships.map((f) =>
      f.userAId === userId ? f.userBId : f.userAId
    )
    const users = await this.userRepo.findByIds(partnerIds)
    const userMap = new Map(users.map((u) => [u.id, u]))

    return friendships
      .map((f) => {
        const partnerId = f.userAId === userId ? f.userBId : f.userAId
        const user = userMap.get(partnerId)
        if (!user) return null
        return { friendship: f, user }
      })
      .filter((item): item is { friendship: Friendship; user: User } => item !== null)
  }

  async getPendingReceived(userId: string): Promise<{ friendship: Friendship; user: User }[]> {
    const friendships = await this.friendshipRepo.findPendingReceived(userId)
    const requesterIds = friendships.map((f) => f.requestedBy)
    const users = await this.userRepo.findByIds(requesterIds)
    const userMap = new Map(users.map((u) => [u.id, u]))

    return friendships
      .map((f) => {
        const user = userMap.get(f.requestedBy)
        if (!user) return null
        return { friendship: f, user }
      })
      .filter((item): item is { friendship: Friendship; user: User } => item !== null)
  }
}
