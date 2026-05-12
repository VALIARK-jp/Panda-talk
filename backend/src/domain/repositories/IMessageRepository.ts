import type { UUID, Message } from '../entities/index'

export interface IMessageRepository {
  findByGroup(groupId: UUID, limit: number, cursor?: UUID): Promise<Message[]>
  create(data: Omit<Message, 'id' | 'createdAt'>): Promise<Message>
}
