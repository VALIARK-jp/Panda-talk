import type { UUID, Message } from '../../../domain/entities/index'
import type { IMessageRepository } from '../../../domain/repositories/IMessageRepository'
import { SupabaseRestClient } from '../SupabaseRestClient'

type MessageRow = {
  id: string
  group_id: string
  user_id: string
  body: string
  created_at: string
  sender?: {
    name?: string | null
    username?: string | null
  } | null
}

export class SupabaseMessageRepository implements IMessageRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  private readonly resource = 'panda_messages'

  async findByGroup(groupId: UUID, limit: number, cursor?: UUID): Promise<Message[]> {
    const query: any = {
      select: '*,sender:panda_profiles!user_id(name,username)',
      group_id: `eq.${groupId}`,
      order: 'created_at.desc',
      limit,
    }
    if (cursor) {
      // For cursor-based pagination, we would need to know the created_at of the cursor message
      // and use .lt(created_at). This is a simplification.
    }

    const rows = await this.client.get<MessageRow[]>(this.resource, query)
    return rows.map(mapMessage)
  }

  async create(data: Omit<Message, 'id' | 'createdAt'>): Promise<Message> {
    const rows = await this.client.insert<MessageRow>(this.resource, {
      group_id: data.groupId,
      user_id: data.userId,
      body: data.body,
    })
    if (!rows[0]) throw new Error('Failed to send message')
    return mapMessage(rows[0])
  }
}

function mapMessage(row: MessageRow): Message {
  return {
    id: row.id,
    groupId: row.group_id,
    userId: row.user_id,
    body: row.body,
    createdAt: row.created_at,
    senderName: row.sender?.name ?? row.sender?.username ?? undefined,
  }
}
