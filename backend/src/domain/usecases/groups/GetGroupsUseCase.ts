import type { IGroupRepository } from '../../repositories/IGroupRepository'
import type { Group } from '../../entities/index'

export class GetGroupsUseCase {
  constructor(private groupRepo: IGroupRepository) {}

  async execute(userId: string): Promise<Group[]> {
    return this.groupRepo.findByUser(userId)
  }
}
