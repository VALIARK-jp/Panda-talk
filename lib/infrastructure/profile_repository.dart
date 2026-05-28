import '../core/dummy_data.dart';
import '../core/oddball_distribution.dart';

abstract class ProfileRepository {
  Future<DummyProfile> getProfile();
  Future<DummyProfile> getUserProfile(String userId);
  Future<OddballScoreDistribution> getOddballDistribution({required int score});
  Future<void> updateProfile({
    required String name,
    required String bio,
    String? avatarUrl,
    String? username,
  });
  Future<bool> isUsernameAvailable(String username);
  Future<void> completeProfileSetup({
    required String name,
    required String username,
    required String bio,
    String? avatarUrl,
  });

  Future<void> deleteAccount();

  Future<void> savePandaType16({
    required String slug,
    required int affectionPct,
    required int thinkingPct,
    required int actionPct,
    required int lifePct,
    DateTime? diagnosedAt,
  });
}
