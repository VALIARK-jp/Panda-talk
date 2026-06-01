import type { IUserRepository } from '../../repositories/IUserRepository'
import type { User, UUID } from '../../entities/index'

type EnsureUserProfileInput = {
  userId: UUID
  email?: string | null
  username?: string | null
  name?: string | null
  avatarUrl?: string | null
  bio?: string | null
}

export class EnsureUserProfileUseCase {
  constructor(private readonly userRepo: IUserRepository) {}

  async execute(input: EnsureUserProfileInput): Promise<User> {
    const existing = await this.userRepo.findById(input.userId)
    const username = await this.resolveUsername(input, existing)
    const name =
      existing?.name?.trim()
        ? existing.name
        : this.resolveName(input, existing, username)

    return this.userRepo.upsert({
      id: input.userId,
      email: input.email ?? existing?.email ?? null,
      username,
      name,
      avatarUrl: input.avatarUrl ?? existing?.avatarUrl ?? null,
      bio: input.bio ?? existing?.bio ?? null,
    })
  }

  private async resolveUsername(
    input: EnsureUserProfileInput,
    existing: User | null
  ): Promise<string> {
    if (existing?.username?.trim()) {
      return existing.username
    }
    // OAuth の displayName / email を username に流用しない（初回設定画面でユーザーが決める）。
    return generatePlaceholderUsername(input.userId)
  }

  private resolveName(
    input: EnsureUserProfileInput,
    existing: User | null,
    username: string
  ): string {
    const name = input.name ?? existing?.name ?? username
    return name.trim() || username
  }
}

function generatePlaceholderUsername(userId: string): string {
  const suffix = userId.replace(/-/g, '').slice(0, 6)
  return `panda_${suffix}`.slice(0, 20)
}
