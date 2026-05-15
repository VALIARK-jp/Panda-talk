import type { UUID, DirectMessage, User } from '../../../domain/entities/index'
import type { IDirectMessageRepository } from '../../../domain/repositories/IDirectMessageRepository'
import { SupabaseRestClient } from '../SupabaseRestClient'

type DMRow = {
  id: string
  sender_id: string
  receiver_id: string
  body: string
  created_at: string
}

export class SupabaseDirectMessageRepository implements IDirectMessageRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  private readonly resource = 'panda_direct_messages'

  async findBetween(
    userAId: UUID,
    userBId: UUID,
    limit: number,
    cursor?: UUID
  ): Promise<DirectMessage[]> {
    const query: any = {
      select: '*',
      or: `(and(sender_id.eq.${userAId},receiver_id.eq.${userBId}),and(sender_id.eq.${userBId},receiver_id.eq.${userAId}))`,
      order: 'created_at.desc',
      limit,
    }
    const rows = await this.client.get<DMRow[]>(this.resource, query)
    return rows.map(mapDM)
  }

  async findThreads(userId: UUID): Promise<{ partner: User; lastMessage: DirectMessage }[]> {
    // Note: To truly get threads with partner profiles and last message in one go, 
    // a Supabase view or RPC is better. Here we do a simplified fetch of all messages 
    // and group them in memory, which is fine for small/medium history.
    const rows = await this.client.get<(DMRow & { sender: any; receiver: any })[]>(this.resource, {
      select: '*,sender:panda_profiles!sender_id(*),receiver:panda_profiles!receiver_id(*)',
      or: `(sender_id.eq.${userId},receiver_id.eq.${userId})`,
      order: 'created_at.desc',
    })

    const threadsMap = new Map<string, { partner: User; lastMessage: DirectMessage }>()
    
    for (const row of rows) {
      const partnerId = row.sender_id === userId ? row.receiver_id : row.sender_id
      if (threadsMap.has(partnerId)) continue

      const partnerRow = row.sender_id === userId ? row.receiver : row.sender
      if (!partnerRow) continue

      threadsMap.set(partnerId, {
        partner: {
          id: partnerRow.id,
          email: partnerRow.email,
          username: partnerRow.username,
          name: partnerRow.name,
          avatarUrl: partnerRow.avatar_url,
          bio: partnerRow.bio,
          createdAt: partnerRow.created_at,
        },
        lastMessage: mapDM(row),
      })
    }

    return Array.from(threadsMap.values())
  }

  async create(data: Omit<DirectMessage, 'id' | 'createdAt'>): Promise<DirectMessage> {
    const rows = await this.client.insert<DMRow>(this.resource, {
      sender_id: data.senderId,
      receiver_id: data.receiverId,
      body: data.body,
    })
    if (!rows[0]) throw new Error('Failed to send DM')
    return mapDM(rows[0])
  }
}

function mapDM(row: DMRow): DirectMessage {
  return {
    id: row.id,
    senderId: row.sender_id,
    receiverId: row.receiver_id,
    body: row.body,
    createdAt: row.created_at,
  }
}
