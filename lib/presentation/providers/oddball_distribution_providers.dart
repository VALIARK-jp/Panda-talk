import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/oddball_distribution.dart';
import '../../infrastructure/providers/repositories.dart';

final oddballDistributionProvider =
    FutureProvider.family<OddballScoreDistribution, int>((ref, score) {
  return ref.read(profileRepositoryProvider).getOddballDistribution(score: score);
});
