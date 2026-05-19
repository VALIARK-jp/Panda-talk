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
    const [answerCount, postCount, friendCount] = await Promise.all([
      this.client.count('panda_answers', { user_id: `eq.${id}` }),
      this.client.count('panda_questions', { user_id: `eq.${id}` }),
      this.client.count('panda_friendships', {
        or: `(user_a_id.eq.${id},user_b_id.eq.${id})`,
        status: 'eq.accepted',
      }),
    ])

    return mapUser(rows[0], {
      answerCount,
      postCount,
      friendCount,
      oddballScore: 0, // TODO: Implement oddball score algorithm
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
    data: Partial<Pick<User, 'name' | 'username' | 'avatarUrl' | 'bio'>>
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
  }
}
