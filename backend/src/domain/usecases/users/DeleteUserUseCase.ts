import type { IUserRepository } from '../../repositories/IUserRepository'
import { deleteSupabaseAuthUser } from '../../../infrastructure/supabase/deleteAuthUser'
import type { Env } from '../../../infrastructure/env'

function shouldUseSupabaseAuthDelete(env?: Env): env is Env & {
  SUPABASE_URL: string
  SUPABASE_SERVICE_ROLE_KEY: string
} {
  return Boolean(
    env?.REPOSITORY_MODE !== 'mock' &&
      env?.SUPABASE_URL &&
      env?.SUPABASE_SERVICE_ROLE_KEY
  )
}

export class DeleteUserUseCase {
  constructor(
    private readonly userRepo: IUserRepository,
    private readonly env?: Env
  ) {}

  async execute(userId: string): Promise<void> {
    if (shouldUseSupabaseAuthDelete(this.env)) {
      // auth.users 削除 → panda_profiles ほか関連データは DB の CASCADE で消える
      await deleteSupabaseAuthUser(
        this.env.SUPABASE_URL,
        this.env.SUPABASE_SERVICE_ROLE_KEY,
        userId
      )
      return
    }

    await this.userRepo.delete(userId)
  }
}
