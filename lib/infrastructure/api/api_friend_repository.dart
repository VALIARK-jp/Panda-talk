import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/dummy_data.dart';
import '../friend_repository.dart';

class ApiFriendRepository implements FriendRepository {
  ApiFriendRepository({http.Client? client})
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
  final Set<String> _requestedUserIds = {}; // Fallback for pendingSent

  @override
  Future<List<DummyUser>> getFriends() async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/friendships'),
      auth: true,
    );
    final friendsData = data['friends'] as List<dynamic>? ?? [];
    return friendsData
        .map((json) => _parseUser(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DummyFriendRequest>> getRequests() async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/friendships'),
      auth: true,
    );
    final pendingData = data['pendingReceived'] as List<dynamic>? ?? [];
    return pendingData.map((json) {
      final user = _parseUser(json as Map<String, dynamic>);
      return DummyFriendRequest(user: user, message: '友達申請が届いています');
    }).toList();
  }

  @override
  Future<Set<String>> getRequestedUserIds() async {
    // API doesn't return sent requests currently, so we track them locally in session
    return Set.unmodifiable(_requestedUserIds);
  }

  @override
  Future<List<DummyUser>> searchUsers(String keyword) async {
    final query = Uri.encodeQueryComponent(
      keyword.trim().replaceFirst('@', ''),
    );
    if (query.isEmpty) return const [];

    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/users/search?q=$query&limit=20'),
      auth: true,
    );

    final usersData = data['users'] as List<dynamic>? ?? [];
    return usersData
        .map((json) => _parseUser(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> sendFriendRequest(String userId) async {
    await _postJson(
      Uri.parse('$_apiBaseUrl/friendships/$userId'),
      body: {},
      auth: true,
    );
    _requestedUserIds.add(userId);
  }

  @override
  Future<void> acceptRequest(String userId) async {
    await _client.patch(
      Uri.parse('$_apiBaseUrl/friendships/$userId/accept'),
      headers: await _headers(auth: true),
    );
  }

  @override
  Future<void> rejectRequest(String userId) async {
    await _delete(Uri.parse('$_apiBaseUrl/friendships/$userId'), auth: true);
  }

  @override
  Future<void> deleteFriendship(String userId) async {
    await _delete(Uri.parse('$_apiBaseUrl/friendships/$userId'), auth: true);
  }

  DummyUser _parseUser(Map<String, dynamic> userMap) {
    return DummyUser(
      id: userMap['id'] as String,
      name:
          userMap['name'] as String? ??
          userMap['username'] as String? ??
          '名無しさん',
      matchRate: 0, // Not provided by this API
      avatarUrl: userMap['avatarUrl'] as String?,
    );
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

  Future<void> _delete(Uri uri, {bool auth = false}) async {
    final response = await _client.delete(
      uri,
      headers: await _headers(auth: auth),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(response.body);
    }
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
