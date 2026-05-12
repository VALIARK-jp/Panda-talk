import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mock/mock_question_repository.dart';
import '../mock/mock_match_repository.dart';
import '../mock/mock_group_repository.dart';
import '../mock/mock_message_repository.dart';

// ここを ApiXxxRepository() に変えるだけでAPI実装に切り替わる
final questionRepositoryProvider = Provider((ref) => MockQuestionRepository());
final matchRepositoryProvider = Provider((ref) => MockMatchRepository());
final groupRepositoryProvider = Provider((ref) => MockGroupRepository());
final messageRepositoryProvider = Provider((ref) => MockMessageRepository());
