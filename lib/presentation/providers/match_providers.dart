import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/providers/repositories.dart';
import '../../core/dummy_data.dart';

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
