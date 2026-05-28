const USERNAME_PATTERN = /^[a-zA-Z0-9_]{3,20}$/

export const USERNAME_MAX_LENGTH = 20

export const USERNAME_VALIDATION_MESSAGE =
  'ユーザーコードは英数字と_のみ、3〜20文字です'

export function normalizeUsername(username: string): string {
  return username.trim().toLowerCase()
}

export function isValidUsername(username: string): boolean {
  return USERNAME_PATTERN.test(normalizeUsername(username))
}
