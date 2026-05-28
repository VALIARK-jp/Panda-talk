import 'package:flutter/material.dart';

/// カテゴリ別の「ポスター」一言（質問カード上部の思想ライン）。
String categoryPosterTagline(String category) {
  final key = category.trim();
  return _taglines[key] ?? _taglines[_normalize(key)] ?? '白か黒か。';
}

String? categoryWatermarkLabel(String category) {
  final key = category.trim();
  return _watermarks[key] ?? _watermarks[_normalize(key)];
}

String normalizedCategoryLabel(String category) {
  final key = category.trim();
  return _normalize(key);
}

Color categoryAccentColor(String category) {
  switch (_normalize(category.trim())) {
    case '恋愛':
      return const Color(0xFFE85D9E);
    case '人生':
      return const Color(0xFF8E5BE8);
    case '生活':
      return const Color(0xFF28A86B);
    case '価値観':
      return const Color(0xFF3478F6);
    case 'SNS':
      return const Color(0xFFE0A800);
    case '仕事':
      return const Color(0xFF0D9488);
    case '友人':
      return const Color(0xFFFF8A3D);
    case '学校':
      return const Color(0xFFEF4444);
    case '旅行':
      return const Color(0xFF14B8A6);
    case '食べ物':
      return const Color(0xFFD97706);
    case 'お金':
      return const Color(0xFF16A34A);
    case '診断':
      return const Color(0xFF6B7280);
    default:
      return const Color(0xFF111111);
  }
}

String _normalize(String category) {
  if (category.contains('恋')) return '恋愛';
  if (category.contains('友')) return '友人';
  if (category.contains('仕') || category.contains('働')) return '仕事';
  if (category.contains('学') || category.contains('校')) return '学校';
  if (category.contains('生')) return '生活';
  if (category.contains('性') || category.contains('価')) return '価値観';
  if (category.contains('旅')) return '旅行';
  if (category.contains('食')) return '食べ物';
  if (category.toLowerCase().contains('lifestyle')) return '生活';
  if (category.toLowerCase().contains('work')) return '仕事';
  if (category.toLowerCase().contains('travel')) return '旅行';
  if (category.toLowerCase().contains('pet')) return '生活';
  return category;
}

const _taglines = <String, String>{
  '恋愛': '恋愛に正解なんてない。',
  '生活': '日常の本音、ここに全部ある。',
  '友人': '友達の前でも、本音は違う。',
  '仕事': '職場の建前、剥がしてみ。',
  '学校': '教室の空気、数値になる。',
  '価値観': '正しさより、率直さ。',
  '旅行': '予定通りか、気分次第か。',
  '食べ物': '食べ方にも、性格が出る。',
  'お金': '金の話、一番白黒つく。',
  'SNS': '画面の向こうの本音。',
  '診断': '16問で、あなたの軸が見える。',
};

const _watermarks = <String, String>{
  '恋愛': '恋愛',
  '生活': '生活',
  '友人': '友人',
  '仕事': '仕事',
  '学校': '学校',
  '価値観': '価値観',
  '旅行': '旅行',
  '食べ物': '食べ物',
  'お金': 'お金',
  'SNS': 'SNS',
  '診断': '診断',
};

/// 少数派側の選択率からシェア向きコピーを生成。
String minorityFlavorCopy(int selectedPercent) {
  if (selectedPercent <= 8) return '全体の$selectedPercent%しか選んでない';
  if (selectedPercent <= 15) return '上位$selectedPercent%のレア回答';
  if (selectedPercent <= 25) return 'かなり価値観ズレてます';
  return '少数派 $selectedPercent%';
}

/// 異端児スコアの変化コピー。
String? oddballBumpCopy({
  required int prevScore,
  required int newScore,
  required bool wasMinorityThisAnswer,
}) {
  if (!wasMinorityThisAnswer && newScore <= prevScore) return null;
  final delta = newScore - prevScore;
  if (delta >= 8) return '異端児度、急上昇';
  if (delta >= 3) return '異端児度、上昇';
  if (wasMinorityThisAnswer && delta > 0) return '異端児スコア +$delta%';
  if (wasMinorityThisAnswer) return 'レア回答を記録';
  return null;
}
