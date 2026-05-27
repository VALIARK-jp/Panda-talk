import type { IUserRepository } from '../../repositories/IUserRepository'
import type { User } from '../../entities/index'

/**
 * 共有URL `/u/:username` から呼ばれる、username 単発取得ユースケース。
 */
export class GetUserByUsernameUseCase {
  constructor(private userRepo: IUserRepository) {}

  async execute(username: string): Promise<User | null> {
    return this.userRepo.findByUsername(username)
  }
}
