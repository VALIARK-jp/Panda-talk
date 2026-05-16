import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';
import 'auth_providers.dart';

class ProfileController extends AsyncNotifier<DummyProfile> {
  @override
  Future<DummyProfile> build() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final provider =
          session.user.appMetadata['provider'] as String? ?? 'email';
      await ref.read(authServiceProvider).ensureBackendProfile(
            provider: provider,
          );
    }
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
