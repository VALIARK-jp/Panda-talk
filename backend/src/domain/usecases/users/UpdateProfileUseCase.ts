import type { IUserRepository } from '../../repositories/IUserRepository'
import type { User } from '../../entities/index'
import { isValidUsername } from '../../usernameRules'

interface UpdateProfileInput {
  userId: string
  name?: string
  username?: string
  avatarUrl?: string | null
  bio?: string | null
  pandaTypeSlug?: string | null
  typeAffectionPct?: number | null
  typeThinkingPct?: number | null
  typeActionPct?: number | null
  typeLifePct?: number | null
  diagnosed16At?: string | null
}

export class UpdateProfileUseCase {
  constructor(private userRepo: IUserRepository) {}

  async execute(input: UpdateProfileInput): Promise<User> {
    const user = await this.userRepo.findById(input.userId)
    if (!user) {
      throw Object.assign(new Error('User not found'), { code: 'NOT_FOUND' })
    }
    if (input.username !== undefined && !isValidUsername(input.username)) {
      throw Object.assign(new Error('Invalid username'), { code: 'VALIDATION' })
    }
    return this.userRepo.update(input.userId, {
      name: input.name,
      username: input.username,
      avatarUrl: input.avatarUrl,
      bio: input.bio,
      pandaTypeSlug: input.pandaTypeSlug,
      typeAffectionPct: input.typeAffectionPct,
      typeThinkingPct: input.typeThinkingPct,
      typeActionPct: input.typeActionPct,
      typeLifePct: input.typeLifePct,
      diagnosed16At: input.diagnosed16At,
    })
  }
}
