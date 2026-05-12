import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mock/mock_question_repository.dart';
import '../mock/mock_match_repository.dart';
import '../mock/mock_group_repository.dart';
import '../mock/mock_message_repository.dart';
import '../mock/mock_friend_repository.dart';
import '../mock/mock_notification_repository.dart';
import '../mock/mock_settings_repository.dart';
import '../mock/mock_comment_repository.dart';
import '../mock/mock_profile_repository.dart';

// ここを ApiXxxRepository() に変えるだけでAPI実装に切り替わる
final questionRepositoryProvider = Provider((ref) => MockQuestionRepository());
final matchRepositoryProvider = Provider((ref) => MockMatchRepository());
final groupRepositoryProvider = Provider((ref) => MockGroupRepository());
final messageRepositoryProvider = Provider((ref) => MockMessageRepository());
final friendRepositoryProvider = Provider((ref) => MockFriendRepository());
final notificationRepositoryProvider = Provider(
  (ref) => MockNotificationRepository(),
);
final settingsRepositoryProvider = Provider((ref) => MockSettingsRepository());
final commentRepositoryProvider = Provider((ref) => MockCommentRepository());
final profileRepositoryProvider = Provider((ref) => MockProfileRepository());
