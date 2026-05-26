import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/dummy_data.dart';
import '../../core/oddball_score.dart';
import '../question_repository.dart';
import '../supabase/supabase_answer_submit.dart';

class ApiQuestionRepository implements QuestionRepository {
  ApiQuestionRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  final List<DummyQuestion> _myQuestions = [];

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

  bool get _hasSession => Supabase.instance.client.auth.currentSession != null;

  @override
  Future<List<DummyQuestion>> getDiagnosis16Questions() async {
    return getFeedWindow(before: 0, after: 0, maxQuestionNumber: 16);
  }

  @override
  Future<List<DummyQuestion>> getFeedWindow({
    int before = 10,
    int after = 10,
    int? maxQuestionNumber,
  }) async {
    final params = <String, String>{'before': '$before', 'after': '$after'};
    if (maxQuestionNumber != null) {
      params['maxQuestionNumber'] = '$maxQuestionNumber';
    }
    final uri = Uri.parse(
      '$_apiBaseUrl/questions/window',
    ).replace(queryParameters: params);
    final data = await _getJson(uri, auth: _hasSession);
    return _questionsFromResponse(data);
  }

  @override
  Future<List<DummyQuestion>> getFeedWindowAround({
    int before = 15,
    int after = 15,
    int? questionNumber,
    String? questionId,
    int? currentQuestionNumber,
  }) async {
    final params = <String, String>{
      'before': '$before',
      'after': '$after',
    };
    if (questionNumber != null) {
      params['questionNumber'] = '$questionNumber';
    }
    if (questionId != null && questionId.isNotEmpty) {
      params['questionId'] = questionId;
    }
    final reported = currentQuestionNumber ?? questionNumber;
    if (reported != null) {
      params['currentQuestionNumber'] = '$reported';
    }
    final uri = Uri.parse(
      '$_apiBaseUrl/questions/window/around',
    ).replace(queryParameters: params);
    final data = await _getJson(uri, auth: _hasSession);
    return _questionsFromResponse(data);
  }

