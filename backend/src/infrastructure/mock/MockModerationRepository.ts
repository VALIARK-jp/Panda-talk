import type { ContentReport, ReportTargetType } from '../../domain/entities/moderation'
import type { IModerationRepository } from '../../domain/repositories/IModerationRepository'

const reports: ContentReport[] = []
const blocks = new Map<string, Set<string>>()

export class MockModerationRepository implements IModerationRepository {
  async createReport(input: {
    reporterId: string
    targetType: ReportTargetType
    targetId: string
    reason: string
    detail?: string | null
  }): Promise<ContentReport> {
    const report: ContentReport = {
      id: crypto.randomUUID(),
      reporterId: input.reporterId,
      targetType: input.targetType,
      targetId: input.targetId,
      reason: input.reason,
      detail: input.detail ?? null,
      createdAt: new Date().toISOString(),
    }
    reports.push(report)
    return report
  }

  async blockUser(blockerId: string, blockedId: string): Promise<void> {
    const set = blocks.get(blockerId) ?? new Set<string>()
    set.add(blockedId)
    blocks.set(blockerId, set)
  }

  async unblockUser(blockerId: string, blockedId: string): Promise<void> {
    blocks.get(blockerId)?.delete(blockedId)
  }

  async listBlockedUserIds(blockerId: string): Promise<string[]> {
    return [...(blocks.get(blockerId) ?? [])]
  }
}
