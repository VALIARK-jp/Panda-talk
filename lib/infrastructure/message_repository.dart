import '../core/dummy_data.dart';

abstract class MessageRepository {
  Future<List<DummyDirectThread>> getDirectThreads();
  Future<List<DummyMessage>> getGroupMessages(String groupId);
  Future<List<DummyMessage>> getDirectMessages(String userId);
  Future<void> sendDirectMessage(String userId, String text);
  Future<void> sendGroupMessage(String groupId, String text);
}
