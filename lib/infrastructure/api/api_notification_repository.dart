import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/dummy_data.dart';
import '../notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository({http.Client? client})
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
  Future<List<DummyNotification>> getNotifications() async {
    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/notifications'),
      auth: true,
    );
    final notifications = data['notifications'] as List<dynamic>? ?? [];
    return notifications
        .map((n) => _parseNotification(n as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    // Currently backend only supports markAll, but we can implement single mark if needed
    // For now, let's just call markAll if the API is limited, or assume it might be added
    // Backend has PATCH /notifications/read which marks all
    await _patchJson(
      Uri.parse('$_apiBaseUrl/notifications/read'),
      body: {'id': id}, // Even if backend ignores id and marks all, it's safer
      auth: true,
    );
  }

  @override
  Future<void> markAllAsRead() async {
    await _patchJson(
      Uri.parse('$_apiBaseUrl/notifications/read'),
      body: {},
      auth: true,
    );
  }

  DummyNotification _parseNotification(Map<String, dynamic> json) {
    final type = json['type'] as String;
    String title = '通知';
    String body = '新しい通知があります';
    String targetLabel = 'その他';

    switch (type) {
      case 'like':
        title = '質問にいいねされました';
        body = 'あなたの質問にいいねがつきました';
        targetLabel = '質問';
        break;
      case 'comment':
        title = 'コメントが届きました';
        body = 'あなたの質問に新着コメントがあります';
        targetLabel = '質問';
        break;
      case 'friend_request':
        title = '友達申請が届きました';
        body = '誰かがあなたと友達になりたがっています';
        targetLabel = '友達申請';
        break;
      case 'friend_accepted':
        title = '友達申請が承認されました';
        body = '友達申請が承認されました！トークを始めましょう';
        targetLabel = 'プロフィール';
        break;
      case 'new_match':
        title = '新しいマッチング';
        body = '一致率の高いパンダが見つかりました';
        targetLabel = 'マッチ';
        break;
      case 'group_created':
        title = 'グループ作成';
        body = '新しいグループに参加しました';
        targetLabel = 'グループ';
        break;
    }

    return DummyNotification(
      id: json['id'] as String,
      title: title,
      body: body,
      time: _formatTime(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      targetLabel: targetLabel,
    );
  }

  String _formatTime(String createdAt) {
    final date = DateTime.parse(createdAt).toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}時間前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}日前';
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
