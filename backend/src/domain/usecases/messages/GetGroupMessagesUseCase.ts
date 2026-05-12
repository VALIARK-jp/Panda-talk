import type { IMessageRepository } from '../../repositories/IMessageRepository'
import type { IGroupRepository } from '../../repositories/IGroupRepository'
import type { Message } from '../../entities/index'

export class GetGroupMessagesUseCase {
  constructor(
    private messageRepo: IMessageRepository,
    private groupRepo: IGroupRepository
  ) {}

  async execute(
    groupId: string,
    userId: string,
    limit: number,
    cursor?: string
  ): Promise<Message[]> {
    const members = await this.groupRepo.findMembers(groupId)
    const isMember = members.some((m) => m.userId === userId)
    if (!isMember) {
      throw Object.assign(new Error('Forbidden'), { code: 'FORBIDDEN' })
    }
    return this.messageRepo.findByGroup(groupId, limit, cursor)
  }
}
