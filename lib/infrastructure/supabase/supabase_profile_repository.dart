import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/dummy_data.dart';
import '../profile_repository.dart';

/// `panda_profiles` を Supabase から直接読む（実機でも `https://….supabase.co` のみで動く）。
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<DummyProfile> getProfile() async {
    final userId = _requireUserId();
    final row = await _client
        .from('panda_profiles')
        .select('id, email, username, name, avatar_url, bio')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      throw StateError('プロフィールがまだありません。一度ログインし直してください。');
    }

    final answerCount = await _count('panda_answers', 'user_id', userId);
    final postCount = await _count('panda_questions', 'user_id', userId);
    final friendCount = await _countFriendships(userId);

    return DummyProfile(
      name: row['name'] as String? ?? '名無しさん',
      username: row['username'] as String? ?? 'unknown',
      bio: row['bio'] as String? ?? '',
      avatarUrl: row['avatar_url'] as String?,
      answerCount: answerCount,
      postCount: postCount,
      friendCount: friendCount,
      oddballScore: 0,
      tags: const [],
    );
  }

  @override
  Future<void> updateProfile({required String name, required String bio}) async {
    final userId = _requireUserId();
    await _client
        .from('panda_profiles')
        .update({'name': name.trim(), 'bio': bio})
        .eq('id', userId);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final normalized = username.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(normalized)) {
      return false;
    }
    final userId = _requireUserId();
    final row = await _client
        .from('panda_profiles')
        .select('id')
        .eq('username', normalized)
        .maybeSingle();
    if (row == null) return true;
    return row['id'] == userId;
  }

  @override
  Future<void> completeProfileSetup({
    required String name,
    required String username,
    required String bio,
    String? avatarUrl,
  }) async {
    final userId = _requireUserId();
    await _client.from('panda_profiles').update({
      'name': name.trim(),
      'username': username.trim().toLowerCase(),
      'bio': bio.trim(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', userId);
  }

  Future<int> _count(String table, String column, String userId) async {
    try {
      final result = await _client
          .from(table)
          .count(CountOption.exact)
          .eq(column, userId);
      return result;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('SupabaseProfileRepository._count($table): $e\n$st');
      }
      return 0;
    }
  }

  Future<int> _countFriendships(String userId) async {
    try {
      final a = await _client
          .from('panda_friendships')
          .count(CountOption.exact)
          .eq('status', 'accepted')
          .eq('user_a_id', userId);
      final b = await _client
          .from('panda_friendships')
          .count(CountOption.exact)
          .eq('status', 'accepted')
          .eq('user_b_id', userId);
      return a + b;
    } catch (_) {
      return 0;
    }
  }

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('ログインしていません');
    }
    return id;
  }
}
