import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/diagnosis_16_store.dart';
import '../../infrastructure/providers/repositories.dart';

/// 16問の結果モーダルを見終え、17問目以降のフィードに進める状態。
final diagnosis16UnlockedProvider = FutureProvider<bool>((ref) async {
  try {
    final profile = await ref.watch(profileRepositoryProvider).getProfile();
    if (profile.hasDiagnosis16) return true;
  } catch (_) {}

  return Diagnosis16Store.isResultSeen();
});
