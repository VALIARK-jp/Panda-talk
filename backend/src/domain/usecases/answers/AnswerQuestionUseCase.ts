import type { IAnswerRepository } from '../../repositories/IAnswerRepository'
import type { IMatchRepository } from '../../repositories/IMatchRepository'
import type { IQuestionRepository } from '../../repositories/IQuestionRepository'
import type { Answer, AnswerChoice, QuestionStats } from '../../entities/index'

interface AnswerQuestionInput {
  userId: string
  questionId: string
  choice: AnswerChoice
}

interface AnswerQuestionResult {
  answer: Answer
  stats: QuestionStats
}

export class AnswerQuestionUseCase {
  constructor(
    private answerRepo: IAnswerRepository,
    private matchRepo: IMatchRepository,
    private questionRepo: IQuestionRepository
  ) {}

  async execute(input: AnswerQuestionInput): Promise<AnswerQuestionResult> {
    const existing = await this.answerRepo.findByUserAndQuestion(
      input.userId,
      input.questionId
    )
    if (existing) {
      throw Object.assign(new Error('Already answered'), { code: 'CONFLICT' })
    }

    const question = await this.questionRepo.findById(input.questionId)
    if (!question) {
      throw Object.assign(new Error('Question not found'), { code: 'NOT_FOUND' })
    }

    const answer = await this.answerRepo.create({
      userId: input.userId,
      questionId: input.questionId,
      choice: input.choice,
    })

    // Update match scores for all users who answered the same question
    const allAnswers = await this.answerRepo.findByQuestion(input.questionId)
    const otherAnswers = allAnswers.filter((a) => a.userId !== input.userId)

    await Promise.all(
      otherAnswers.map((otherAnswer) => {
        const isSame = otherAnswer.choice === input.choice
        const [aId, bId] =
          input.userId < otherAnswer.userId
            ? [input.userId, otherAnswer.userId]
            : [otherAnswer.userId, input.userId]
        return this.matchRepo.upsert(aId, bId, isSame)
      })
    )

    const stats = await this.questionRepo.getStats(input.questionId)

    return { answer, stats }
  }
}
