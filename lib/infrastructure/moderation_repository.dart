enum ReportTargetType { question, user }

enum ContentReportReason {
  spam('spam', 'スパム'),
  harassment('harassment', '嫌がらせ'),
  inappropriate('inappropriate', '不適切な内容'),
  other('other', 'その他');

  const ContentReportReason(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

abstract class ModerationRepository {
  Future<void> reportContent({
    required ReportTargetType targetType,
    required String targetId,
    required ContentReportReason reason,
    String? detail,
  });

  Future<void> blockUser(String userId);

  Future<void> unblockUser(String userId);

  Future<Set<String>> getBlockedUserIds();
}
