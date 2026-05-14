import '../../core/dummy_data.dart';
import '../group_repository.dart';

class MockGroupRepository implements GroupRepository {
  @override
  Future<List<DummyGroup>> getGroups() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      const DummyGroup(
        id: 'ほぼ同じパンダ部屋',
        name: 'ほぼ同じパンダ部屋',
        avgMatchRate: 98,
        members: ['自分', 'こうたろう', 'まなみ', 'ゆうき'],
        type: 'high',
      ),
      const DummyGroup(
        id: 'カフェ好きパンダ',
        name: 'カフェ好きパンダ',
        avgMatchRate: 85,
        members: ['自分', 'さくら', 'たけし'],
        type: 'middle',
      ),
      const DummyGroup(
        id: '真逆パンダ部屋',
        name: '真逆パンダ部屋',
        avgMatchRate: 32,
        members: ['たくみ', 'あやか', 'ゆうすけ'],
        type: 'low',
      ),
    ];
  }
}
