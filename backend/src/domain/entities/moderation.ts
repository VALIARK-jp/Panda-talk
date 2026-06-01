export type ReportTargetType = 'question' | 'user'

export interface ContentReport {
  id: string
  reporterId: string
  targetType: ReportTargetType
  targetId: string
  reason: string
  detail?: string | null
  createdAt: string
}

export const REPORT_REASONS = [
  'spam',
  'harassment',
  'inappropriate',
  'other',
] as const

export type ReportReason = (typeof REPORT_REASONS)[number]
