import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';

class ProfileController extends AsyncNotifier<DummyProfile> {
  @override
  Future<DummyProfile> build() {
    return ref.read(profileRepositoryProvider).getProfile();
  }

  Future<void> updateProfile({required String name, required String bio}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).updateProfile(name: name, bio: bio);
      return ref.read(profileRepositoryProvider).getProfile();
    });
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, DummyProfile>(ProfileController.new);
