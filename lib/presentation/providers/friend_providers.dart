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

class FriendController extends AsyncNotifier<FriendState> {
  @override
  Future<FriendState> build() async {
    final repository = ref.read(friendRepositoryProvider);
    final friends = await repository.getFriends();
    final requests = await repository.getRequests();
    final requestedUserIds = await repository.getRequestedUserIds();
    final searchResults = await repository.searchUsers('@panda');

    return FriendState(
      friends: friends,
      requests: requests,
      searchResults: searchResults,
      requestedUserIds: requestedUserIds,
      searchQuery: '@panda',
    );
  }

  Future<void> setSearchQuery(String query) async {
    final prev = state.value;
    if (prev == null) return;

    state = const AsyncValue.loading();
    try {
      final repository = ref.read(friendRepositoryProvider);
      final searchResults = await repository.searchUsers(query);
      final requestedUserIds = await repository.getRequestedUserIds();

      state = AsyncValue.data(prev.copyWith(
        searchQuery: query,
        searchResults: searchResults,
        requestedUserIds: requestedUserIds,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendFriendRequest(String userId) async {
    final prev = state.value;
    if (prev == null) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(friendRepositoryProvider).sendFriendRequest(userId);
      await _refresh(prev);
      await setSearchQuery(prev.searchQuery);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      ref.invalidateSelf();
    }
  }

  Future<void> acceptRequest(String userId) async {
    final prev = state.value;
    if (prev == null) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(friendRepositoryProvider).acceptRequest(userId);
      await _refresh(prev);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      ref.invalidateSelf();
    }
  }

  Future<void> rejectRequest(String userId) async {
    final prev = state.value;
    if (prev == null) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(friendRepositoryProvider).rejectRequest(userId);
      await _refresh(prev);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      ref.invalidateSelf();
    }
  }

  Future<void> deleteFriendship(String userId) async {
    final prev = state.value;
    if (prev == null) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(friendRepositoryProvider).deleteFriendship(userId);
      await _refresh(prev);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      ref.invalidateSelf();
    }
  }

  Future<void> _refresh(FriendState prev) async {
    final repository = ref.read(friendRepositoryProvider);
    final friends = await repository.getFriends();
    final requests = await repository.getRequests();
    final requestedUserIds = await repository.getRequestedUserIds();

    state = AsyncValue.data(prev.copyWith(
      friends: friends,
      requests: requests,
      requestedUserIds: requestedUserIds,
    ));
  }
}

final friendControllerProvider =
    AsyncNotifierProvider<FriendController, FriendState>(
  FriendController.new,
);
