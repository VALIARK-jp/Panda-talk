import type { ContentReport, ReportTargetType } from '../entities/moderation'

export interface IModerationRepository {
  createReport(input: {
    reporterId: string
    targetType: ReportTargetType
    targetId: string
    reason: string
    detail?: string | null
  }): Promise<ContentReport>

  blockUser(blockerId: string, blockedId: string): Promise<void>
  unblockUser(blockerId: string, blockedId: string): Promise<void>
  listBlockedUserIds(blockerId: string): Promise<string[]>
}
