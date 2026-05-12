import type { IMessageRepository } from '../../repositories/IMessageRepository'
import type { IGroupRepository } from '../../repositories/IGroupRepository'
import type { Message } from '../../entities/index'

interface SendGroupMessageInput {
  groupId: string
  userId: string
  body: string
}

export class SendGroupMessageUseCase {
  constructor(
    private messageRepo: IMessageRepository,
    private groupRepo: IGroupRepository
  ) {}

  async execute(input: SendGroupMessageInput): Promise<Message> {
    const members = await this.groupRepo.findMembers(input.groupId)
    const isMember = members.some((m) => m.userId === input.userId)
    if (!isMember) {
      throw Object.assign(new Error('Forbidden'), { code: 'FORBIDDEN' })
    }
    return this.messageRepo.create({
      groupId: input.groupId,
      userId: input.userId,
      body: input.body,
    })
  }
}
