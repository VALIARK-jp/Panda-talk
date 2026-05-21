import type { IQuestionLikeRepository } from '../../repositories/IQuestionLikeRepository'

interface ToggleResult {
  liked: boolean
}

export class ToggleQuestionLikeUseCase {
  constructor(private questionLikeRepo: IQuestionLikeRepository) {}

  async like(userId: string, questionId: string): Promise<ToggleResult> {
    const existing = await this.questionLikeRepo.find(userId, questionId)
    if (existing) {
      return { liked: true }
    }
    await this.questionLikeRepo.create(userId, questionId)
    return { liked: true }
  }

  async unlike(userId: string, questionId: string): Promise<ToggleResult> {
    const existing = await this.questionLikeRepo.find(userId, questionId)
    if (!existing) {
      return { liked: false }
    }
    await this.questionLikeRepo.delete(userId, questionId)
    return { liked: false }
  }
}
