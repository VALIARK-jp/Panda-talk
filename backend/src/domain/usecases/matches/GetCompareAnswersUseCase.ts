import type { CompareAnswer, UUID } from '../../entities/index'
import type { IMatchRepository } from '../../repositories/IMatchRepository'

export class GetCompareAnswersUseCase {
  constructor(private matchRepo: IMatchRepository) {}

  async execute(userAId: UUID, userBId: UUID): Promise<CompareAnswer[]> {
    if (userAId === userBId) {
      throw Object.assign(new Error('Cannot compare with yourself'), { code: 'BAD_REQUEST' })
    }
    return this.matchRepo.getCompareAnswers(userAId, userBId)
  }
}
