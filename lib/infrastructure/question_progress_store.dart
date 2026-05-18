import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _kQuestionProgress = 'panda_question_feed_progress_v1';

/// ゲスト／ログイン前の質問フィード進捗を端末に保持（新規登録後も続きから）。
class QuestionProgressStore {
  static Future<void> save(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kQuestionProgress, jsonEncode(json));
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kQuestionProgress);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
