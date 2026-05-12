import type { IDirectMessageRepository } from '../../repositories/IDirectMessageRepository'
import type { DirectMessage, User } from '../../entities/index'

export class GetDirectMessagesUseCase {
  constructor(private dmRepo: IDirectMessageRepository) {}

  async getConversation(
    userId: string,
    partnerId: string,
    limit: number,
    cursor?: string
  ): Promise<DirectMessage[]> {
    return this.dmRepo.findBetween(userId, partnerId, limit, cursor)
  }

  async getThreads(userId: string): Promise<{ partner: User; lastMessage: DirectMessage }[]> {
    return this.dmRepo.findThreads(userId)
  }
}
