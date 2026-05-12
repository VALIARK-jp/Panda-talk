import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/providers/repositories.dart';
import '../../core/dummy_data.dart';

final currentQuestionProvider = FutureProvider<DummyQuestion>((ref) {
  return ref.watch(questionRepositoryProvider).getCurrentQuestion();
});

final feedQuestionsProvider = FutureProvider<List<DummyQuestion>>((ref) {
  return ref.watch(questionRepositoryProvider).getFeedQuestions();
});

final questionHistoryProvider = FutureProvider<List<DummyQuestion>>((ref) {
  return ref.watch(questionRepositoryProvider).getHistory();
});

final questionSearchProvider =
    FutureProvider.family<List<DummyQuestion>, String>((ref, keyword) {
      return ref.watch(questionRepositoryProvider).search(keyword);
    });
