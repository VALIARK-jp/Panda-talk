import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _kGuestProgress = 'panda_question_feed_progress_guest_v1';

String _userProgressKey(String userId) =>
    'panda_question_feed_progress_user_$userId';

/// ゲスト用とログインユーザー用で進捗を分けて保持する。
class QuestionProgressStore {
  static Future<void> saveGuest(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGuestProgress, jsonEncode(json));
  }

  static Future<void> saveForUser(
    String userId,
    Map<String, dynamic> json,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProgressKey(userId), jsonEncode(json));
  }

  static Future<Map<String, dynamic>?> loadGuest() async {
    final prefs = await SharedPreferences.getInstance();
    // 旧キー（ログイン／ゲスト共通）を捨て、未ログイン時にログイン中の回答が出ないようにする。
    const legacy = 'panda_question_feed_progress_v1';
    if (prefs.containsKey(legacy)) {
      await prefs.remove(legacy);
    }
    return _decode(prefs.getString(_kGuestProgress));
  }

  static Future<Map<String, dynamic>?> loadForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_userProgressKey(userId)));
  }

  /// ログイン後にゲスト回答をサーバーへ送ったあと、ゲスト用キャッシュを消す。
  static Future<void> clearGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGuestProgress);
  }

  static Future<void> clearForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userProgressKey(userId));
  }

  static Map<String, dynamic>? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