  @override
  Future<List<DummyQuestion>> getFeedQuestions({
    int limit = 200,
    String? cursor,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (cursor != null) params['cursor'] = cursor;
    final uri = Uri.parse(
      '$_apiBaseUrl/questions',
    ).replace(queryParameters: params);
    // ログイン時は Authorization を付けて「自分の未回答」だけ返す
    final data = await _getJson(uri, auth: _hasSession);
    return _questionsFromResponse(data);
  }

  @override
  Future<DummyQuestion> getCurrentQuestion() async {
    final questions = await getFeedQuestions();
    if (questions.isEmpty) {
      throw StateError('No questions returned from API');
    }
    return questions.first;
  }

  @override
  Future<List<DummyQuestion>> getHistory({
    int limit = 20,
    String? cursor,
  }) async {
    final params = <String, String>{
      'limit': '$limit',
      ...?cursor == null ? null : {'cursor': cursor},
    };
    final uri = Uri.parse(
      '$_apiBaseUrl/questions/history',
    ).replace(queryParameters: params);
    final data = await _getJson(uri, auth: true);
    return _questionsFromResponse(data);
  }

  @override
  Future<List<DummyQuestion>> search(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return const [];

    final data = await _getJson(
      Uri.parse(
        '$_apiBaseUrl/questions/search?q=${Uri.encodeQueryComponent(trimmed)}',
      ),
    );
    return _questionsFromResponse(data);
  }

  @override
  Future<List<DummyQuestion>> getMyQuestions() async {
    return List.unmodifiable(_myQuestions);
  }

  @override
  Future<void> postQuestion({
    required String text,
    required String optionA,
    required String optionB,
    required String category,
  }) async {
    final data = await _postJson(
      Uri.parse('$_apiBaseUrl/questions'),
      body: {
        'text': text,
        'optionA': optionA,
        'optionB': optionB,
        'category': category,
      },
      auth: true,
    );

    final question = await _questionFromJson(
      data['question'] as Map<String, dynamic>,
    );
    _myQuestions.insert(0, question);
  }

  @override
  Future<void> editQuestion({
    required int number,
    required String text,
    required String optionA,
    required String optionB,
    required String category,
  }) async {
    final index = _myQuestions.indexWhere(
      (question) => question.number == number,
    );
    if (index == -1) return;

    final question = _myQuestions[index];
    if (question.apiId == null) return;

    final data = await _patchJson(
      Uri.parse('$_apiBaseUrl/questions/${question.apiId}'),
      body: {
        'text': text,
        'optionA': optionA,
        'optionB': optionB,
        'category': category,
      },
      auth: true,
    );

    _myQuestions[index] = await _questionFromJson(
      data['question'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteQuestion(int number) async {
    final index = _myQuestions.indexWhere(
      (question) => question.number == number,
    );
    if (index == -1) return;

    final question = _myQuestions[index];
    if (question.apiId == null) return;

    await _delete(
      Uri.parse('$_apiBaseUrl/questions/${question.apiId}'),
      auth: true,
    );
    _myQuestions.removeAt(index);
  }

  @override
  Future<QuestionVoteStats> answerQuestion({
    required DummyQuestion question,
    required String selectedOption,
  }) async {
    if (question.apiId == null || !_hasSession) {
      assert(() {
        debugPrint(
          'ApiQuestionRepository.answerQuestion: skipped POST '
          '(apiId=${question.apiId}, session=$_hasSession)',
        );
        return true;
      }());
      return QuestionVoteStats(
        percentA: question.percentA,
        countA: question.countA,
        countB: question.countB,
      );
    }

    final selectedA = selectedOption == question.optionA;

    try {
      final response = await _client.post(
        Uri.parse('$_apiBaseUrl/answers'),
        headers: await _headers(auth: true),
        body: jsonEncode({
          'questionId': question.apiId,
          'choice': selectedA ? 'a' : 'b',
        }),
      );

      // 二重タップや端末進捗のずれで既に回答済みのときは stats だけ取り直す。
      if (response.statusCode == 409 &&
          response.body.contains('Already answered')) {
        return _fetchVoteStats(question.apiId!);
      }

      if (kDebugMode && response.statusCode == 201) {
        debugPrint(
          'ApiQuestionRepository.answerQuestion: saved '
          'questionId=${question.apiId}',
        );
      }

      final data = _decode(response);
      return _voteStatsFromJson(data['stats'] as Map<String, dynamic>);
    } catch (e) {
      if (AppConfig.usesLocalApiHost && _isConnectionError(e)) {
        await submitAnswerViaSupabase(
          questionId: question.apiId!,
          selectedA: selectedA,
        );
        return fetchVoteStatsFromSupabase(question.apiId!);
      }
      rethrow;
    }
  }

  QuestionVoteStats _voteStatsFromJson(Map<String, dynamic> stats) {
    final countA = stats['countA'] as int? ?? 0;
    final countB = stats['countB'] as int? ?? 0;
    final total = countA + countB;
    final percentA = stats['percentA'] is num
        ? (stats['percentA'] as num).round()
        : total == 0
        ? 50
        : (countA / total * 100).round();
    return QuestionVoteStats(
      percentA: percentA,
      countA: countA,
      countB: countB,
    );
  }

  Future<QuestionVoteStats> _fetchVoteStats(String questionId) async {
    try {
      final data = await _getJson(
        Uri.parse('$_apiBaseUrl/questions/$questionId/stats'),
        auth: true,
      );
      return _voteStatsFromJson(data['stats'] as Map<String, dynamic>);
    } catch (e) {
      if (AppConfig.usesLocalApiHost && _isConnectionError(e)) {
        return fetchVoteStatsFromSupabase(questionId);
      }
      rethrow;
    }
  }

  bool _isConnectionError(Object e) {
    final msg = e.toString();
    return msg.contains('Connection refused') ||
        msg.contains('Failed host lookup') ||
        msg.contains('SocketException') ||
        msg.contains('ClientException');
  }

  Future<List<DummyQuestion>> _questionsFromResponse(
    Map<String, dynamic> data,
  ) async {
    final rows = data['questions'] as List<dynamic>? ?? const [];
    return Future.wait(
      rows.map((row) => _questionFromJson(row as Map<String, dynamic>)),
    );
  }

  Future<DummyQuestion> _questionFromJson(Map<String, dynamic> json) async {
    final id = json['id'] as String;
    final poster = json['poster'] as Map<String, dynamic>?;
    final countA = json['countA'] as int? ?? 0;
    final countB = json['countB'] as int? ?? 0;
    final percentFromApi = json['percentA'];
    QuestionVoteStats voteStats;
    if (percentFromApi is num && (countA > 0 || countB > 0)) {
      voteStats = QuestionVoteStats(
        percentA: percentFromApi.round(),
        countA: countA,
        countB: countB,
      );
    } else if (percentFromApi is num) {
      voteStats = QuestionVoteStats(
        percentA: percentFromApi.round(),
        countA: countA,
        countB: countB,
      );
    } else {
      voteStats = await _fetchVoteStats(id);
    }

    return DummyQuestion(
      apiId: id,
      number: _questionNumberFromJson(json, id),
      category: json['category'] as String? ?? 'その他',
      authorName: _posterDisplayName(poster),
      authorUsername: poster?['username'] as String? ?? 'unknown',
      text: json['text'] as String,
      optionA: json['optionA'] as String,
      optionB: json['optionB'] as String,
      myAnswer: json['myAnswer'] as String?,
      percentA: voteStats.percentA,
      countA: voteStats.countA,
      countB: voteStats.countB,
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
    );
  }

  @override
  Future<void> toggleQuestionLike({
    required String questionId,
    required bool isLike,
  }) async {
    if (isLike) {
      await _postJson(
        Uri.parse('$_apiBaseUrl/questions/$questionId/likes'),
        body: {},
        auth: true,
      );
    } else {
      await _delete(
        Uri.parse('$_apiBaseUrl/questions/$questionId/likes'),
        auth: true,
      );
    }
  }

  @override
  Future<int> fetchQuestionPercentA(String questionId) async {
    try {
      return await _getStats(questionId);
    } catch (e) {
      if (AppConfig.usesLocalApiHost && _isConnectionError(e)) {
        return fetchQuestionPercentAFromSupabase(questionId);
      }
      rethrow;
    }
  }

  Future<int> _getStats(String questionId) async {
    return (await _fetchVoteStats(questionId)).percentA;
  }

  String _posterDisplayName(Map<String, dynamic>? poster) {
    if (poster == null) return 'unknown';
    final name = poster['name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return poster['username'] as String? ?? 'unknown';
  }

  int _questionNumberFromJson(Map<String, dynamic> json, String id) {
    final number = json['questionNumber'] ?? json['question_number'];
    if (number is int) return number;
    if (number is num) return number.toInt();
    if (number is String) {
      final parsed = int.tryParse(number);
      if (parsed != null) return parsed;
    }

    final tail = id.split('-').last;
    final decimal = int.tryParse(tail);
    if (decimal != null) return decimal;
    final hex = int.tryParse(tail.substring(tail.length - 6), radix: 16);
    if (hex != null) return hex;
    return id.hashCode & 0x7fffffff;
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
