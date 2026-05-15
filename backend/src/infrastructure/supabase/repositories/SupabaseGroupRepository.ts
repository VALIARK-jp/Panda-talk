import type { UUID, Group, GroupMember, GroupType } from '../../../domain/entities/index'
import type { IGroupRepository } from '../../../domain/repositories/IGroupRepository'
import { SupabaseRestClient } from '../SupabaseRestClient'

type GroupRow = {
  id: string
  name: string
  type: string
  created_at: string
}

type GroupMemberRow = {
  id: string
  group_id: string
  user_id: string
  created_at: string
}

export class SupabaseGroupRepository implements IGroupRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  private readonly table = 'panda_groups'
  private readonly membersTable = 'panda_group_members'

  async findByUser(userId: UUID): Promise<Group[]> {
    // Join with members table to find groups the user is in
    const rows = await this.client.get<GroupRow[]>(this.table, {
      select: '*,panda_group_members!inner(user_id)',
      'panda_group_members.user_id': `eq.${userId}`,
    })
    return rows.map(mapGroup)
  }

  async findById(id: UUID): Promise<Group | null> {
    const rows = await this.client.get<GroupRow[]>(this.table, {
      select: '*',
      id: `eq.${id}`,
      limit: 1,
    })
    return rows[0] ? mapGroup(rows[0]) : null
  }

  async findMembers(groupId: UUID): Promise<GroupMember[]> {
    const rows = await this.client.get<GroupMemberRow[]>(this.membersTable, {
      select: '*',
      group_id: `eq.${groupId}`,
    })
    return rows.map(mapMember)
  }

  async create(data: Omit<Group, 'id' | 'createdAt'>): Promise<Group> {
    const rows = await this.client.insert<GroupRow>(this.table, {
      name: data.name,
      type: data.type,
    })
    if (!rows[0]) throw new Error('Failed to create group')
    return mapGroup(rows[0])
  }

  async addMember(groupId: UUID, userId: UUID): Promise<GroupMember> {
    const rows = await this.client.insert<GroupMemberRow>(this.membersTable, {
      group_id: groupId,
      user_id: userId,
    })
    if (!rows[0]) throw new Error('Failed to add group member')
    return mapMember(rows[0])
  }

  async removeMember(groupId: UUID, userId: UUID): Promise<void> {
    await this.client.delete(this.membersTable, {
      group_id: `eq.${groupId}`,
      user_id: `eq.${userId}`,
    })
  }
}

function mapGroup(row: GroupRow): Group {
  return {
    id: row.id,
    name: row.name,
    type: row.type as GroupType,
    createdAt: row.created_at,
  }
}

function mapMember(row: GroupMemberRow): GroupMember {
  return {
    id: row.id,
    groupId: row.group_id,
    userId: row.user_id,
    createdAt: row.created_at,
  }
}
