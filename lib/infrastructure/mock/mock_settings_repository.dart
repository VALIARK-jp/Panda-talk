import '../../core/dummy_data.dart';

class MockSettingsRepository {
  DummyNotificationSettings _settings = const DummyNotificationSettings(
    friendRequests: true,
    questionLikes: true,
    messages: true,
    groupUpdates: false,
  );

  DummyNotificationSettings getNotificationSettings() => _settings;

  void updateNotificationSettings(DummyNotificationSettings settings) {
    _settings = settings;
  }
}
