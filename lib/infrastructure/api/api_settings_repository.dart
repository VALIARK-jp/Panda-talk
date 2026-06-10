import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/dummy_data.dart';
import '../settings_repository.dart';

class ApiSettingsRepository implements SettingsRepository {
  ApiSettingsRepository({http.Client? client})
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
  Future<DummyNotificationSettings> getNotificationSettings() async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/users/me/settings'),
      auth: true,
    );
    final settings = data['settings'] as Map<String, dynamic>;
    return DummyNotificationSettings(
      likesEnabled: settings['likesEnabled'] as bool? ?? true,
      commentsEnabled: settings['commentsEnabled'] as bool? ?? true,
      friendRequestsEnabled: settings['friendRequestsEnabled'] as bool? ?? true,
      friendAcceptedEnabled: settings['friendAcceptedEnabled'] as bool? ?? true,
    );
  }

  @override
  Future<void> updateNotificationSettings(
    DummyNotificationSettings settings,
  ) async {
    await _patchJson(
      Uri.parse('$_apiBaseUrl/users/me/settings'),
      body: {
        'settings': {
          'likesEnabled': settings.likesEnabled,
          'commentsEnabled': settings.commentsEnabled,
          'friendRequestsEnabled': settings.friendRequestsEnabled,
          'friendAcceptedEnabled': settings.friendAcceptedEnabled,
        },
      },
      auth: true,
    );
  }

  @override
  Future<void> sendTestNotification() async {
    await _postJson(
      Uri.parse('$_apiBaseUrl/notifications/test'),
      body: {},
      auth: true,
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
