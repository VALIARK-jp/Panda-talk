import type { INotificationRepository } from '../../repositories/INotificationRepository'
import type { Notification } from '../../entities/index'

export class GetNotificationsUseCase {
  constructor(private notificationRepo: INotificationRepository) {}

  async execute(
    userId: string,
    limit: number,
    cursor?: string
  ): Promise<{ notifications: Notification[]; unreadCount: number }> {
    const [notifications, unreadCount] = await Promise.all([
      this.notificationRepo.findByUser(userId, limit, cursor),
      this.notificationRepo.countUnread(userId),
    ])
    return { notifications, unreadCount }
  }
}
