import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/dummy_data.dart';
import '../../core/oddball_distribution.dart';
import '../../core/username_rules.dart';
import '../profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static String get _apiBaseUrl => AppConfig.apiBaseUrl;
  static String get _supabaseUrl => AppConfig.supabaseUrl;
  static String get _supabaseAnonKey => AppConfig.supabaseAnonKey;
  static const _devEmail = String.fromEnvironment(
    'PANDA_TALK_DEV_EMAIL',
    defaultValue: '',
  );
  static const _devPassword = String.fromEnvironment(
    'PANDA_TALK_DEV_PASSWORD',
    defaultValue: '',
  );

  String? _accessToken;

  @override
  Future<DummyProfile> getProfile() async {
    final data = await _getJson(Uri.parse('$_apiBaseUrl/users/me'), auth: true);
    return _profileFromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<DummyProfile> getUserProfile(String userId) async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/users/$userId'),
      auth: true,
    );
    return _profileFromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<OddballScoreDistribution> getOddballDistribution({
    required int score,
  }) async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/users/oddball-distribution?score=$score'),
    );
    final bins = (data['bins'] as List<dynamic>? ?? const [])
        .map(
          (raw) => OddballDistributionBin(
            start: (raw['start'] as num?)?.toInt() ?? 0,
            end: (raw['end'] as num?)?.toInt() ?? 0,
            count: (raw['count'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
    return OddballScoreDistribution(
      score: (data['score'] as num?)?.toInt() ?? score,
      totalUsers: (data['totalUsers'] as num?)?.toInt() ?? 0,
      percentile: (data['percentile'] as num?)?.toInt() ?? 0,
      bins: bins,
    );
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String bio,
    String? avatarUrl,
    String? username,
  }) async {
    await _patchJson(
      Uri.parse('$_apiBaseUrl/users/me'),
      body: {
        'name': name,
        'bio': bio,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (username != null) 'username': username,
      },
      auth: true,
    );
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final normalized = username.trim().toLowerCase();
    if (!_isValidUsername(normalized)) return false;
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/users/search?q=$normalized&limit=5'),
      auth: true,
    );
    final users = (data['users'] as List<dynamic>?) ?? const [];
    final userId = Supabase.instance.client.auth.currentUser?.id;
    for (final raw in users) {
      final map = raw as Map<String, dynamic>;
      if ((map['username'] as String?)?.toLowerCase() == normalized &&
          map['id'] != userId) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> completeProfileSetup({
    required String name,
    required String username,
    required String bio,
    String? avatarUrl,
  }) async {
    await _patchJson(
      Uri.parse('$_apiBaseUrl/users/me'),
      body: {
        'name': name.trim(),
        'username': username.trim().toLowerCase(),
        'bio': bio.trim(),
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
      auth: true,
    );
  }

  bool _isValidUsername(String username) {
    return UsernameRules.isValid(username);
  }

  @override
  Future<void> deleteAccount() async {
    final response = await _client.delete(
      Uri.parse('$_apiBaseUrl/users/me'),
      headers: await _headers(auth: true),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw StateError(
        response.body.isNotEmpty
            ? response.body
            : 'アカウント削除に失敗しました (${response.statusCode})',
      );
    }
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
    await _patchJson(
      Uri.parse('$_apiBaseUrl/users/me'),
      body: {
        'pandaTypeSlug': slug,
        'typeAffectionPct': affectionPct,
        'typeThinkingPct': thinkingPct,
        'typeActionPct': actionPct,
        'typeLifePct': lifePct,
        'diagnosed16At': (diagnosedAt ?? DateTime.now())
            .toUtc()
            .toIso8601String(),
      },
      auth: true,
    );
  }

  DummyProfile _profileFromJson(Map<String, dynamic> json) {
    return DummyProfile(
      name: json['name'] as String? ?? '名無しさん',
      username: json['username'] as String? ?? 'unknown',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      answerCount: json['answerCount'] as int? ?? 0,
      postCount: json['postCount'] as int? ?? 0,
      friendCount: json['friendCount'] as int? ?? 0,
      oddballScore: (json['oddballScore'] as num? ?? 0).toInt(),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      pandaTypeSlug: json['pandaTypeSlug'] as String?,
      typeAffectionPct: (json['typeAffectionPct'] as num?)?.toInt(),
      typeThinkingPct: (json['typeThinkingPct'] as num?)?.toInt(),
      typeActionPct: (json['typeActionPct'] as num?)?.toInt(),
      typeLifePct: (json['typeLifePct'] as num?)?.toInt(),
      diagnosed16At: json['diagnosed16At'] != null
          ? DateTime.tryParse(json['diagnosed16At'] as String)
          : null,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, {bool auth = false}) async {
    final response = await _client.get(
      uri,
      headers: await _headers(auth: auth),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _patchJson(
    Uri uri, {
    required Map<String, Object?> body,
    bool auth = false,
  }) async {
    final response = await _client.patch(
      uri,
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      headers['Authorization'] = 'Bearer ${await _getAccessToken()}';
    }
    return headers;
  }

  Future<String> _getAccessToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) return session.accessToken;

    if (_accessToken != null) return _accessToken!;

    if (_devEmail.isEmpty || _devPassword.isEmpty) {
      throw StateError(
        "Authentication required. Set PANDA_TALK_DEV_EMAIL and PANDA_TALK_DEV_PASSWORD only for mock/dev fallback.",
      );
    }

    final response = await _client.post(
      Uri.parse('$_supabaseUrl/auth/v1/token?grant_type=password'),
      headers: {'apikey': _supabaseAnonKey, 'Content-Type': 'application/json'},
      body: jsonEncode({'email': _devEmail, 'password': _devPassword}),
    );

    final data = _decode(response);
    _accessToken = data['access_token'] as String;
    return _accessToken!;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(response.body);
    }
    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
