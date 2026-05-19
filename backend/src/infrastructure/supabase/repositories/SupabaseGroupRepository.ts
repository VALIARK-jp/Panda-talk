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

type ProfileRow = {
  id: string
  username: string
  name: string | null
}

type MatchScoreRow = {
  user_a_id: string
  user_b_id: string
  match_rate: number
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
    return Promise.all(
      rows.map(async (row) => {
        const group = mapGroup(row)
        const members = await this.findMembers(group.id)
        const memberIds = members.map((member) => member.userId)
        const partnerIds = memberIds.filter((memberId) => memberId !== userId)

        const profiles = memberIds.length === 0
          ? []
          : await this.client.get<ProfileRow[]>('panda_profiles', {
              select: 'id,username,name',
              id: `in.(${memberIds.join(',')})`,
            })

        const matchScores = partnerIds.length === 0
          ? []
          : await this.client.get<MatchScoreRow[]>('panda_match_scores', {
              select: 'user_a_id,user_b_id,match_rate',
              or: `(${partnerIds
                .flatMap((partnerId) => [
                  `and(user_a_id.eq.${userId},user_b_id.eq.${partnerId})`,
                  `and(user_a_id.eq.${partnerId},user_b_id.eq.${userId})`,
                ])
                .join(',')})`,
            })

        const avgMatchRate = matchScores.length === 0
          ? 0
          : Math.round(
              (matchScores.reduce((sum, score) => sum + normalizeRate(score.match_rate), 0) /
                matchScores.length)
            )

        return {
          ...group,
          members: profiles.map((profile) => profile.name || profile.username),
          avgMatchRate,
        }
      })
    )
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

function normalizeRate(rate: number): number {
  return rate <= 1 ? rate * 100 : rate
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
