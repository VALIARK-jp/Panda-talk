import type { UUID, DirectMessage, User } from '../entities/index'

export interface IDirectMessageRepository {
  findBetween(
    userAId: UUID,
    userBId: UUID,
    limit: number,
    cursor?: UUID
  ): Promise<DirectMessage[]>
  findThreads(userId: UUID): Promise<{ partner: User; lastMessage: DirectMessage }[]>
  create(data: Omit<DirectMessage, 'id' | 'createdAt'>): Promise<DirectMessage>
}
