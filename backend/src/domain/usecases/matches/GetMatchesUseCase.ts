import type { IMatchRepository } from '../../repositories/IMatchRepository'
import type { MatchResult } from '../../entities/index'

type MatchType = 'similar' | 'opposite' | 'middle'

interface GetMatchesInput {
  userId: string
  type: MatchType
  limit: number
  cursor?: string
}

export class GetMatchesUseCase {
  constructor(private matchRepo: IMatchRepository) {}

  async execute(input: GetMatchesInput): Promise<MatchResult[]> {
    switch (input.type) {
      case 'similar':
        return this.matchRepo.getSimilar(input.userId, input.limit, input.cursor)
      case 'opposite':
        return this.matchRepo.getOpposite(input.userId, input.limit, input.cursor)
      case 'middle':
        return this.matchRepo.getMiddle(input.userId, input.limit, input.cursor)
      default:
        throw Object.assign(new Error('Invalid match type'), { code: 'BAD_REQUEST' })
    }
  }
}
