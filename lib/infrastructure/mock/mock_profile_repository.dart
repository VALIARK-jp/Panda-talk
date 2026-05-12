import '../../core/dummy_data.dart';

class MockProfileRepository {
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

  DummyProfile getProfile() => _profile;

  void updateProfile({required String name, required String bio}) {
    _profile = _profile.copyWith(name: name, bio: bio);
  }
}
