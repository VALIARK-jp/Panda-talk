import type { UUID, MatchResult, MatchScore } from '../../../domain/entities/index'
import type { IMatchRepository } from '../../../domain/repositories/IMatchRepository'
import type { SupabaseRestClient } from '../SupabaseRestClient'
import {
  toMatchResult,
  toMatchScore,
  type MatchScoreRow,
  type UserRow,
} from './mappers'

type MatchKind = 'similar' | 'opposite' | 'middle'

export class SupabaseMatchRepository implements IMatchRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  async getSimilar(userId: UUID, limit: number, cursor?: UUID): Promise<MatchResult[]> {
    return this.getMatches(userId, limit, cursor, 'similar')
  }

  async getOpposite(userId: UUID, limit: number, cursor?: UUID): Promise<MatchResult[]> {
    return this.getMatches(userId, limit, cursor, 'opposite')
  }

  async getMiddle(userId: UUID, limit: number, cursor?: UUID): Promise<MatchResult[]> {
    return this.getMatches(userId, limit, cursor, 'middle')
  }

  async findBetween(userAId: UUID, userBId: UUID): Promise<MatchScore | null> {
    const [aId, bId] = userAId < userBId ? [userAId, userBId] : [userBId, userAId]
    const rows = await this.client.get<MatchScoreRow[]>('panda_match_scores', {
      select: 'id,user_a_id,user_b_id,match_rate,common_answer_count,same_answer_count,updated_at',
      user_a_id: `eq.${aId}`,
      user_b_id: `eq.${bId}`,
      limit: 1,
    })
    return rows[0] ? toMatchScore(rows[0]) : null
  }

  async upsert(userAId: UUID, userBId: UUID, isSame: boolean): Promise<void> {
    const [aId, bId] = userAId < userBId ? [userAId, userBId] : [userBId, userAId]
    const existing = await this.findBetween(aId, bId)

    if (existing) {
      const commonAnswerCount = existing.commonAnswerCount + 1
      const sameAnswerCount = existing.sameAnswerCount + (isSame ? 1 : 0)
      await this.client.update<MatchScoreRow>('panda_match_scores', {
        user_a_id: `eq.${aId}`,
        user_b_id: `eq.${bId}`,
      }, {
        common_answer_count: commonAnswerCount,
        same_answer_count: sameAnswerCount,
        match_rate: sameAnswerCount / commonAnswerCount,
        updated_at: new Date().toISOString(),
      })
      return
    }

    await this.client.insert<MatchScoreRow>('panda_match_scores', {
      user_a_id: aId,
      user_b_id: bId,
      common_answer_count: 1,
      same_answer_count: isSame ? 1 : 0,
      match_rate: isSame ? 1 : 0,
    })
  }

  private async getMatches(
    userId: UUID,
    limit: number,
    cursor: UUID | undefined,
    kind: MatchKind
  ): Promise<MatchResult[]> {
    const rows = await this.client.get<MatchScoreRow[]>('panda_match_scores', {
      select: 'id,user_a_id,user_b_id,match_rate,common_answer_count,same_answer_count,updated_at',
      or: `(user_a_id.eq.${userId},user_b_id.eq.${userId})`,
      order: 'display_score.desc',
      limit: Math.max(limit * 3, limit),
    })

    const filteredRows = rows.filter((row) => {
      if (kind === 'similar') return row.match_rate >= 0.7
      if (kind === 'opposite') return row.match_rate < 0.4
      return row.match_rate >= 0.4 && row.match_rate < 0.7
    })

    const partnerIds = filteredRows.map((row) =>
      row.user_a_id === userId ? row.user_b_id : row.user_a_id
    )
    if (partnerIds.length === 0) return []

    const users = await this.client.get<UserRow[]>('panda_profiles', {
      select: 'id,email,username,name,avatar_url,bio,created_at',
      id: `in.(${partnerIds.join(',')})`,
    })
    const usersById = new Map(users.map((user) => [user.id, user]))

    let results = filteredRows
      .map((row) => {
        const partnerId = row.user_a_id === userId ? row.user_b_id : row.user_a_id
        const user = usersById.get(partnerId)
        return user ? toMatchResult(row, user) : null
      })
      .filter((result): result is MatchResult => result !== null)

    if (cursor) {
      const index = results.findIndex((result) => result.user.id === cursor)
      if (index !== -1) results = results.slice(index + 1)
    }

    return results.slice(0, limit)
  }
}
