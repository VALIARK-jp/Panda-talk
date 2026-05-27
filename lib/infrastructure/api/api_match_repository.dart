import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/dummy_data.dart';
import '../match_repository.dart';

class ApiMatchRepository implements MatchRepository {
  ApiMatchRepository({http.Client? client}) : _client = client ?? http.Client();

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
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/matches/$userId/answers'),
      auth: true,
    );
    final answers = data['answers'] as List<dynamic>? ?? const [];
    return answers.map((answerData) {
      final answer = answerData as Map<String, dynamic>;
      return <String, Object>{
        'question': answer['question'] as String? ?? '',
        'mine': answer['mine'] as String? ?? '',
        'theirs': answer['theirs'] as String? ?? '',
        'match': answer['match'] as bool? ?? false,
      };
    }).toList();
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
      final rawMatchRate = (match['matchRate'] as num? ?? 0).toDouble();
      final matchRatePercent = rawMatchRate <= 1
          ? (rawMatchRate * 100).round()
          : rawMatchRate.round();

      return DummyUser(
        id: user['id'] as String,
        name: user['name'] as String? ?? '名無しさん',
        matchRate: matchRatePercent,
        avatarUrl: user['avatarUrl'] as String?,
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
