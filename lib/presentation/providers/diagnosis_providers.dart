import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/diagnosis_16_store.dart';
import '../../infrastructure/providers/repositories.dart';

/// 16問の結果モーダルを見終え、17問目以降のフィードに進める状態。
///
/// 「16問すべて回答済み」だけでは true にしない（診断計算・結果保存・モーダル閲覧まで完了が必要）。
final diagnosis16UnlockedProvider = FutureProvider<bool>((ref) async {
  final profileRepo = ref.watch(profileRepositoryProvider);

  try {
    final profile = await profileRepo.getProfile();
    if (profile.hasDiagnosis16) return true;
  } catch (_) {}

  return Diagnosis16Store.isResultSeen();
});
