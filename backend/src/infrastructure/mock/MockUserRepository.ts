import type {
  OddballScoreDistribution,
  UUID,
  User,
} from '../../domain/entities/index'
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
      .filter((u) => u.username.startsWith(prefix))
      .slice(0, limit)
  }

  async getOddballScoreDistribution(score: number): Promise<OddballScoreDistribution> {
    const sampleScores = [4, 8, 13, 17, 21, 28, 32, 37, 41, 46, 52, 58, 63, 69, 74, 82]
    const counts = Array.from({ length: 10 }, () => 0)
    let belowOrEqual = 0

    for (const raw of sampleScores) {
      const value = Math.max(0, Math.min(100, raw))
      const index = value === 100 ? 9 : Math.floor(value / 10)
      counts[index] += 1
      if (value <= score) belowOrEqual += 1
    }

    return {
      totalUsers: sampleScores.length,
      percentile:
        sampleScores.length === 0
          ? 0
          : Math.round((belowOrEqual / sampleScores.length) * 100),
      bins: counts.map((count, index) => ({
        start: index * 10,
        end: index === 9 ? 100 : index * 10 + 9,
        count,
      })),
    }
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
