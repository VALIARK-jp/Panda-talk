import '../core/dummy_data.dart';

abstract class ProfileRepository {
  Future<DummyProfile> getProfile();
  Future<void> updateProfile({required String name, required String bio});
}
