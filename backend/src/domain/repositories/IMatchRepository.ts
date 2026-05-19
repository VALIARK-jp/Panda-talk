import type { CompareAnswer, UUID, MatchResult, MatchScore } from '../entities/index'

export interface IMatchRepository {
  getSimilar(userId: UUID, limit: number, cursor?: UUID): Promise<MatchResult[]>
  getOpposite(userId: UUID, limit: number, cursor?: UUID): Promise<MatchResult[]>
  getMiddle(userId: UUID, limit: number, cursor?: UUID): Promise<MatchResult[]>
  findBetween(userAId: UUID, userBId: UUID): Promise<MatchScore | null>
  getCompareAnswers(userAId: UUID, userBId: UUID): Promise<CompareAnswer[]>
  upsert(userAId: UUID, userBId: UUID, isSame: boolean): Promise<void>
}
