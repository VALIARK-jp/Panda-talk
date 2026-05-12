import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';

class FriendState {
  final List<DummyUser> friends;
  final List<DummyFriendRequest> requests;
  final List<DummyUser> searchResults;
  final Set<String> requestedUserIds;
  final String searchQuery;

  const FriendState({
    required this.friends,
    required this.requests,
    required this.searchResults,
    required this.requestedUserIds,
    required this.searchQuery,
  });

  FriendState copyWith({
    List<DummyUser>? friends,
    List<DummyFriendRequest>? requests,
    List<DummyUser>? searchResults,
    Set<String>? requestedUserIds,
    String? searchQuery,
  }) {
    return FriendState(
      friends: friends ?? this.friends,
      requests: requests ?? this.requests,
      searchResults: searchResults ?? this.searchResults,
      requestedUserIds: requestedUserIds ?? this.requestedUserIds,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class FriendController extends StateNotifier<FriendState> {
  FriendController(this._ref)
    : super(
        const FriendState(
          friends: [],
          requests: [],
          searchResults: [],
          requestedUserIds: {},
          searchQuery: '@panda',
        ),
      ) {
    _refresh();
    setSearchQuery(state.searchQuery);
  }

  final Ref _ref;

  void setSearchQuery(String query) {
    final repository = _ref.read(friendRepositoryProvider);
    state = state.copyWith(
      searchQuery: query,
      searchResults: repository.searchUsers(query),
      requestedUserIds: repository.getRequestedUserIds(),
    );
  }

  void sendFriendRequest(String userId) {
    _ref.read(friendRepositoryProvider).sendFriendRequest(userId);
    _refresh();
    setSearchQuery(state.searchQuery);
  }

  void acceptRequest(String userId) {
    _ref.read(friendRepositoryProvider).acceptRequest(userId);
    _refresh();
  }

  void rejectRequest(String userId) {
    _ref.read(friendRepositoryProvider).rejectRequest(userId);
    _refresh();
  }

  void deleteFriendship(String userId) {
    _ref.read(friendRepositoryProvider).deleteFriendship(userId);
    _refresh();
  }

  void _refresh() {
    final repository = _ref.read(friendRepositoryProvider);
    state = state.copyWith(
      friends: repository.getFriends(),
      requests: repository.getRequests(),
      requestedUserIds: repository.getRequestedUserIds(),
    );
  }
}

final friendControllerProvider =
    StateNotifierProvider<FriendController, FriendState>((ref) {
      return FriendController(ref);
    });
