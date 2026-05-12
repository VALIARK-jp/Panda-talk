import type { INotificationRepository } from '../../repositories/INotificationRepository'

export class MarkAsReadUseCase {
  constructor(private notificationRepo: INotificationRepository) {}

  async markAll(userId: string): Promise<void> {
    await this.notificationRepo.markAllAsRead(userId)
  }

  async markOne(notificationId: string): Promise<void> {
    await this.notificationRepo.markAsRead(notificationId)
  }
}
