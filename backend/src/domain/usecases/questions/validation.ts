export const QUESTION_TEXT_MAX_LENGTH = 100

function badRequest(message: string): Error & { code: string } {
  return Object.assign(new Error(message), { code: 'BAD_REQUEST' })
}

export function validateQuestionText(text: unknown): string {
  if (typeof text !== 'string') {
    throw badRequest('Question text is required')
  }

  const trimmed = text.trim()
  if (!trimmed) {
    throw badRequest('Question text is required')
  }

  if (Array.from(trimmed).length > QUESTION_TEXT_MAX_LENGTH) {
    throw badRequest(`Question text must be ${QUESTION_TEXT_MAX_LENGTH} characters or fewer`)
  }

  return trimmed
}
