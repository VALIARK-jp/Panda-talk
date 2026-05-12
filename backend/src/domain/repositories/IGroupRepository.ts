import type { UUID, Group, GroupMember } from '../entities/index'

export interface IGroupRepository {
  findByUser(userId: UUID): Promise<Group[]>
  findById(id: UUID): Promise<Group | null>
  findMembers(groupId: UUID): Promise<GroupMember[]>
  create(data: Omit<Group, 'id' | 'createdAt'>): Promise<Group>
  addMember(groupId: UUID, userId: UUID): Promise<GroupMember>
  removeMember(groupId: UUID, userId: UUID): Promise<void>
}
