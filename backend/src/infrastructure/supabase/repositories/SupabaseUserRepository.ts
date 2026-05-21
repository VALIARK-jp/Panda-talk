import type { User, UUID } from '../../../domain/entities/index'
import type { IUserRepository } from '../../../domain/repositories/IUserRepository'
import { SupabaseRestClient } from '../SupabaseRestClient'

type UserRow = {
  id: string
  email: string | null
  username: string
  name: string
  avatar_url: string | null
  bio: string | null
  created_at: string
  panda_type_slug: string | null
  type_affection_pct: number | null
  type_thinking_pct: number | null
  type_action_pct: number | null
  type_life_pct: number | null
  diagnosed_16_at: string | null
}

export class SupabaseUserRepository implements IUserRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  private readonly resource = 'panda_profiles'

  async findById(id: UUID): Promise<User | null> {
    const rows = await this.client.get<UserRow[]>(this.resource, {
      select: '*',
      id: `eq.${id}`,
      limit: 1,
    })
    if (!rows[0]) return null

    // Fetch counts from other tables
    const [answerCount, postCount, friendCount, oddballScore] = await Promise.all([
      this.client.count('panda_answers', { user_id: `eq.${id}` }),
      this.client.count('panda_questions', { user_id: `eq.${id}` }),
      this.client.count('panda_friendships', {
        or: `(user_a_id.eq.${id},user_b_id.eq.${id})`,
        status: 'eq.accepted',
      }),
      this.fetchOddballScore(id),
    ])

    return mapUser(rows[0], {
      answerCount,
      postCount,
      friendCount,
      oddballScore,
      tags: [], // TODO: Generate tags from answers
    })
  }

  async findByIds(ids: UUID[]): Promise<User[]> {
    if (ids.length === 0) return []
    const rows = await this.client.get<UserRow[]>(this.resource, {
      select: '*',
      id: `in.(${ids.join(',')})`,
    })
    return rows.map((row) => mapUser(row))
  }

  async findByUsername(username: string): Promise<User | null> {
    const rows = await this.client.get<UserRow[]>(this.resource, {
      select: '*',
      username: `eq.${username}`,
      limit: 1,
    })
    return rows[0] ? mapUser(rows[0]) : null
  }

  async searchByUsername(prefix: string, limit: number): Promise<User[]> {
    const rows = await this.client.get<UserRow[]>(this.resource, {
      select: '*',
      username: `ilike.${prefix}%`,
      order: 'username.asc',
      limit,
    })
    return rows.map((row) => mapUser(row))
  }

  async isUsernameTaken(username: string): Promise<boolean> {
    return (await this.findByUsername(username)) !== null
  }

  async create(data: Omit<User, 'id' | 'createdAt'>): Promise<User> {
    const rows = await this.client.insert<UserRow>(this.resource, toRow(data))
    if (!rows[0]) throw new Error('Failed to create user')
    return mapUser(rows[0])
  }

  async upsert(data: Omit<User, 'createdAt'>): Promise<User> {
    const patchRows = await this.client.update<UserRow>(
      this.resource,
      { id: `eq.${data.id}` },
      toRow(data)
    )
    if (patchRows[0]) return mapUser(patchRows[0])

    const rows = await this.client.insert<UserRow>(this.resource, toRow(data))
    if (!rows[0]) throw new Error('Failed to upsert user')
    return mapUser(rows[0])
  }

  async update(
    id: UUID,
    data: Partial<
      Pick<
        User,
        | 'name'
        | 'username'
        | 'avatarUrl'
        | 'bio'
        | 'pandaTypeSlug'
        | 'typeAffectionPct'
        | 'typeThinkingPct'
        | 'typeActionPct'
        | 'typeLifePct'
        | 'diagnosed16At'
      >
    >
  ): Promise<User> {
    const rows = await this.client.update<UserRow>(
      this.resource,
      { id: `eq.${id}` },
      toRow(data)
    )
    if (!rows[0]) throw new Error('User not found')
    return mapUser(rows[0])
  }

  async delete(id: UUID): Promise<void> {
    await this.client.delete(this.resource, { id: `eq.${id}` })
  }

  private async fetchOddballScore(userId: UUID): Promise<number> {
    const rows = await this.client.get<Array<{ oddball_score: number }>>(
      'panda_user_oddball_scores',
      {
        select: 'oddball_score',
        user_id: `eq.${userId}`,
        limit: 1,
      }
    )
    return rows[0]?.oddball_score ?? 0
  }
}

function mapUser(
  row: UserRow,
  stats?: Partial<Pick<User, 'answerCount' | 'postCount' | 'friendCount' | 'oddballScore' | 'tags'>>
): User {
  return {
    id: row.id,
    email: row.email,
    username: row.username,
    name: row.name,
    avatarUrl: row.avatar_url,
    bio: row.bio,
    createdAt: row.created_at,
    pandaTypeSlug: row.panda_type_slug,
    typeAffectionPct: row.type_affection_pct,
    typeThinkingPct: row.type_thinking_pct,
    typeActionPct: row.type_action_pct,
    typeLifePct: row.type_life_pct,
    diagnosed16At: row.diagnosed_16_at,
    ...stats,
  }
}

function toRow(data: Partial<Omit<User, 'createdAt'>>): Record<string, unknown> {
  return {
    ...(data.id !== undefined ? { id: data.id } : {}),
    ...(data.email !== undefined ? { email: data.email } : {}),
    ...(data.username !== undefined ? { username: data.username } : {}),
    ...(data.name !== undefined ? { name: data.name } : {}),
    ...(data.avatarUrl !== undefined ? { avatar_url: data.avatarUrl } : {}),
    ...(data.bio !== undefined ? { bio: data.bio } : {}),
    ...(data.pandaTypeSlug !== undefined ? { panda_type_slug: data.pandaTypeSlug } : {}),
    ...(data.typeAffectionPct !== undefined ? { type_affection_pct: data.typeAffectionPct } : {}),
    ...(data.typeThinkingPct !== undefined ? { type_thinking_pct: data.typeThinkingPct } : {}),
    ...(data.typeActionPct !== undefined ? { type_action_pct: data.typeActionPct } : {}),
    ...(data.typeLifePct !== undefined ? { type_life_pct: data.typeLifePct } : {}),
    ...(data.diagnosed16At !== undefined ? { diagnosed_16_at: data.diagnosed16At } : {}),
  }
}
