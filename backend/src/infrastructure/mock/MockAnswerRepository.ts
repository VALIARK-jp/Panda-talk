import type { UUID, Answer } from '../../domain/entities/index'
import type { IAnswerRepository } from '../../domain/repositories/IAnswerRepository'

const answers: Answer[] = [
  {
    id: 'answer-1',
    userId: 'user-1',
    questionId: 'question-1',
    choice: 'a',
    createdAt: '2024-01-15T00:00:00.000Z',
  },
  {
    id: 'answer-2',
    userId: 'user-2',
    questionId: 'question-1',
    choice: 'b',
    createdAt: '2024-01-15T01:00:00.000Z',
  },
  {
    id: 'answer-3',
    userId: 'user-1',
    questionId: 'question-2',
    choice: 'a',
    createdAt: '2024-01-15T02:00:00.000Z',
  },
  {
    id: 'answer-4',
    userId: 'user-3',
    questionId: 'question-2',
    choice: 'a',
    createdAt: '2024-01-15T03:00:00.000Z',
  },
  {
    id: 'answer-5',
    userId: 'user-2',
    questionId: 'question-3',
    choice: 'b',
    createdAt: '2024-01-15T04:00:00.000Z',
  },
]

export class MockAnswerRepository implements IAnswerRepository {
  async findByUserAndQuestion(userId: UUID, questionId: UUID): Promise<Answer | null> {
    return answers.find((a) => a.userId === userId && a.questionId === questionId) ?? null
  }

  async findByQuestion(questionId: UUID): Promise<Answer[]> {
    return answers.filter((a) => a.questionId === questionId)
  }

  async findByUser(userId: UUID, limit: number, cursor?: UUID): Promise<Answer[]> {
    let list = answers.filter((a) => a.userId === userId)
    if (cursor) {
      const idx = list.findIndex((a) => a.id === cursor)
      if (idx !== -1) list = list.slice(idx + 1)
    }
    return list.slice(0, limit)
  }

  async create(data: Omit<Answer, 'id' | 'createdAt'>): Promise<Answer> {
    const answer: Answer = {
      id: crypto.randomUUID(),
      ...data,
      createdAt: new Date().toISOString(),
    }
    answers.push(answer)
    return answer
  }
}
