import type { CompareAnswer, UUID, MatchResult, MatchScore } from '../../../domain/entities/index'
import type { IMatchRepository } from '../../../domain/repositories/IMatchRepository'
import type { SupabaseRestClient } from '../SupabaseRestClient'
import {
  toMatchResult,
  toMatchScore,
  toUser,
  type MatchScoreRow,
  type UserRow,
} from './mappers'

type MatchKind = 'similar' | 'opposite' | 'middle'

type CompareAnswerRow = {
  question_id: string
  choice: 'a' | 'b'
}

type CompareQuestionRow = {
  id: string
  text: string
  option_a: string
  option_b: string
}

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

  async getCompareAnswers(userAId: UUID, userBId: UUID): Promise<CompareAnswer[]> {
    const [mine, theirs] = await Promise.all([
      this.client.get<CompareAnswerRow[]>('panda_answers', {
        select: 'question_id,choice',
        user_id: `eq.${userAId}`,
        limit: 1000,
      }),
      this.client.get<CompareAnswerRow[]>('panda_answers', {
        select: 'question_id,choice',
        user_id: `eq.${userBId}`,
        limit: 1000,
      }),
    ])

    const mineByQuestion = new Map(mine.map((answer) => [answer.question_id, answer.choice]))
    const theirsByQuestion = new Map(theirs.map((answer) => [answer.question_id, answer.choice]))
    const questionIds = [...mineByQuestion.keys()].filter((id) => theirsByQuestion.has(id))
    if (questionIds.length === 0) return []

    const questions = await this.client.get<CompareQuestionRow[]>('panda_questions', {
      select: 'id,text,option_a,option_b',
      id: `in.(${questionIds.join(',')})`,
    })
    const questionById = new Map(questions.map((question) => [question.id, question]))

    return questionIds
      .map((questionId) => {
        const question = questionById.get(questionId)
        const myChoice = mineByQuestion.get(questionId)
        const theirChoice = theirsByQuestion.get(questionId)
        if (!question || !myChoice || !theirChoice) return null

        return {
          questionId,
          question: question.text,
          mine: myChoice === 'a' ? question.option_a : question.option_b,
          theirs: theirChoice === 'a' ? question.option_a : question.option_b,
          match: myChoice === theirChoice,
        }
      })
      .filter((answer): answer is CompareAnswer => answer !== null)
  }

  private async getMatches(
    userId: UUID,
    limit: number,
    cursor: UUID | undefined,
    kind: MatchKind
  ): Promise<MatchResult[]> {
    const calculated = await this.calculateMatchesFromAnswers(userId, limit, cursor, kind)
    if (calculated.length > 0) return calculated

    const rows = await this.client.get<MatchScoreRow[]>('panda_match_scores', {
      select: 'id,user_a_id,user_b_id,match_rate,common_answer_count,same_answer_count,updated_at',
      or: `(user_a_id.eq.${userId},user_b_id.eq.${userId})`,
      order: kind === 'opposite' ? 'match_rate.asc' : 'match_rate.desc',
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

  private async calculateMatchesFromAnswers(
    userId: UUID,
    limit: number,
    cursor: UUID | undefined,
    kind: MatchKind
  ): Promise<MatchResult[]> {
    const myAnswers = await this.client.get<CompareAnswerRow[]>('panda_answers', {
      select: 'question_id,choice',
      user_id: `eq.${userId}`,
      limit: 1000,
    })
    if (myAnswers.length === 0) return []

    const myChoiceByQuestion = new Map(
      myAnswers.map((answer) => [answer.question_id, answer.choice])
    )
    const otherAnswers = await this.client.get<Array<CompareAnswerRow & { user_id: string }>>(
      'panda_answers',
      {
        select: 'user_id,question_id,choice',
        question_id: `in.(${[...myChoiceByQuestion.keys()].join(',')})`,
        user_id: `neq.${userId}`,
        limit: 10000,
      }
    )

    const scores = new Map<string, { common: number; same: number }>()
    for (const answer of otherAnswers) {
      const mine = myChoiceByQuestion.get(answer.question_id)
      if (!mine) continue
      const current = scores.get(answer.user_id) ?? { common: 0, same: 0 }
      current.common += 1
      if (mine === answer.choice) current.same += 1
      scores.set(answer.user_id, current)
    }

    const filtered = [...scores.entries()]
      .map(([partnerId, score]) => ({
        partnerId,
        commonAnswerCount: score.common,
        sameAnswerCount: score.same,
        matchRate: score.common === 0 ? 0 : score.same / score.common,
      }))
      .filter((score) => {
        if (kind === 'similar') return score.matchRate >= 0.7
        if (kind === 'opposite') return score.matchRate < 0.4
        return score.matchRate >= 0.4 && score.matchRate < 0.7
      })
      .sort((a, b) =>
        kind === 'opposite'
          ? a.matchRate - b.matchRate || b.commonAnswerCount - a.commonAnswerCount
          : b.matchRate - a.matchRate || b.commonAnswerCount - a.commonAnswerCount
      )

    let page = filtered
    if (cursor) {
      const index = page.findIndex((score) => score.partnerId === cursor)
      if (index !== -1) page = page.slice(index + 1)
    }
    page = page.slice(0, limit)
    if (page.length === 0) return []

    const users = await this.client.get<UserRow[]>('panda_profiles', {
      select: 'id,email,username,name,avatar_url,bio,created_at',
      id: `in.(${page.map((score) => score.partnerId).join(',')})`,
    })
    const usersById = new Map(users.map((user) => [user.id, user]))

    return page
      .map((score) => {
        const user = usersById.get(score.partnerId)
        if (!user) return null
        return {
          user: toUser(user),
          matchRate: score.matchRate,
          commonAnswerCount: score.commonAnswerCount,
          displayScore:
            score.matchRate *
            (score.commonAnswerCount / (score.commonAnswerCount + 50)),
        }
      })
      .filter((result): result is MatchResult => result !== null)
  }
}
