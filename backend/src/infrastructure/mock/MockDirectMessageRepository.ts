import type { UUID, DirectMessage, User } from '../../domain/entities/index'
import type { IDirectMessageRepository } from '../../domain/repositories/IDirectMessageRepository'

const usersData: User[] = [
  {
    id: 'user-1',
    email: 'alice@example.com',
    username: 'alice',
    name: 'Alice',
    avatarUrl: null,
    bio: 'Hello, I am Alice!',
    createdAt: '2024-01-01T00:00:00.000Z',
  },
  {
    id: 'user-2',
    email: 'bob@example.com',
    username: 'bob',
    name: 'Bob',
    avatarUrl: null,
    bio: 'Hello, I am Bob!',
    createdAt: '2024-01-02T00:00:00.000Z',
  },
  {
    id: 'user-3',
    email: 'carol@example.com',
    username: 'carol',
    name: 'Carol',
    avatarUrl: null,
    bio: 'Hello, I am Carol!',
    createdAt: '2024-01-03T00:00:00.000Z',
  },
]

const directMessages: DirectMessage[] = [
  {
    id: 'dm-1',
    senderId: 'user-1',
    receiverId: 'user-2',
    body: 'やあ！',
    createdAt: '2024-01-22T00:00:00.000Z',
  },
  {
    id: 'dm-2',
    senderId: 'user-2',
    receiverId: 'user-1',
    body: 'こんにちは！',
    createdAt: '2024-01-22T01:00:00.000Z',
  },
]

export class MockDirectMessageRepository implements IDirectMessageRepository {
  async findBetween(
    userAId: UUID,
    userBId: UUID,
    limit: number,
    cursor?: UUID
  ): Promise<DirectMessage[]> {
    let list = directMessages.filter(
      (m) =>
        (m.senderId === userAId && m.receiverId === userBId) ||
        (m.senderId === userBId && m.receiverId === userAId)
    )
    list.sort((a, b) => a.createdAt.localeCompare(b.createdAt))
    if (cursor) {
      const idx = list.findIndex((m) => m.id === cursor)
      if (idx !== -1) list = list.slice(idx + 1)
    }
    return list.slice(0, limit)
  }

  async findThreads(userId: UUID): Promise<{ partner: User; lastMessage: DirectMessage }[]> {
    const partnerIds = new Set<string>()
    for (const m of directMessages) {
      if (m.senderId === userId) partnerIds.add(m.receiverId)
      if (m.receiverId === userId) partnerIds.add(m.senderId)
    }

    const threads: { partner: User; lastMessage: DirectMessage }[] = []
    for (const partnerId of partnerIds) {
      const partner = usersData.find((u) => u.id === partnerId)
      if (!partner) continue

      const conversation = directMessages
        .filter(
          (m) =>
            (m.senderId === userId && m.receiverId === partnerId) ||
            (m.senderId === partnerId && m.receiverId === userId)
        )
        .sort((a, b) => b.createdAt.localeCompare(a.createdAt))

      if (conversation.length > 0) {
        threads.push({ partner, lastMessage: conversation[0] })
      }
    }

    threads.sort((a, b) =>
      b.lastMessage.createdAt.localeCompare(a.lastMessage.createdAt)
    )
    return threads
  }

  async create(data: Omit<DirectMessage, 'id' | 'createdAt'>): Promise<DirectMessage> {
    const message: DirectMessage = {
      id: crypto.randomUUID(),
      ...data,
      createdAt: new Date().toISOString(),
    }
    directMessages.push(message)
    return message
  }
}
