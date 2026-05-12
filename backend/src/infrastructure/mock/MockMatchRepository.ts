import type { UUID, MatchResult, MatchScore, User } from '../../domain/entities/index'
import type { IMatchRepository } from '../../domain/repositories/IMatchRepository'

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

const matchScores: MatchScore[] = [
  {
    id: 'match-1',
    userAId: 'user-1',
    userBId: 'user-2',
    matchRate: 80,
    commonAnswerCount: 5,
    sameAnswerCount: 4,
    updatedAt: '2024-01-20T00:00:00.000Z',
  },
  {
    id: 'match-2',
    userAId: 'user-1',
    userBId: 'user-3',
    matchRate: 40,
    commonAnswerCount: 5,
    sameAnswerCount: 2,
    updatedAt: '2024-01-20T00:00:00.000Z',
  },
]

function toMatchResult(score: MatchScore, userId: UUID): MatchResult | null {
  const partnerId = score.userAId === userId ? score.userBId : score.userAId
  const user = usersData.find((u) => u.id === partnerId)
  if (!user) return null
  return {
    user,
    matchRate: score.matchRate,
    commonAnswerCount: score.commonAnswerCount,
    displayScore: Math.round(score.matchRate),
  }
}

function getScoresForUser(userId: UUID): MatchScore[] {
  return matchScores.filter(
    (s) => s.userAId === userId || s.userBId === userId
  )
}

export class MockMatchRepository implements IMatchRepository {
  async getSimilar(userId: UUID, limit: number, cursor?: UUID): Promise<MatchResult[]> {
    let results = getScoresForUser(userId)
      .filter((s) => s.matchRate >= 70)
      .map((s) => toMatchResult(s, userId))
      .filter((r): r is MatchResult => r !== null)
    if (cursor) {
      const idx = results.findIndex((r) => r.user.id === cursor)
      if (idx !== -1) results = results.slice(idx + 1)
    }
    return results.slice(0, limit)
  }

  async getOpposite(userId: UUID, limit: number, cursor?: UUID): Promise<MatchResult[]> {
    let results = getScoresForUser(userId)
      .filter((s) => s.matchRate < 40)
      .map((s) => toMatchResult(s, userId))
      .filter((r): r is MatchResult => r !== null)
    if (cursor) {
      const idx = results.findIndex((r) => r.user.id === cursor)
      if (idx !== -1) results = results.slice(idx + 1)
    }
    return results.slice(0, limit)
  }

  async getMiddle(userId: UUID, limit: number, cursor?: UUID): Promise<MatchResult[]> {
    let results = getScoresForUser(userId)
      .filter((s) => s.matchRate >= 40 && s.matchRate < 70)
      .map((s) => toMatchResult(s, userId))
      .filter((r): r is MatchResult => r !== null)
    if (cursor) {
      const idx = results.findIndex((r) => r.user.id === cursor)
      if (idx !== -1) results = results.slice(idx + 1)
    }
    return results.slice(0, limit)
  }

  async findBetween(userAId: UUID, userBId: UUID): Promise<MatchScore | null> {
    return (
      matchScores.find(
        (s) =>
          (s.userAId === userAId && s.userBId === userBId) ||
          (s.userAId === userBId && s.userBId === userAId)
      ) ?? null
    )
  }

  async upsert(userAId: UUID, userBId: UUID, isSame: boolean): Promise<void> {
    const [aId, bId] = userAId < userBId ? [userAId, userBId] : [userBId, userAId]
    const existing = matchScores.find(
      (s) => s.userAId === aId && s.userBId === bId
    )
    if (existing) {
      existing.commonAnswerCount += 1
      if (isSame) existing.sameAnswerCount += 1
      existing.matchRate =
        existing.commonAnswerCount > 0
          ? Math.round((existing.sameAnswerCount / existing.commonAnswerCount) * 100)
          : 0
      existing.updatedAt = new Date().toISOString()
    } else {
      matchScores.push({
        id: crypto.randomUUID(),
        userAId: aId,
        userBId: bId,
        matchRate: isSame ? 100 : 0,
        commonAnswerCount: 1,
        sameAnswerCount: isSame ? 1 : 0,
        updatedAt: new Date().toISOString(),
      })
    }
  }
}
