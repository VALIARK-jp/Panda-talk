import {
  REPORT_REASONS,
  type ReportReason,
  type ReportTargetType,
} from '../../entities/moderation'
import type { IModerationRepository } from '../../repositories/IModerationRepository'

interface ReportInput {
  reporterId: string
  targetType: ReportTargetType
  targetId: string
  reason: string
  detail?: string | null
}

export class ReportContentUseCase {
  constructor(private moderationRepo: IModerationRepository) {}

  async execute(input: ReportInput) {
    const targetId = input.targetId.trim()
    if (!targetId) {
      const err = new Error('targetId is required') as Error & { code?: string }
      err.code = 'BAD_REQUEST'
      throw err
    }

    if (input.targetType !== 'question' && input.targetType !== 'user') {
      const err = new Error('Invalid targetType') as Error & { code?: string }
      err.code = 'BAD_REQUEST'
      throw err
    }

    if (!REPORT_REASONS.includes(input.reason as ReportReason)) {
      const err = new Error('Invalid reason') as Error & { code?: string }
      err.code = 'BAD_REQUEST'
      throw err
    }

    const report = await this.moderationRepo.createReport({
      reporterId: input.reporterId,
      targetType: input.targetType,
      targetId,
      reason: input.reason,
      detail: input.detail?.trim() || null,
    })

    return { report }
  }
}
