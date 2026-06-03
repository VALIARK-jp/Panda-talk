import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../moderation_repository.dart';

class ApiModerationRepository implements ModerationRepository {
  ApiModerationRepository({http.Client? client})
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
  Future<void> reportContent({
    required ReportTargetType targetType,
    required String targetId,
    required ContentReportReason reason,
    String? detail,
  }) async {
    await _postJson(
      Uri.parse('$_apiBaseUrl/moderation/reports'),
      body: {
        'targetType': targetType.name,
        'targetId': targetId,
        'reason': reason.apiValue,
        if (detail != null && detail.trim().isNotEmpty) 'detail': detail.trim(),
      },
      auth: true,
    );
  }

  @override
  Future<void> blockUser(String userId) async {
    await _postJson(
      Uri.parse('$_apiBaseUrl/users/$userId/block'),
      body: {},
      auth: true,
    );
  }

  @override
  Future<void> unblockUser(String userId) async {
    final response = await _client.delete(
      Uri.parse('$_apiBaseUrl/users/$userId/block'),
      headers: await _headers(auth: true),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(response.body);
    }
  }

  @override
  Future<Set<String>> getBlockedUserIds() async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/users/me/blocks'),
      auth: true,
    );
    final ids = data['blockedUserIds'] as List<dynamic>? ?? [];
    return ids.map((id) => id as String).toSet();
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, {bool auth = false}) async {
    final response = await _client.get(
      uri,
      headers: await _headers(auth: auth),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri, {
    required Map<String, Object?> body,
    bool auth = false,
  }) async {
    final response = await _client.post(
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
        'Authentication required. Set PANDA_TALK_DEV_EMAIL and PANDA_TALK_DEV_PASSWORD only for mock/dev fallback.',
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
