import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';

/// 他ユーザーのプロフィール（友達でなくても閲覧可）。
final userProfileProvider = FutureProvider.family<DummyProfile, String>((
  ref,
  userId,
) {
  return ref.read(profileRepositoryProvider).getUserProfile(userId);
});
