import '../../core/dummy_data.dart';

class MockFriendRepository {
  final List<DummyUser> _friends = [
    const DummyUser(name: 'こうたろう', id: 'kotaro_123', matchRate: 92),
    const DummyUser(name: 'まなみ', id: 'manami_456', matchRate: 88),
    const DummyUser(name: 'たくみ', id: 'takumi_111', matchRate: 29),
  ];

  final List<DummyFriendRequest> _requests = [
    const DummyFriendRequest(
      user: DummyUser(name: 'りな', id: 'rina_222', matchRate: 31),
      message: '友達申請が届いています',
    ),
    const DummyFriendRequest(
      user: DummyUser(name: 'ゆうき', id: 'yuuki_789', matchRate: 84),
      message: '回答の傾向が近いユーザーです',
    ),
  ];

  final List<DummyUser> _candidates = [
    const DummyUser(name: 'ぱんだ好き', id: 'panda_love', matchRate: 74),
    const DummyUser(name: 'ぱんだ夜型', id: 'panda_night', matchRate: 67),
    const DummyUser(name: 'ぱんだ社長', id: 'panda_ceo', matchRate: 52),
    const DummyUser(name: 'こうたろう', id: 'kotaro_123', matchRate: 92),
    const DummyUser(name: 'まなみ', id: 'manami_456', matchRate: 88),
  ];

  final Set<String> _requestedUserIds = {};

  List<DummyUser> getFriends() => List.unmodifiable(_friends);

  List<DummyFriendRequest> getRequests() => List.unmodifiable(_requests);

  Set<String> getRequestedUserIds() => Set.unmodifiable(_requestedUserIds);

  List<DummyUser> searchUsers(String keyword) {
    final query = keyword.trim().replaceFirst('@', '').toLowerCase();
    if (query.isEmpty) return const [];
    return _candidates.where((user) {
      return user.id.toLowerCase().startsWith(query) ||
          user.name.toLowerCase().contains(query);
    }).toList();
  }

  void sendFriendRequest(String userId) {
    _requestedUserIds.add(userId);
  }

  void acceptRequest(String userId) {
    final index = _requests.indexWhere((request) => request.user.id == userId);
    if (index == -1) return;
    final request = _requests.removeAt(index);
    if (!_friends.any((friend) => friend.id == userId)) {
      _friends.add(request.user);
    }
  }

  void rejectRequest(String userId) {
    _requests.removeWhere((request) => request.user.id == userId);
  }

  void deleteFriendship(String userId) {
    _friends.removeWhere((friend) => friend.id == userId);
  }
}
