import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/moderation_repository.dart';
import '../../infrastructure/providers/repositories.dart';

class ModerationState {
  const ModerationState({this.blockedUserIds = const {}});

  final Set<String> blockedUserIds;

  bool isBlocked(String userId) => blockedUserIds.contains(userId);

  ModerationState copyWith({Set<String>? blockedUserIds}) {
    return ModerationState(blockedUserIds: blockedUserIds ?? this.blockedUserIds);
  }
}

final moderationControllerProvider =
    AsyncNotifierProvider<ModerationController, ModerationState>(
      ModerationController.new,
    );

class ModerationController extends AsyncNotifier<ModerationState> {
  @override
  Future<ModerationState> build() async {
    final repository = ref.read(moderationRepositoryProvider);
    final blockedUserIds = await repository.getBlockedUserIds();
    return ModerationState(blockedUserIds: blockedUserIds);
  }

  Future<void> reportContent({
    required ReportTargetType targetType,
    required String targetId,
    required ContentReportReason reason,
    String? detail,
  }) async {
    await ref.read(moderationRepositoryProvider).reportContent(
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      detail: detail,
    );
  }

  Future<void> blockUser(String userId) async {
    await ref.read(moderationRepositoryProvider).blockUser(userId);
    final current = state.valueOrNull ?? const ModerationState();
    state = AsyncData(
      current.copyWith(
        blockedUserIds: {...current.blockedUserIds, userId},
      ),
    );
  }

  Future<void> unblockUser(String userId) async {
    await ref.read(moderationRepositoryProvider).unblockUser(userId);
    final current = state.valueOrNull ?? const ModerationState();
    final next = {...current.blockedUserIds}..remove(userId);
    state = AsyncData(current.copyWith(blockedUserIds: next));
  }
}
