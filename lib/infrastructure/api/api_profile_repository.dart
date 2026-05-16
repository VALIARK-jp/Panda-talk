import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/dummy_data.dart';
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
    defaultValue: 'alice.dev@panda-talk.local',
  );
  static const _devPassword = String.fromEnvironment(
    'PANDA_TALK_DEV_PASSWORD',
    defaultValue: 'PandaTalk_dev_2026!',
  );

  String? _accessToken;

  @override
  Future<DummyProfile> getProfile() async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/users/me'),
      auth: true,
    );
    return _profileFromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> updateProfile({required String name, required String bio}) async {
    await _patchJson(
      Uri.parse('$_apiBaseUrl/users/me'),
      body: {
        'name': name,
        'bio': bio,
      },
      auth: true,
    );
  }

  DummyProfile _profileFromJson(Map<String, dynamic> json) {
    return DummyProfile(
      name: json['name'] as String? ?? '名無しさん',
      username: json['username'] as String? ?? 'unknown',
      bio: json['bio'] as String? ?? '',
      answerCount: json['answerCount'] as int? ?? 0,
      postCount: json['postCount'] as int? ?? 0,
      friendCount: json['friendCount'] as int? ?? 0,
      oddballScore: (json['oddballScore'] as num? ?? 0).toInt(),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
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
