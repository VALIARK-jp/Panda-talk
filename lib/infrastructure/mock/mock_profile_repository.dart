import '../../core/dummy_data.dart';
import '../profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  DummyProfile _profile = const DummyProfile(
    name: 'ぱんだちゃん',
    username: 'panda_123',
    bio: 'パンダが大好きです',
    avatarUrl: null,
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
  Future<DummyProfile> getUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return DummyProfile(
      name: 'ぱんだユーザー',
      username: userId,
      bio: 'よろしくお願いします',
      avatarUrl: null,
      answerCount: 42,
      postCount: 3,
      friendCount: 10,
      oddballScore: 18,
      tags: const ['夜型', '外出派'],
    );
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String bio,
    String? avatarUrl,
    String? username,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _profile = _profile.copyWith(
      name: name,
      bio: bio,
      avatarUrl: avatarUrl,
      username: username,
    );
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return username != 'taken';
  }

  @override
  Future<void> completeProfileSetup({
    required String name,
    required String username,
    required String bio,
    String? avatarUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _profile = DummyProfile(
      name: name,
      username: username,
      bio: bio,
      avatarUrl: avatarUrl ?? _profile.avatarUrl,
      answerCount: _profile.answerCount,
      postCount: _profile.postCount,
      friendCount: _profile.friendCount,
      oddballScore: _profile.oddballScore,
      tags: _profile.tags,
      pandaTypeSlug: _profile.pandaTypeSlug,
      typeAffectionPct: _profile.typeAffectionPct,
      typeThinkingPct: _profile.typeThinkingPct,
      typeActionPct: _profile.typeActionPct,
      typeLifePct: _profile.typeLifePct,
      diagnosed16At: _profile.diagnosed16At,
    );
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> savePandaType16({
    required String slug,
    required int affectionPct,
    required int thinkingPct,
    required int actionPct,
    required int lifePct,
    DateTime? diagnosedAt,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _profile = _profile.copyWith(
      pandaTypeSlug: slug,
      typeAffectionPct: affectionPct,
      typeThinkingPct: thinkingPct,
      typeActionPct: actionPct,
      typeLifePct: lifePct,
      diagnosed16At: diagnosedAt ?? DateTime.now(),
    );
  }
}
