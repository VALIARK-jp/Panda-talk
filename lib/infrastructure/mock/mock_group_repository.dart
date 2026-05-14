import '../../core/dummy_data.dart';
import '../group_repository.dart';

class MockGroupRepository implements GroupRepository {
  @override
  Future<List<DummyGroup>> getGroups() async {
    return [
      const DummyGroup(
        name: 'ほぼ同じパンダ部屋',
        avgMatchRate: 91,
        members: ['こうたろう', 'まなみ', 'ゆうき'],
        type: 'high',
      ),
      const DummyGroup(
        name: 'なんか似てるパンダ部屋',
        avgMatchRate: 62,
        members: ['りな', 'しょう', 'けんじ'],
        type: 'middle',
      ),
      const DummyGroup(
        name: '真逆パンダ部屋',
        avgMatchRate: 32,
        members: ['たくみ', 'あやか', 'ゆうすけ'],
        type: 'low',
      ),
    ];
  }
}
