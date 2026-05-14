import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/dummy_data.dart';
import '../match_repository.dart';

class ApiMatchRepository implements MatchRepository {
  ApiMatchRepository({http.Client? client}) : _client = client ?? http.Client();

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
  Future<List<DummyUser>> getSimilar() async {
    return _fetchMatches('similar');
  }

  @override
  Future<List<DummyUser>> getOpposite() async {
    return _fetchMatches('opposite');
  }

  @override
  Future<List<DummyUser>> getMiddle() async {
    return _fetchMatches('middle');
  }

  @override
  Future<List<Map<String, Object>>> getCompareAnswers(String userId) async {
    // API does not currently have this endpoint, so returning mock data
    return [
      {'question': '休日は外出派？家派？', 'mine': '外出派', 'theirs': '外出派', 'match': true},
      {'question': '朝型？夜型？', 'mine': '夜型', 'theirs': '夜型', 'match': true},
      {
        'question': 'LINEは即レス派？溜める派？',
        'mine': '即レス派',
        'theirs': '即レス派',
        'match': true,
      },
      {
        'question': '旅行は計画派？ノープラン派？',
        'mine': '計画派',
        'theirs': 'ノープラン派',
        'match': false,
      },
    ];
  }

  Future<List<DummyUser>> _fetchMatches(String type) async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/matches?type=$type&limit=20'),
      auth: true,
    );

    final matches = data['matches'] as List<dynamic>? ?? [];
    return matches.map((matchData) {
      final match = matchData as Map<String, dynamic>;
      final user = match['user'] as Map<String, dynamic>;
      final matchRate = (match['matchRate'] as num? ?? 0).toDouble();

      return DummyUser(
        id: user['id'] as String,
        name: user['name'] as String? ?? '名無しさん',
        matchRate: (matchRate * 100).round(),
      );
    }).toList();
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
