import type { UUID, Notification } from '../entities/index'

export interface INotificationRepository {
  findByUser(userId: UUID, limit: number, cursor?: UUID): Promise<Notification[]>
  countUnread(userId: UUID): Promise<number>
  markAllAsRead(userId: UUID): Promise<void>
  markAsRead(notificationId: UUID): Promise<void>
  create(data: Omit<Notification, 'id' | 'isRead' | 'createdAt'>): Promise<Notification>
}
