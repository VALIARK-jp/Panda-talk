import type { UUID, Notification } from '../../domain/entities/index'
import type { INotificationRepository } from '../../domain/repositories/INotificationRepository'

const notifications: Notification[] = []

export class MockNotificationRepository implements INotificationRepository {
  async findByUser(userId: UUID, limit: number, cursor?: UUID): Promise<Notification[]> {
    let list = notifications.filter((n) => n.userId === userId)
    list.sort((a, b) => b.createdAt.localeCompare(a.createdAt))
    if (cursor) {
      const idx = list.findIndex((n) => n.id === cursor)
      if (idx !== -1) list = list.slice(idx + 1)
    }
    return list.slice(0, limit)
  }

  async countUnread(userId: UUID): Promise<number> {
    return notifications.filter((n) => n.userId === userId && !n.isRead).length
  }

  async markAllAsRead(userId: UUID): Promise<void> {
    notifications
      .filter((n) => n.userId === userId)
      .forEach((n) => {
        n.isRead = true
      })
  }

  async markAsRead(notificationId: UUID): Promise<void> {
    const n = notifications.find((n) => n.id === notificationId)
    if (n) n.isRead = true
  }

  async create(data: Omit<Notification, 'id' | 'isRead' | 'createdAt'>): Promise<Notification> {
    const notification: Notification = {
      id: crypto.randomUUID(),
      ...data,
      isRead: false,
      createdAt: new Date().toISOString(),
    }
    notifications.push(notification)
    return notification
  }
}
