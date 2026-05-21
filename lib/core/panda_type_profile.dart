import 'dummy_data.dart';
import 'panda_type.dart';

extension DummyProfilePandaType on DummyProfile {
  PandaTypeResult? get pandaTypeResult {
    if (!hasDiagnosis16 || pandaTypeSlug == null) return null;
    final def = PandaTypeCatalog.bySlug(pandaTypeSlug!);
    return PandaTypeResult(
      slug: pandaTypeSlug!,
      displayName: def?.displayName ?? pandaTypeSlug!,
      tagline: def?.tagline ?? '',
      scores: PandaTypeScores(
        affection: typeAffectionPct!,
        thinking: typeThinkingPct!,
        action: typeActionPct!,
        life: typeLifePct!,
      ),
      diagnosedAt: diagnosed16At,
    );
  }
}
