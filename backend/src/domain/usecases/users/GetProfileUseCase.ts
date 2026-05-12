import type { IUserRepository } from '../../repositories/IUserRepository'
import type { User } from '../../entities/index'

export class GetProfileUseCase {
  constructor(private userRepo: IUserRepository) {}

  async execute(userId: string): Promise<User> {
    const user = await this.userRepo.findById(userId)
    if (!user) {
      throw Object.assign(new Error('User not found'), { code: 'NOT_FOUND' })
    }
    return user
  }
}
