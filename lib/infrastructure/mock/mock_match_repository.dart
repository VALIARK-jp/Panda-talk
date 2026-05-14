import '../../core/dummy_data.dart';
import '../match_repository.dart';

class MockMatchRepository implements MatchRepository {
  @override
  Future<List<DummyUser>> getSimilar() async {
    return [
      const DummyUser(name: 'こうたろう', id: 'kotaro_123', matchRate: 92),
      const DummyUser(name: 'まなみ', id: 'manami_456', matchRate: 88),
      const DummyUser(name: 'ゆうき', id: 'yuuki_789', matchRate: 84),
      const DummyUser(name: 'あやか', id: 'ayaka_012', matchRate: 77),
      const DummyUser(name: 'しょうた', id: 'shota_345', matchRate: 71),
    ];
  }

  @override
  Future<List<DummyUser>> getOpposite() async {
    return [
      const DummyUser(name: 'たくみ', id: 'takumi_111', matchRate: 29),
      const DummyUser(name: 'りな', id: 'rina_222', matchRate: 31),
      const DummyUser(name: 'しょう', id: 'sho_333', matchRate: 33),
      const DummyUser(name: 'けんじ', id: 'kenji_444', matchRate: 35),
      const DummyUser(name: 'ゆうすけ', id: 'yusuke_555', matchRate: 37),
    ];
  }

  @override
  Future<List<DummyUser>> getMiddle() async {
    return [
      const DummyUser(name: 'さくら', id: 'sakura_001', matchRate: 51),
      const DummyUser(name: 'だいき', id: 'daiki_002', matchRate: 49),
      const DummyUser(name: 'みほ', id: 'miho_003', matchRate: 52),
      const DummyUser(name: 'けいた', id: 'keita_004', matchRate: 48),
      const DummyUser(name: 'なな', id: 'nana_005', matchRate: 50),
    ];
  }

  @override
  Future<List<Map<String, Object>>> getCompareAnswers(String userId) async {
    return [
      {'question': '休日は外出派？家派？', 'mine': '外出派', 'theirs': '外出派', 'match': true},
      {'question': '朝型？夜型？', 'mine': '夜型', 'theirs': '夜型', 'match': true},
      {
        'question': 'LINEは即レス派？溜める派？',
        'mine': '即レス派',
        'theirs': '即レス派',
        'match': true,
      },
      {
        'question': '旅行は計画派？ノープラン派？',
        'mine': '計画派',
        'theirs': 'ノープラン派',
        'match': false,
      },
    ];
  }
}
