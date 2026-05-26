import type {
  UUID,
  Question,
  QuestionWithUser,
  HotQuestion,
  QuestionStats,
  AnsweredQuestion,
  FeedWindowQuestion,
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
    questionNumber: 1,
    userId: 'user-1',
    text: '朝食はどちら派？',
    optionA: 'ご飯',
    optionB: 'パン',
    category: 'lifestyle',
    createdAt: '2024-01-10T00:00:00.000Z',
  },
  {
    id: 'question-2',
    questionNumber: 2,
    userId: 'user-2',
    text: '休日の過ごし方は？',
    optionA: 'インドア',
    optionB: 'アウトドア',
    category: 'lifestyle',
    createdAt: '2024-01-11T00:00:00.000Z',
  },
  {
    id: 'question-3',
    questionNumber: 3,
    userId: 'user-3',
    text: '仕事のスタイルは？',
    optionA: 'リモート',
    optionB: '出社',
    category: 'work',
    createdAt: '2024-01-12T00:00:00.000Z',
  },
  {
    id: 'question-4',
    questionNumber: 4,
    userId: 'user-1',
    text: '旅行するなら？',
    optionA: '国内',
    optionB: '海外',
    category: 'travel',
    createdAt: '2024-01-13T00:00:00.000Z',
  },
  {
    id: 'question-5',
    questionNumber: 5,
    userId: 'user-2',
    text: 'ペットを飼うなら？',
    optionA: '犬',
    optionB: '猫',
    category: 'pets',
    createdAt: '2024-01-14T00:00:00.000Z',
  },
]

function toQuestionWithUser(
  q: Question,
  engagement?: { likeCount: number; commentCount: number }
): QuestionWithUser {
  const poster = users.find((u) => u.id === q.userId) ?? {
    id: q.userId,
    username: 'unknown',
    avatarUrl: null,
  }
  return {
    ...q,
    poster: {
      id: poster.id,
      username: poster.username,
      name: poster.username,
      avatarUrl: poster.avatarUrl,
    },
    likeCount: engagement?.likeCount ?? 0,
    commentCount: engagement?.commentCount ?? 0,
  }
}

export class MockQuestionRepository implements IQuestionRepository {
  async getDiagnosis16(_userId?: UUID): Promise<QuestionWithUser[]> {
    return questions
      .filter((q) => q.questionNumber >= 1 && q.questionNumber <= 16)
      .sort((a, b) => a.questionNumber - b.questionNumber)
      .map((q, index) =>
        toQuestionWithUser(q, {
          likeCount: (index + 1) * 2,
          commentCount: index,
        })
      )
  }

  async getFeedWindow(
    _userId: UUID,
    before: number,
    after: number,
    maxQuestionNumber?: number
  ): Promise<FeedWindowQuestion[]> {
    const sorted = [...questions].sort((a, b) => a.questionNumber - b.questionNumber)
    if (maxQuestionNumber != null && maxQuestionNumber > 0) {
      const inRange = sorted.filter(
        (q) => q.questionNumber >= 1 && q.questionNumber <= maxQuestionNumber
      )
      return inRange.map((q, index) =>
        toQuestionWithUser(q, { likeCount: index, commentCount: index })
      )
    }
    const frontier = sorted[0]?.questionNumber ?? 1
    const minNum = Math.max(1, frontier - before)
    const maxNum = frontier + after
    return sorted
      .filter((q) => q.questionNumber >= minNum && q.questionNumber <= maxNum)
      .map((q, index) => toQuestionWithUser(q, { likeCount: index, commentCount: index }))
  }

  async getFeedWindowAround(
    _userId: UUID,
    before: number,
    after: number,
    target: { questionId?: UUID; questionNumber?: number }
  ): Promise<FeedWindowQuestion[]> {
    const sorted = [...questions].sort((a, b) => a.questionNumber - b.questionNumber)
    let targetNumber = target.questionNumber
    if ((targetNumber == null || targetNumber < 1) && target.questionId) {
      targetNumber = sorted.find((q) => q.id === target.questionId)?.questionNumber
    }
    if (targetNumber == null || targetNumber < 1) {
      return this.getFeedWindow(_userId, before, after)
    }
    const minNum = Math.max(1, targetNumber - before)
    const maxNum = targetNumber + after
    return sorted
      .filter((q) => q.questionNumber >= minNum && q.questionNumber <= maxNum)
      .map((q, index) => toQuestionWithUser(q, { likeCount: index, commentCount: index }))
  }

  async getFeed(userId: UUID, limit: number, cursor?: UUID): Promise<QuestionWithUser[]> {
    let list = questions.map((q, index) =>
      toQuestionWithUser(q, {
        likeCount: (index + 1) * 3,
        commentCount: index + 2,
      })
    )
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

  async getAnsweredHistory(
    userId: UUID,
    limit: number,
    cursor?: UUID
  ): Promise<AnsweredQuestion[]> {
    let list: AnsweredQuestion[] = questions.map((q, index) => ({
      ...toQuestionWithUser(q),
      myAnswer: index % 2 === 0 ? q.optionA : q.optionB,
    }))
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
      .map((q) => toQuestionWithUser(q))
      .slice(0, limit)
  }

  async create(data: Omit<Question, 'id' | 'questionNumber' | 'createdAt'>): Promise<Question> {
    const nextQuestionNumber =
      questions.length === 0
        ? 1
        : Math.max(...questions.map((question) => question.questionNumber)) + 1
    const question: Question = {
      id: crypto.randomUUID(),
      questionNumber: nextQuestionNumber,
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
    const target = questions.find((q) => q.id === id)
    if (!target) return
    const deletedNumber = target.questionNumber
    const idx = questions.findIndex((q) => q.id === id)
    questions.splice(idx, 1)
    for (const q of questions) {
      if (q.questionNumber > deletedNumber) {
        q.questionNumber -= 1
      }
    }
  }
}
