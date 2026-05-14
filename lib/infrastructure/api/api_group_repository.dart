import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/dummy_data.dart';
import '../group_repository.dart';

class ApiGroupRepository implements GroupRepository {
  ApiGroupRepository({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _apiBaseUrl = AppConfig.apiBaseUrl;
  static const _supabaseUrl = String.fromEnvironment(
    'PANDA_TALK_SUPABASE_URL',
    defaultValue: AppConfig.supabaseUrl,
  );
  static const _supabaseAnonKey = String.fromEnvironment(
    'PANDA_TALK_SUPABASE_ANON_KEY',
    defaultValue: AppConfig.supabaseAnonKey,
  );
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
  Future<List<DummyGroup>> getGroups() async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/groups'),
      auth: true,
    );
    final groupsData = data['groups'] as List<dynamic>? ?? [];
    return groupsData.map((json) => _parseGroup(json as Map<String, dynamic>)).toList();
  }

  DummyGroup _parseGroup(Map<String, dynamic> groupMap) {
    // members may be a list of user objects or strings
    final rawMembers = groupMap['members'] as List<dynamic>? ?? [];
    final members = rawMembers.map((m) {
      if (m is String) return m;
      if (m is Map<String, dynamic>) {
        return (m['name'] as String?) ?? (m['username'] as String?) ?? '名無し';
      }
      return '名無し';
    }).toList();

    final avgMatchRate = groupMap['avgMatchRate'] as int? ??
        ((groupMap['matchRate'] as num?)?.toInt() ?? 0);
    final type = groupMap['type'] as String? ?? 'middle';
    final name = groupMap['name'] as String? ?? 'グループ';

    return DummyGroup(
      name: name,
      avgMatchRate: avgMatchRate,
      members: members,
      type: type,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, {bool auth = false}) async {
    final response = await _client.get(
      uri,
      headers: await _headers(auth: auth),
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
