import type { UUID, Friendship } from '../../domain/entities/index'
import type { IFriendshipRepository } from '../../domain/repositories/IFriendshipRepository'

const friendships: Friendship[] = []

export class MockFriendshipRepository implements IFriendshipRepository {
  async sendRequest(userAId: UUID, userBId: UUID, requestedBy: UUID): Promise<Friendship> {
    const friendship: Friendship = {
      id: crypto.randomUUID(),
      userAId,
      userBId,
      requestedBy,
      status: 'pending',
      createdAt: new Date().toISOString(),
    }
    friendships.push(friendship)
    return friendship
  }

  async accept(userAId: UUID, userBId: UUID): Promise<Friendship> {
    const f = friendships.find(
      (f) => f.userAId === userAId && f.userBId === userBId
    )
    if (!f) throw new Error('Friendship not found')
    f.status = 'accepted'
    return f
  }

  async delete(userAId: UUID, userBId: UUID): Promise<void> {
    const idx = friendships.findIndex(
      (f) =>
        (f.userAId === userAId && f.userBId === userBId) ||
        (f.userAId === userBId && f.userBId === userAId)
    )
    if (idx !== -1) friendships.splice(idx, 1)
  }

  async findFriends(userId: UUID): Promise<Friendship[]> {
    return friendships.filter(
      (f) =>
        f.status === 'accepted' &&
        (f.userAId === userId || f.userBId === userId)
    )
  }

  async findPendingReceived(userId: UUID): Promise<Friendship[]> {
    return friendships.filter(
      (f) =>
        f.status === 'pending' &&
        f.requestedBy !== userId &&
        (f.userAId === userId || f.userBId === userId)
    )
  }

  async findBetween(userAId: UUID, userBId: UUID): Promise<Friendship | null> {
    return (
      friendships.find(
        (f) =>
          (f.userAId === userAId && f.userBId === userBId) ||
          (f.userAId === userBId && f.userBId === userAId)
      ) ?? null
    )
  }
}
