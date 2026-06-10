import type { UUID, User } from '../../domain/entities/index'
import type { IUserRepository } from '../../domain/repositories/IUserRepository'

const users: User[] = [
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

export class MockUserRepository implements IUserRepository {
  async findById(id: UUID): Promise<User | null> {
    return users.find((u) => u.id === id) ?? null
  }

  async findByIds(ids: UUID[]): Promise<User[]> {
    return users.filter((u) => ids.includes(u.id))
  }

  async findByUsername(username: string): Promise<User | null> {
    return users.find((u) => u.username === username) ?? null
  }

  async searchByUsername(prefix: string, limit: number): Promise<User[]> {
    return users
      .filter((u) =>
        u.username.startsWith(prefix) ||
        u.name.toLowerCase().includes(prefix.toLowerCase())
      )
      .slice(0, limit)
  }

  async isUsernameTaken(username: string): Promise<boolean> {
    return users.some((u) => u.username === username)
  }

  async create(data: Omit<User, 'id' | 'createdAt'>): Promise<User> {
    const user: User = {
      id: crypto.randomUUID(),
      ...data,
      createdAt: new Date().toISOString(),
    }
    users.push(user)
    return user
  }

  async upsert(data: Omit<User, 'createdAt'>): Promise<User> {
    const idx = users.findIndex((u) => u.id === data.id)
    if (idx === -1) {
      const user = { ...data, createdAt: new Date().toISOString() }
      users.push(user)
      return user
    }

    users[idx] = { ...users[idx], ...data }
    return users[idx]
  }

  async update(
    id: UUID,
    data: Partial<
      Pick<
        User,
        | 'name'
        | 'username'
        | 'avatarUrl'
        | 'bio'
        | 'pandaTypeSlug'
        | 'typeAffectionPct'
        | 'typeThinkingPct'
        | 'typeActionPct'
        | 'typeLifePct'
        | 'diagnosed16At'
      >
    >
  ): Promise<User> {
    const idx = users.findIndex((u) => u.id === id)
    if (idx === -1) throw new Error('User not found')
    users[idx] = { ...users[idx], ...data }
    return users[idx]
  }

  async delete(id: UUID): Promise<void> {
    const idx = users.findIndex((u) => u.id === id)
    if (idx !== -1) users.splice(idx, 1)
  }
}
