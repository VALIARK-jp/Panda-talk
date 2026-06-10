import type { UUID, Notification, NotificationType } from '../../../domain/entities/index'
import type { INotificationRepository } from '../../../domain/repositories/INotificationRepository'
import type { FirebasePushNotifier } from '../../push/FirebasePushNotifier'
import { SupabaseRestClient } from '../SupabaseRestClient'

type NotificationRow = {
  id: string
  user_id: string
  actor_id: string | null
  type: string
  target_id: string | null
  is_read: boolean
  created_at: string
}

export class SupabaseNotificationRepository implements INotificationRepository {
  constructor(
    private readonly client: SupabaseRestClient,
    private readonly pushNotifier?: FirebasePushNotifier
  ) {}

  private readonly resource = 'panda_notifications'

  async findByUser(userId: UUID, limit: number, cursor?: UUID): Promise<Notification[]> {
    const query: any = {
      select: '*',
      user_id: `eq.${userId}`,
      order: 'created_at.desc',
      limit,
    }
    const rows = await this.client.get<NotificationRow[]>(this.resource, query)
    return rows.map(mapNotification)
  }

  async countUnread(userId: UUID): Promise<number> {
    return this.client.count(this.resource, {
      user_id: `eq.${userId}`,
      is_read: 'eq.false',
    })
  }

  async markAllAsRead(userId: UUID): Promise<void> {
    await this.client.update(
      this.resource,
      { user_id: `eq.${userId}`, is_read: 'eq.false' },
      { is_read: true }
    )
  }

  async markAsRead(notificationId: UUID): Promise<void> {
    await this.client.update(
      this.resource,
      { id: `eq.${notificationId}` },
      { is_read: true }
    )
  }

  async create(data: Omit<Notification, 'id' | 'isRead' | 'createdAt'>): Promise<Notification> {
    const rows = await this.client.insert<NotificationRow>(this.resource, {
      user_id: data.userId,
      actor_id: data.actorId,
      type: data.type,
      target_id: data.targetId,
      is_read: false,
    })
    if (!rows[0]) throw new Error('Failed to create notification')
    const notification = mapNotification(rows[0])
    if (this.pushNotifier) {
      try {
        await this.pushNotifier.notify(notification)
      } catch (err) {
        console.warn('push notify failed:', err)
      }
    }
    return notification
  }
}

function mapNotification(row: NotificationRow): Notification {
  return {
    id: row.id,
    userId: row.user_id,
    actorId: row.actor_id,
    type: row.type as NotificationType,
    targetId: row.target_id,
    isRead: row.is_read,
    createdAt: row.created_at,
  }
}
