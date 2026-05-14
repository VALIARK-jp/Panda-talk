import '../core/dummy_data.dart';

abstract class MatchRepository {
  Future<List<DummyUser>> getSimilar();
  Future<List<DummyUser>> getOpposite();
  Future<List<DummyUser>> getMiddle();
  Future<List<Map<String, Object>>> getCompareAnswers(String userId);
}
