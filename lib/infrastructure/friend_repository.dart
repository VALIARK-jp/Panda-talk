import '../core/dummy_data.dart';

abstract class FriendRepository {
  Future<List<DummyUser>> getFriends();
  Future<List<DummyFriendRequest>> getRequests();
  Future<Set<String>> getRequestedUserIds();
  Future<List<DummyUser>> searchUsers(String keyword);
  Future<void> sendFriendRequest(String userId);
  Future<void> acceptRequest(String userId);
  Future<void> rejectRequest(String userId);
  Future<void> deleteFriendship(String userId);
}
