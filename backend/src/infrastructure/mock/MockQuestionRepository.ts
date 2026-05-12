import type {
  UUID,
  Question,
  QuestionWithUser,
  HotQuestion,
  QuestionStats,
} from '../../domain/entities/index'
import type { IQuestionRepository } from '../../domain/repositories/IQuestionRepository'

const users = [
  { id: 'user-1', username: 'alice', avatarUrl: null },
  { id: 'user-2', username: 'bob', avatarUrl: null },
  { id: 'user-3', username: 'carol', avatarUrl: null },
]

const questions: Question[] = [
  {
    id: 'question-1',
    userId: 'user-1',
    text: '朝食はどちら派？',
    optionA: 'ご飯',
    optionB: 'パン',
    category: 'lifestyle',
    createdAt: '2024-01-10T00:00:00.000Z',
  },
  {
    id: 'question-2',
    userId: 'user-2',
    text: '休日の過ごし方は？',
    optionA: 'インドア',
    optionB: 'アウトドア',
    category: 'lifestyle',
    createdAt: '2024-01-11T00:00:00.000Z',
  },
  {
    id: 'question-3',
    userId: 'user-3',
    text: '仕事のスタイルは？',
    optionA: 'リモート',
    optionB: '出社',
    category: 'work',
    createdAt: '2024-01-12T00:00:00.000Z',
  },
  {
    id: 'question-4',
    userId: 'user-1',
    text: '旅行するなら？',
    optionA: '国内',
    optionB: '海外',
    category: 'travel',
    createdAt: '2024-01-13T00:00:00.000Z',
  },
  {
    id: 'question-5',
    userId: 'user-2',
    text: 'ペットを飼うなら？',
    optionA: '犬',
    optionB: '猫',
    category: 'pets',
    createdAt: '2024-01-14T00:00:00.000Z',
  },
]

function toQuestionWithUser(q: Question): QuestionWithUser {
  const poster = users.find((u) => u.id === q.userId) ?? {
    id: q.userId,
    username: 'unknown',
    avatarUrl: null,
  }
  return { ...q, poster }
}

export class MockQuestionRepository implements IQuestionRepository {
  async getFeed(userId: UUID, limit: number, cursor?: UUID): Promise<QuestionWithUser[]> {
    let list = questions.map(toQuestionWithUser)
    if (cursor) {
      const idx = list.findIndex((q) => q.id === cursor)
      if (idx !== -1) list = list.slice(idx + 1)
    }
    return list.slice(0, limit)
  }

  async getHotFeed(limit: number, cursor?: UUID): Promise<HotQuestion[]> {
    let list: HotQuestion[] = questions.map((q) => ({
      ...toQuestionWithUser(q),
      likeCount: Math.floor(Math.random() * 50),
      commentCount: Math.floor(Math.random() * 20),
    }))
    list.sort((a, b) => b.likeCount - a.likeCount)
    if (cursor) {
      const idx = list.findIndex((q) => q.id === cursor)
      if (idx !== -1) list = list.slice(idx + 1)
    }
    return list.slice(0, limit)
  }

  async findById(id: UUID): Promise<QuestionWithUser | null> {
    const q = questions.find((q) => q.id === id)
    return q ? toQuestionWithUser(q) : null
  }

  async getStats(questionId: UUID): Promise<QuestionStats> {
    return {
      questionId,
      countA: 10,
      countB: 5,
    }
  }

  async search(keyword: string, limit: number): Promise<QuestionWithUser[]> {
    return questions
      .filter(
        (q) =>
          q.text.includes(keyword) ||
          q.optionA.includes(keyword) ||
          q.optionB.includes(keyword)
      )
      .map(toQuestionWithUser)
      .slice(0, limit)
  }

  async create(data: Omit<Question, 'id' | 'createdAt'>): Promise<Question> {
    const question: Question = {
      id: crypto.randomUUID(),
      ...data,
      createdAt: new Date().toISOString(),
    }
    questions.push(question)
    return question
  }

  async update(
    id: UUID,
    data: Partial<Pick<Question, 'text' | 'optionA' | 'optionB' | 'category'>>
  ): Promise<Question> {
    const idx = questions.findIndex((q) => q.id === id)
    if (idx === -1) throw new Error('Question not found')
    questions[idx] = { ...questions[idx], ...data }
    return questions[idx]
  }

  async delete(id: UUID): Promise<void> {
    const idx = questions.findIndex((q) => q.id === id)
    if (idx !== -1) questions.splice(idx, 1)
  }
}
