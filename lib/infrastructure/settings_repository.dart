import '../core/dummy_data.dart';

abstract class SettingsRepository {
  Future<DummyNotificationSettings> getNotificationSettings();
  Future<void> updateNotificationSettings(DummyNotificationSettings settings);
}
