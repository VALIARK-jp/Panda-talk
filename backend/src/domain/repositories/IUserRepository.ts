import type { UUID, User } from '../entities/index'

export interface IUserRepository {
  findById(id: UUID): Promise<User | null>
  findByIds(ids: UUID[]): Promise<User[]>
  findByUsername(username: string): Promise<User | null>
  searchByUsername(prefix: string, limit: number): Promise<User[]>
  isUsernameTaken(username: string): Promise<boolean>
  create(data: Omit<User, 'id' | 'createdAt'>): Promise<User>
  upsert(data: Omit<User, 'createdAt'>): Promise<User>
  update(
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
  ): Promise<User>
  delete(id: UUID): Promise<void>
}
