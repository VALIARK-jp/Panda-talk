import type { UUID, Message } from '../../domain/entities/index'
import type { IMessageRepository } from '../../domain/repositories/IMessageRepository'

const messages: Message[] = [
  {
    id: 'message-1',
    groupId: 'group-1',
    userId: 'user-1',
    body: 'こんにちは！',
    createdAt: '2024-01-21T00:00:00.000Z',
  },
  {
    id: 'message-2',
    groupId: 'group-1',
    userId: 'user-2',
    body: 'よろしくお願いします！',
    createdAt: '2024-01-21T01:00:00.000Z',
  },
]

export class MockMessageRepository implements IMessageRepository {
  async findByGroup(groupId: UUID, limit: number, cursor?: UUID): Promise<Message[]> {
    let list = messages.filter((m) => m.groupId === groupId)
    list.sort((a, b) => a.createdAt.localeCompare(b.createdAt))
    if (cursor) {
      const idx = list.findIndex((m) => m.id === cursor)
      if (idx !== -1) list = list.slice(idx + 1)
    }
    return list.slice(0, limit)
  }

  async create(data: Omit<Message, 'id' | 'createdAt'>): Promise<Message> {
    const message: Message = {
      id: crypto.randomUUID(),
      ...data,
      createdAt: new Date().toISOString(),
    }
    messages.push(message)
    return message
  }
}
