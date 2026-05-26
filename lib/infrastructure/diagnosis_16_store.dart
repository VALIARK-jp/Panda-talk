import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/panda_type.dart';
import '../domain/panda_type_calculator.dart';

/// 16type 診断のローカル進捗（ゲスト / ログイン前の一時保存）。
class Diagnosis16Store {
  const Diagnosis16Store._();

  static const _prefix = 'panda_diagnosis16_';

  static String _scopeKey() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return userId ?? 'guest';
  }

  static String _key(String suffix) => '$_prefix${_scopeKey()}_$suffix';

  static String _scopedKey(String scope, String suffix) =>
      '$_prefix${scope}_$suffix';

  /// ゲストで保存した16問の回答・結果を、ログイン後のユーザー scope へ移す。
  static Future<void> migrateGuestScopeToCurrentUser() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    for (final suffix in ['answers', 'result']) {
      final guestKey = _scopedKey('guest', suffix);
      final userKey = _scopedKey(userId, suffix);
      final raw = prefs.getString(guestKey);
      if (raw != null && !prefs.containsKey(userKey)) {
        await prefs.setString(userKey, raw);
      }
      await prefs.remove(guestKey);
    }

    final guestSeenKey = _scopedKey('guest', 'result_seen');
    final userSeenKey = _scopedKey(userId, 'result_seen');
    if (prefs.containsKey(guestSeenKey) && !prefs.containsKey(userSeenKey)) {
      await prefs.setBool(userSeenKey, prefs.getBool(guestSeenKey) ?? false);
    }
    await prefs.remove(guestSeenKey);
  }

  static Future<Map<int, bool>> loadAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key('answers'));
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final answers = <int, bool>{};
    for (final entry in decoded.entries) {
      final n = int.tryParse(entry.key);
      if (n == null || n < 1 || n > 16) continue;
      answers[n] = entry.value as bool;
    }
    if (answers.length != decoded.length) {
      await prefs.setString(
        _key('answers'),
        jsonEncode(answers.map((k, v) => MapEntry(k.toString(), v))),
      );
    }
    return answers;
  }

  static Future<void> saveAnswer(int questionNumber, bool choseA) async {
    if (questionNumber < 1 || questionNumber > 16) return;
    final answers = await loadAnswers();
    answers[questionNumber] = choseA;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key('answers'),
      jsonEncode(answers.map((k, v) => MapEntry(k.toString(), v))),
    );
  }

  static Future<bool> isComplete() async {
    final answers = await loadAnswers();
    for (var n = 1; n <= 16; n++) {
      if (!answers.containsKey(n)) return false;
    }
    return true;
  }

  static Future<PandaTypeResult?> loadResult() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key('result'));
    if (raw != null) {
      return PandaTypeResult.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    }
    if (!await isComplete()) return null;
    return PandaTypeCalculator.compute(await loadAnswers());
  }

  static Future<void> saveResult(PandaTypeResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key('result'), jsonEncode({
      'slug': result.slug,
      'pandaTypeSlug': result.slug,
      'displayName': result.displayName,
      'tagline': result.tagline,
      'typeAffectionPct': result.scores.affection,
      'typeThinkingPct': result.scores.thinking,
      'typeActionPct': result.scores.action,
      'typeLifePct': result.scores.life,
      'diagnosed16At': (result.diagnosedAt ?? DateTime.now()).toIso8601String(),
    }));
    await prefs.setBool(_key('result_seen'), false);
  }

  static Future<bool> isResultSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key('result_seen')) ?? false;
  }

  static Future<void> markResultSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key('result_seen'), true);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key('answers'));
    await prefs.remove(_key('result'));
    await prefs.remove(_key('result_seen'));
  }
}
