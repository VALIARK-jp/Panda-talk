import type { IQuestionLikeRepository } from '../../repositories/IQuestionLikeRepository'

interface ToggleResult {
  liked: boolean
}

export class ToggleQuestionLikeUseCase {
  constructor(private questionLikeRepo: IQuestionLikeRepository) {}

  async like(userId: string, questionId: string): Promise<ToggleResult> {
    const existing = await this.questionLikeRepo.find(userId, questionId)
    if (existing) {
      throw Object.assign(new Error('Already liked'), { code: 'CONFLICT' })
    }
    await this.questionLikeRepo.create(userId, questionId)
    return { liked: true }
  }

  async unlike(userId: string, questionId: string): Promise<ToggleResult> {
    await this.questionLikeRepo.delete(userId, questionId)
    return { liked: false }
  }
}
