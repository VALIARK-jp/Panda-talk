import type { IUserRepository } from '../../repositories/IUserRepository'
import type { User } from '../../entities/index'

export class SearchUsersUseCase {
  constructor(private userRepo: IUserRepository) {}

  async execute(query: string, limit: number): Promise<User[]> {
    const normalized = query.trim().replace(/^@+/, '')
    if (!normalized) return []
    return this.userRepo.searchByUsername(normalized, limit)
  }
}
