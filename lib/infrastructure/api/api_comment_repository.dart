import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/dummy_data.dart';
import '../comment_repository.dart';

class ApiCommentRepository implements CommentRepository {
  ApiCommentRepository({http.Client? client})
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

  bool get _hasSession => Supabase.instance.client.auth.currentSession != null;

  @override
  Future<List<DummyComment>> getComments(DummyQuestion question) async {
    if (question.apiId == null) return [];

    final data = await _getJson(
      Uri.parse('$_apiBaseUrl/questions/${question.apiId}/comments'),
      auth: _hasSession,
    );

    final commentsData = data['comments'] as List<dynamic>? ?? [];
    final currentUserId = await _getCurrentUserId();

    return commentsData.map((json) {
      final commentMap = json as Map<String, dynamic>;
      final choice = commentMap['choice'] as String;
      final optionText = choice == 'a' ? question.optionA : question.optionB;

      return DummyComment(
        id: commentMap['id'] as String,
        option: optionText,
        body: commentMap['body'] as String,
        likes: commentMap['likeCount'] as int? ?? 0,
        isMine: commentMap['userId'] == currentUserId,
        likedByMe: commentMap['likedByMe'] as bool? ?? false,
      );
    }).toList();
  }

  @override
  Future<void> toggleLike({
    required int questionNumber,
    required String commentId,
    required bool isLike,
  }) async {
    if (isLike) {
      await _postJson(
        Uri.parse('$_apiBaseUrl/comments/$commentId/likes'),
        body: {},
        auth: true,
      );
    } else {
      await _delete(
        Uri.parse('$_apiBaseUrl/comments/$commentId/likes'),
        auth: true,
      );
    }
  }

  @override
  Future<void> deleteComment({
    required int questionNumber,
    required String commentId,
  }) async {
    await _delete(Uri.parse('$_apiBaseUrl/comments/$commentId'), auth: true);
  }

  @override
  Future<void> postComment({
    required int questionNumber,
    required String option,
    required String body,
    String? apiQuestionId,
    DummyQuestion? question,
  }) async {
    final actualQuestionId = apiQuestionId ?? question?.apiId;
    if (actualQuestionId == null) return;

    String choice = 'a';
    if (question != null && option == question.optionB) {
      choice = 'b';
    }

    await _postJson(
      Uri.parse('$_apiBaseUrl/questions/$actualQuestionId/comments'),
      body: {'choice': choice, 'body': body},
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

  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) return session.user.id;
    return null; // For dev login we might not have it strictly this way but we'll try
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
      throw StateError('${response.statusCode}: ${response.body}');
    }
    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
