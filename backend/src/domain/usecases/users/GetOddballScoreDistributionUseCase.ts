import type { OddballScoreDistribution } from '../../entities/index'
import type { IUserRepository } from '../../repositories/IUserRepository'

export class GetOddballScoreDistributionUseCase {
  constructor(private readonly userRepo: IUserRepository) {}

  async execute(score: number): Promise<OddballScoreDistribution> {
    const clamped = Math.max(0, Math.min(100, Math.round(score)))
    return this.userRepo.getOddballScoreDistribution(clamped)
  }
}
