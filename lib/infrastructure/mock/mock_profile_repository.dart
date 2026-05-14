import '../../core/dummy_data.dart';
import '../profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  DummyProfile _profile = const DummyProfile(
    name: 'ぱんだちゃん',
    username: 'panda_123',
    bio: 'パンダが大好きです',
    answerCount: 128,
    postCount: 12,
    friendCount: 23,
    oddballScore: 26,
    tags: ['夜型', '外出派', '即レス派', '追う派', '計画派'],
  );

  @override
  Future<DummyProfile> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _profile;
  }

  @override
  Future<void> updateProfile({required String name, required String bio}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _profile = _profile.copyWith(name: name, bio: bio);
  }
}
