import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';

final similarUsersProvider = FutureProvider<List<DummyUser>>((ref) {
  return ref.watch(matchRepositoryProvider).getSimilar();
});

final oppositeUsersProvider = FutureProvider<List<DummyUser>>((ref) {
  return ref.watch(matchRepositoryProvider).getOpposite();
});

final middleUsersProvider = FutureProvider<List<DummyUser>>((ref) {
  return ref.watch(matchRepositoryProvider).getMiddle();
});

final compareAnswersProvider =
    FutureProvider.family<List<Map<String, Object>>, String>((ref, userId) {
      return ref.watch(matchRepositoryProvider).getCompareAnswers(userId);
    });

/// マッチ一覧を再取得する（Pull-to-refresh 用）。
Future<void> refreshMatchLists(WidgetRef ref, {required int activeTabIndex}) async {
  ref.invalidate(similarUsersProvider);
  ref.invalidate(oppositeUsersProvider);
  ref.invalidate(middleUsersProvider);

  switch (activeTabIndex) {
    case 0:
      await ref.read(similarUsersProvider.future);
    case 1:
      await ref.read(oppositeUsersProvider.future);
    default:
      await ref.read(middleUsersProvider.future);
  }
}
