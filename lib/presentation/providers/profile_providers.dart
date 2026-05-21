import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';

class ProfileController extends AsyncNotifier<DummyProfile> {
  @override
  Future<DummyProfile> build() async {
    // ensureBackendProfile はログイン時のみ（main / post_auth）。ここで毎回呼ぶと
    // 編集した名前が OAuth の表示名で上書きされる。
    return ref.read(profileRepositoryProvider).getProfile();
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    String? avatarUrl,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).updateProfile(
            name: name,
            bio: bio,
            avatarUrl: avatarUrl,
          );
      return ref.read(profileRepositoryProvider).getProfile();
    });
  }

  Future<bool> isUsernameAvailable(String username) {
    return ref.read(profileRepositoryProvider).isUsernameAvailable(username);
  }

  Future<void> completeProfileSetup({
    required String name,
    required String username,
    required String bio,
    String? avatarUrl,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).completeProfileSetup(
        name: name,
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
      );
      return ref.read(profileRepositoryProvider).getProfile();
    });
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, DummyProfile>(ProfileController.new);
