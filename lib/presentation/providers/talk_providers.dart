import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/providers/repositories.dart';
import '../../core/dummy_data.dart';

final groupsProvider = FutureProvider<List<DummyGroup>>((ref) {
  return ref.watch(groupRepositoryProvider).getGroups();
});

final groupMessagesProvider = FutureProvider.family<List<DummyMessage>, String>(
  (ref, groupId) {
    return ref.watch(messageRepositoryProvider).getGroupMessages(groupId);
  },
);

final directMessagesProvider =
    FutureProvider.family<List<DummyMessage>, String>((ref, userId) {
      return ref.watch(messageRepositoryProvider).getDirectMessages(userId);
    });
