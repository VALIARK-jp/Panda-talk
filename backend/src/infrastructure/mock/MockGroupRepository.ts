import type { UUID, Group, GroupMember } from '../../domain/entities/index'
import type { IGroupRepository } from '../../domain/repositories/IGroupRepository'

const groups: Group[] = [
  {
    id: 'group-1',
    name: 'ハイマッチグループ',
    type: 'high_match',
    createdAt: '2024-01-20T00:00:00.000Z',
  },
]

const groupMembers: GroupMember[] = [
  {
    id: 'member-1',
    groupId: 'group-1',
    userId: 'user-1',
    createdAt: '2024-01-20T00:00:00.000Z',
  },
  {
    id: 'member-2',
    groupId: 'group-1',
    userId: 'user-2',
    createdAt: '2024-01-20T00:00:00.000Z',
  },
]

export class MockGroupRepository implements IGroupRepository {
  async findByUser(userId: UUID): Promise<Group[]> {
    const memberGroupIds = groupMembers
      .filter((m) => m.userId === userId)
      .map((m) => m.groupId)
    return groups.filter((g) => memberGroupIds.includes(g.id))
  }

  async findById(id: UUID): Promise<Group | null> {
    return groups.find((g) => g.id === id) ?? null
  }

  async findMembers(groupId: UUID): Promise<GroupMember[]> {
    return groupMembers.filter((m) => m.groupId === groupId)
  }

  async create(data: Omit<Group, 'id' | 'createdAt'>): Promise<Group> {
    const group: Group = {
      id: crypto.randomUUID(),
      ...data,
      createdAt: new Date().toISOString(),
    }
    groups.push(group)
    return group
  }

  async addMember(groupId: UUID, userId: UUID): Promise<GroupMember> {
    const member: GroupMember = {
      id: crypto.randomUUID(),
      groupId,
      userId,
      createdAt: new Date().toISOString(),
    }
    groupMembers.push(member)
    return member
  }

  async removeMember(groupId: UUID, userId: UUID): Promise<void> {
    const idx = groupMembers.findIndex(
      (m) => m.groupId === groupId && m.userId === userId
    )
    if (idx !== -1) groupMembers.splice(idx, 1)
  }
}
