import type { UUID, Friendship } from '../entities/index'

export interface IFriendshipRepository {
  sendRequest(userAId: UUID, userBId: UUID): Promise<Friendship>
  accept(userAId: UUID, userBId: UUID): Promise<Friendship>
  delete(userAId: UUID, userBId: UUID): Promise<void>
  findFriends(userId: UUID): Promise<Friendship[]>
  findPendingReceived(userId: UUID): Promise<Friendship[]>
  findBetween(userAId: UUID, userBId: UUID): Promise<Friendship | null>
}
