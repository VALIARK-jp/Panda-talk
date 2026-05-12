import type { IUserRepository } from '../../repositories/IUserRepository'
import type { User } from '../../entities/index'

export class SearchUsersUseCase {
  constructor(private userRepo: IUserRepository) {}

  async execute(prefix: string, limit: number): Promise<User[]> {
    return this.userRepo.searchByUsername(prefix, limit)
  }
}
