import type { IUserRepository } from '../../repositories/IUserRepository'
import type { User } from '../../entities/index'

interface UpdateProfileInput {
  userId: string
  name?: string
  avatarUrl?: string | null
  bio?: string | null
}

export class UpdateProfileUseCase {
  constructor(private userRepo: IUserRepository) {}

  async execute(input: UpdateProfileInput): Promise<User> {
    const user = await this.userRepo.findById(input.userId)
    if (!user) {
      throw Object.assign(new Error('User not found'), { code: 'NOT_FOUND' })
    }
    return this.userRepo.update(input.userId, {
      name: input.name,
      avatarUrl: input.avatarUrl,
      bio: input.bio,
    })
  }
}
