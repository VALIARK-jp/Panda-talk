import '../moderation_repository.dart';

class MockModerationRepository implements ModerationRepository {
  final Set<String> _blockedUserIds = {};

  @override
  Future<void> reportContent({
    required ReportTargetType targetType,
    required String targetId,
    required ContentReportReason reason,
    String? detail,
  }) async {}

  @override
  Future<void> blockUser(String userId) async {
    _blockedUserIds.add(userId);
  }

  @override
  Future<void> unblockUser(String userId) async {
    _blockedUserIds.remove(userId);
  }

  @override
  Future<Set<String>> getBlockedUserIds() async {
    return Set.unmodifiable(_blockedUserIds);
  }
}
