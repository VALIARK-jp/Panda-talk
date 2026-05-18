import '../core/dummy_data.dart';

abstract class ProfileRepository {
  Future<DummyProfile> getProfile();
  Future<void> updateProfile({required String name, required String bio});
  Future<bool> isUsernameAvailable(String username);
  Future<void> completeProfileSetup({
    required String name,
    required String username,
    required String bio,
    String? avatarUrl,
  });
}
