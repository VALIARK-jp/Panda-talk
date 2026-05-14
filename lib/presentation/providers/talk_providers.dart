import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/providers/repositories.dart';
import '../../core/dummy_data.dart';

final groupsProvider = FutureProvider<List<DummyGroup>>((ref) {
  return ref.watch(groupRepositoryProvider).getGroups();
});

final directThreadsProvider = FutureProvider<List<DummyDirectThread>>((ref) {
  return ref.watch(messageRepositoryProvider).getDirectThreads();
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

final messageActionsProvider = Provider<MessageActions>((ref) {
  return MessageActions(ref);
});

class MessageActions {
  final Ref _ref;
  const MessageActions(this._ref);

  Future<void> sendDirectMessage(String userId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _ref.read(messageRepositoryProvider).sendDirectMessage(userId, trimmed);
    _ref.invalidate(directMessagesProvider(userId));
    _ref.invalidate(directThreadsProvider);
  }

  Future<void> sendGroupMessage(String groupId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _ref.read(messageRepositoryProvider).sendGroupMessage(groupId, trimmed);
    _ref.invalidate(groupMessagesProvider(groupId));
  }
}
