import '../settings_repository.dart';
import '../../core/dummy_data.dart';

class MockSettingsRepository implements SettingsRepository {
  DummyNotificationSettings _settings = const DummyNotificationSettings(
    friendRequests: true,
    questionLikes: true,
    messages: true,
    groupUpdates: false,
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
}
