import '../settings_repository.dart';
import '../../core/dummy_data.dart';

class MockSettingsRepository implements SettingsRepository {
  DummyNotificationSettings _settings = const DummyNotificationSettings(
    likesEnabled: true,
    commentsEnabled: true,
    friendRequestsEnabled: true,
    friendAcceptedEnabled: true,
  );

  @override
  Future<DummyNotificationSettings> getNotificationSettings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _settings;
  }

  @override
  Future<void> updateNotificationSettings(DummyNotificationSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _settings = settings;
  }

  @override
  Future<void> sendTestNotification() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
