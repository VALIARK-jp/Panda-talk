import type { ContentReport, ReportTargetType } from '../../../domain/entities/moderation'
import type { IModerationRepository } from '../../../domain/repositories/IModerationRepository'
import { SupabaseRestClient } from '../SupabaseRestClient'

type ReportRow = {
  id: string
  reporter_id: string
  target_type: ReportTargetType
  target_id: string
  reason: string
  detail: string | null
  created_at: string
}

type BlockRow = {
  blocker_id: string
  blocked_id: string
  created_at: string
}

export class SupabaseModerationRepository implements IModerationRepository {
  constructor(private readonly client: SupabaseRestClient) {}

  private readonly reportsResource = 'panda_content_reports'
  private readonly blocksResource = 'panda_user_blocks'

  async createReport(input: {
    reporterId: string
    targetType: ReportTargetType
    targetId: string
    reason: string
    detail?: string | null
  }): Promise<ContentReport> {
    const rows = await this.client.insert<ReportRow>(this.reportsResource, {
      reporter_id: input.reporterId,
      target_type: input.targetType,
      target_id: input.targetId,
      reason: input.reason,
      detail: input.detail ?? null,
    })
    if (!rows[0]) throw new Error('Failed to create report')
    return mapReport(rows[0])
  }

  async blockUser(blockerId: string, blockedId: string): Promise<void> {
    const existing = await this.client.get<BlockRow[]>(this.blocksResource, {
      select: 'blocker_id',
      blocker_id: `eq.${blockerId}`,
      blocked_id: `eq.${blockedId}`,
      limit: 1,
    })
    if (existing[0]) return

    await this.client.insert<BlockRow>(this.blocksResource, {
      blocker_id: blockerId,
      blocked_id: blockedId,
    })
  }

  async unblockUser(blockerId: string, blockedId: string): Promise<void> {
    await this.client.delete(this.blocksResource, {
      blocker_id: `eq.${blockerId}`,
      blocked_id: `eq.${blockedId}`,
    })
  }

  async listBlockedUserIds(blockerId: string): Promise<string[]> {
    const rows = await this.client.get<BlockRow[]>(this.blocksResource, {
      select: 'blocked_id',
      blocker_id: `eq.${blockerId}`,
    })
    return rows.map((row) => row.blocked_id)
  }
}

function mapReport(row: ReportRow): ContentReport {
  return {
    id: row.id,
    reporterId: row.reporter_id,
    targetType: row.target_type,
    targetId: row.target_id,
    reason: row.reason,
    detail: row.detail,
    createdAt: row.created_at,
  }
}
