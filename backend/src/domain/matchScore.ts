export type AnswerChoice = 'a' | 'b'
export type AnswerMap = Map<string, AnswerChoice>

export type PairMatchScore = {
  commonAnswerCount: number
  sameAnswerCount: number
  matchRate: number
}

export function computePairMatchScore(
  mine: AnswerMap,
  theirs: AnswerMap,
  validQuestionIds?: ReadonlySet<string>
): PairMatchScore {
  let commonAnswerCount = 0
  let sameAnswerCount = 0

  for (const [questionId, myChoice] of mine) {
    if (validQuestionIds && !validQuestionIds.has(questionId)) continue
    const theirChoice = theirs.get(questionId)
    if (!theirChoice) continue
    commonAnswerCount += 1
    if (myChoice === theirChoice) sameAnswerCount += 1
  }

  return {
    commonAnswerCount,
    sameAnswerCount,
    matchRate:
      commonAnswerCount === 0 ? 0 : sameAnswerCount / commonAnswerCount,
  }
}

export function toDisplayScore(
  matchRate: number,
  commonAnswerCount: number
): number {
  return matchRate * (commonAnswerCount / (commonAnswerCount + 50))
}

export function toMatchRatePercent(matchRate: number): number {
  return matchRate <= 1 ? Math.round(matchRate * 100) : Math.round(matchRate)
}
