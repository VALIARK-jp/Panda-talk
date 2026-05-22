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
    const requested = input.username ?? input.name ?? input.email ?? input.userId
    const base = normalizeUsername(requested)
    let candidate = base
    let suffix = input.userId.replace(/-/g, '').slice(0, 6)
    let i = 0

    while (true) {
      const found = await this.userRepo.findByUsername(candidate)
      if (!found || found.id === input.userId) return candidate

      const tail = i === 0 ? suffix : `${suffix}${i}`
      candidate = `${base.slice(0, Math.max(3, 30 - tail.length - 1))}_${tail}`.slice(0, 30)
      i += 1
    }
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

function normalizeUsername(value: string): string {
  const normalized = value
    .toLowerCase()
    .split('@')[0]
    .replace(/[^a-z0-9_]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 30)

  if (normalized.length >= 3) return normalized
  return `panda_${normalized}`.slice(0, 30)
}
