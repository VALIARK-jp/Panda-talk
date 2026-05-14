import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_question_repository.dart';
import '../mock/mock_question_repository.dart';
import '../mock/mock_match_repository.dart';
import '../mock/mock_group_repository.dart';
import '../mock/mock_message_repository.dart';
import '../mock/mock_friend_repository.dart';
import '../mock/mock_notification_repository.dart';
import '../mock/mock_settings_repository.dart';
import '../mock/mock_comment_repository.dart';
import '../mock/mock_profile_repository.dart';
import '../profile_repository.dart';
import '../api/api_profile_repository.dart';
import '../match_repository.dart';
import '../api/api_match_repository.dart';
import '../question_repository.dart';
import '../friend_repository.dart';
import '../api/api_friend_repository.dart';
import '../comment_repository.dart';
import '../api/api_comment_repository.dart';

const _useApiRepositories = bool.fromEnvironment(
  'PANDA_TALK_USE_API',
  defaultValue: true,
);

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  if (_useApiRepositories) return ApiQuestionRepository();
  return MockQuestionRepository();
});
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  if (_useApiRepositories) return ApiMatchRepository();
  return MockMatchRepository();
});
final groupRepositoryProvider = Provider((ref) => MockGroupRepository());
final messageRepositoryProvider = Provider((ref) => MockMessageRepository());
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  if (_useApiRepositories) return ApiFriendRepository();
  return MockFriendRepository();
});
final notificationRepositoryProvider = Provider(
  (ref) => MockNotificationRepository(),
);
final settingsRepositoryProvider = Provider((ref) => MockSettingsRepository());
final commentRepositoryProvider = Provider((ref) => MockCommentRepository());
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (_useApiRepositories) return ApiProfileRepository();
  return MockProfileRepository();
});
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  if (_useApiRepositories) return ApiCommentRepository();
  return MockCommentRepository();
});
final profileRepositoryProvider = Provider((ref) => MockProfileRepository());
