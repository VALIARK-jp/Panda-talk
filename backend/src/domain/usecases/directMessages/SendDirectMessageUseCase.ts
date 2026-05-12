import type { IDirectMessageRepository } from '../../repositories/IDirectMessageRepository'
import type { DirectMessage } from '../../entities/index'

interface SendDirectMessageInput {
  senderId: string
  receiverId: string
  body: string
}

export class SendDirectMessageUseCase {
  constructor(private dmRepo: IDirectMessageRepository) {}

  async execute(input: SendDirectMessageInput): Promise<DirectMessage> {
    if (input.senderId === input.receiverId) {
      throw Object.assign(new Error('Cannot send message to yourself'), { code: 'BAD_REQUEST' })
    }
    return this.dmRepo.create({
      senderId: input.senderId,
      receiverId: input.receiverId,
      body: input.body,
    })
  }
}
