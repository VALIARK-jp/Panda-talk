import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/dummy_data.dart';
import '../message_repository.dart';

class ApiMessageRepository implements MessageRepository {
  ApiMessageRepository({http.Client? client})
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
  Future<List<DummyDirectThread>> getDirectThreads() async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/direct_messages/threads'),
      auth: true,
    );
    final threads = data['threads'] as List<dynamic>? ?? [];
    return threads.map((t) => _parseThread(t as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<DummyMessage>> getGroupMessages(String groupId) async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/groups/$groupId/messages'),
      auth: true,
    );
    final messages = data['messages'] as List<dynamic>? ?? [];
    return messages.map((m) => _parseMessage(m as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<DummyMessage>> getDirectMessages(String userId) async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/direct_messages/$userId'),
      auth: true,
    );
    final messages = data['messages'] as List<dynamic>? ?? [];
    return messages.map((m) => _parseMessage(m as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> sendDirectMessage(String userId, String text) async {
    await _postJson(
      Uri.parse('$_apiBaseUrl/direct_messages'),
      body: {'receiverId': userId, 'body': text},
      auth: true,
    );
  }

  @override
  Future<void> sendGroupMessage(String groupId, String text) async {
    await _postJson(
      Uri.parse('$_apiBaseUrl/groups/$groupId/messages'),
      body: {'body': text},
      auth: true,
    );
  }

  DummyDirectThread _parseThread(Map<String, dynamic> json) {
    final partner = json['partner'] as Map<String, dynamic>;
    final lastMessage = json['lastMessage'] as Map<String, dynamic>;
    return DummyDirectThread(
      user: DummyUser(
        name: partner['name'] as String? ?? partner['username'] as String? ?? 'unknown',
        id: partner['id'] as String,
        matchRate: 0, // In a real app, this might come from another join
      ),
      lastMessage: lastMessage['body'] as String,
      time: _formatTime(lastMessage['createdAt'] as String),
      unreadCount: 0,
    );
  }

  DummyMessage _parseMessage(Map<String, dynamic> json) {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    return DummyMessage(
      text: json['body'] as String,
      isMe: (json['senderId'] ?? json['userId']) == myId,
      time: _formatTime(json['createdAt'] as String),
      senderName: json['senderName'] as String?,
    );
  }

  String _formatTime(String createdAt) {
    final date = DateTime.parse(createdAt).toLocal();
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.month}/${date.day}';
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
