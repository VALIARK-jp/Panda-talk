import type { UUID, Friendship } from '../../../domain/entities/index'
import type { IFriendshipRepository } from '../../../domain/repositories/IFriendshipRepository'
import { SupabaseRestClient } from '../SupabaseRestClient'

type FriendshipRow = {
  id: string
  user_a_id: string
  user_b_id: string
  requested_by: string
  status: string
  created_at: string
}

export class SupabaseFriendshipRepository implements IFriendshipRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  private readonly resource = 'panda_friendships'

  async sendRequest(userAId: UUID, userBId: UUID, requestedBy: UUID): Promise<Friendship> {
    const rows = await this.client.insert<FriendshipRow>(this.resource, {
      user_a_id: userAId,
      user_b_id: userBId,
      requested_by: requestedBy,
      status: 'pending',
    })
    if (!rows[0]) throw new Error('Failed to send friend request')
    return mapFriendship(rows[0])
  }

  async accept(userAId: UUID, userBId: UUID): Promise<Friendship> {
    const rows = await this.client.update<FriendshipRow>(
      this.resource,
      { user_a_id: `eq.${userAId}`, user_b_id: `eq.${userBId}` },
      { status: 'accepted' }
    )
    if (!rows[0]) throw new Error('Friendship not found')
    return mapFriendship(rows[0])
  }

  async delete(userAId: UUID, userBId: UUID): Promise<void> {
    await this.client.delete(this.resource, {
      user_a_id: `eq.${userAId}`,
      user_b_id: `eq.${userBId}`,
    })
  }

  async findFriends(userId: UUID): Promise<Friendship[]> {
    const rows = await this.client.get<FriendshipRow[]>(this.resource, {
      select: '*',
      or: `(user_a_id.eq.${userId},user_b_id.eq.${userId})`,
      status: 'eq.accepted',
    })
    return rows.map(mapFriendship)
  }

  async findPendingReceived(userId: UUID): Promise<Friendship[]> {
    const rows = await this.client.get<FriendshipRow[]>(this.resource, {
      select: '*',
      or: `(user_a_id.eq.${userId},user_b_id.eq.${userId})`,
      status: 'eq.pending',
      requested_by: `neq.${userId}`,
    })
    return rows.map(mapFriendship)
  }

  async findBetween(userAId: UUID, userBId: UUID): Promise<Friendship | null> {
    const rows = await this.client.get<FriendshipRow[]>(this.resource, {
      select: '*',
      user_a_id: `eq.${userAId}`,
      user_b_id: `eq.${userBId}`,
      limit: 1,
    })
    return rows[0] ? mapFriendship(rows[0]) : null
  }
}

function mapFriendship(row: FriendshipRow): Friendship {
  return {
    id: row.id,
    userAId: row.user_a_id,
    userBId: row.user_b_id,
    requestedBy: row.requested_by,
    status: row.status as any,
    createdAt: row.created_at,
  }
}
