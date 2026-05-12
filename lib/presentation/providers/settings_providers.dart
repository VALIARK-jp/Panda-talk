import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';

class SettingsController extends StateNotifier<DummyNotificationSettings> {
  SettingsController(this._ref)
    : super(_ref.read(settingsRepositoryProvider).getNotificationSettings());

  final Ref _ref;

  void updateFriendRequests(bool value) {
    _update(state.copyWith(friendRequests: value));
  }

  void updateQuestionLikes(bool value) {
    _update(state.copyWith(questionLikes: value));
  }

  void updateMessages(bool value) {
    _update(state.copyWith(messages: value));
  }

  void updateGroupUpdates(bool value) {
    _update(state.copyWith(groupUpdates: value));
  }

  void _update(DummyNotificationSettings settings) {
    _ref.read(settingsRepositoryProvider).updateNotificationSettings(settings);
    state = settings;
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, DummyNotificationSettings>((ref) {
      return SettingsController(ref);
    });
