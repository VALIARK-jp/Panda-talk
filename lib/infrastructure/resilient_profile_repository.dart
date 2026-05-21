import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../core/dummy_data.dart';
import 'api/api_profile_repository.dart';
import 'profile_repository.dart';
import 'supabase/supabase_profile_repository.dart';

/// API を優先し、ローカル Worker へ届かないときだけ Supabase 直更新する。
class ResilientProfileRepository implements ProfileRepository {
  ResilientProfileRepository({
    ApiProfileRepository? api,
    SupabaseProfileRepository? supabase,
  })  : _api = api ?? ApiProfileRepository(),
        _supabase = supabase ?? SupabaseProfileRepository();

  final ApiProfileRepository _api;
  final SupabaseProfileRepository _supabase;

  @override
  Future<DummyProfile> getProfile() => _withFallback(
        () => _api.getProfile(),
        () => _supabase.getProfile(),
      );

  @override
  Future<DummyProfile> getUserProfile(String userId) => _withFallback(
        () => _api.getUserProfile(userId),
        () => _supabase.getUserProfile(userId),
      );

  @override
  Future<void> updateProfile({
    required String name,
    required String bio,
    String? avatarUrl,
  }) =>
      _withFallbackVoid(
        () => _api.updateProfile(
          name: name,
          bio: bio,
          avatarUrl: avatarUrl,
        ),
        () => _supabase.updateProfile(
          name: name,
          bio: bio,
          avatarUrl: avatarUrl,
        ),
      );

  @override
  Future<bool> isUsernameAvailable(String username) => _withFallback(
        () => _api.isUsernameAvailable(username),
        () => _supabase.isUsernameAvailable(username),
      );

  @override
  Future<void> completeProfileSetup({
    required String name,
    required String username,
    required String bio,
    String? avatarUrl,
  }) =>
      _withFallbackVoid(
        () => _api.completeProfileSetup(
          name: name,
          username: username,
          bio: bio,
          avatarUrl: avatarUrl,
        ),
        () => _supabase.completeProfileSetup(
          name: name,
          username: username,
          bio: bio,
          avatarUrl: avatarUrl,
        ),
      );

  @override
  Future<void> savePandaType16({
    required String slug,
    required int affectionPct,
    required int thinkingPct,
    required int actionPct,
    required int lifePct,
    DateTime? diagnosedAt,
  }) =>
      _withFallbackVoid(
        () => _api.savePandaType16(
          slug: slug,
          affectionPct: affectionPct,
          thinkingPct: thinkingPct,
          actionPct: actionPct,
          lifePct: lifePct,
          diagnosedAt: diagnosedAt,
        ),
        () => _supabase.savePandaType16(
          slug: slug,
          affectionPct: affectionPct,
          thinkingPct: thinkingPct,
          actionPct: actionPct,
          lifePct: lifePct,
          diagnosedAt: diagnosedAt,
        ),
      );

  Future<T> _withFallback<T>(
    Future<T> Function() apiCall,
    Future<T> Function() supabaseCall,
  ) async {
    try {
      return await apiCall();
    } catch (e) {
      if (AppConfig.usesLocalApiHost && _isConnectionError(e)) {
        if (kDebugMode) {
          debugPrint('ResilientProfileRepository: API failed, using Supabase: $e');
        }
        return await supabaseCall();
      }
      rethrow;
    }
  }

  Future<void> _withFallbackVoid(
    Future<void> Function() apiCall,
    Future<void> Function() supabaseCall,
  ) async {
    await _withFallback(
      () async {
        await apiCall();
        return null;
      },
      () async {
        await supabaseCall();
        return null;
      },
    );
  }

  bool _isConnectionError(Object e) {
    final msg = e.toString();
    return msg.contains('Connection refused') ||
        msg.contains('Failed host lookup') ||
        msg.contains('SocketException') ||
        msg.contains('ClientException');
  }
}
