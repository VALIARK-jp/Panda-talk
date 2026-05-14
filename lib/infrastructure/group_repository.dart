import '../../core/dummy_data.dart';

abstract class GroupRepository {
  Future<List<DummyGroup>> getGroups();
}
