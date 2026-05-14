import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';

import 'dart:async';

class SettingsController extends AsyncNotifier<DummyNotificationSettings> {
  @override
  FutureOr<DummyNotificationSettings> build() {
    return ref.read(settingsRepositoryProvider).getNotificationSettings();
  }

  Future<void> updateFriendRequests(bool value) async {
    final newSettings = state.value!.copyWith(friendRequests: value);
    await _update(newSettings);
  }

  Future<void> updateQuestionLikes(bool value) async {
    final newSettings = state.value!.copyWith(questionLikes: value);
    await _update(newSettings);
  }

  Future<void> updateMessages(bool value) async {
    final newSettings = state.value!.copyWith(messages: value);
    await _update(newSettings);
  }

  Future<void> updateGroupUpdates(bool value) async {
    final newSettings = state.value!.copyWith(groupUpdates: value);
    await _update(newSettings);
  }

  Future<void> _update(DummyNotificationSettings settings) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(settingsRepositoryProvider)
          .updateNotificationSettings(settings);
      return settings;
    });
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, DummyNotificationSettings>(() {
  return SettingsController();
});
