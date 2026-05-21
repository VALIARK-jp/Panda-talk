import type { AnswerChoice } from './entities/index'

/** 異端児スコア用の少数派判定（`panda_user_oddball_scores` ビューと同一）。 */
export function isMinorityChoice(
  choice: AnswerChoice,
  countA: number,
  countB: number
): boolean {
  const total = countA + countB
  if (total <= 1) return false
  if (countA === countB) return false
  if (choice === 'a') return countA < countB
  return countB < countA
}

export function oddballScorePercent(
  minorityAnswerCount: number,
  totalAnswerCount: number
): number {
  if (totalAnswerCount <= 0) return 0
  return Math.round((minorityAnswerCount / totalAnswerCount) * 100)
}
