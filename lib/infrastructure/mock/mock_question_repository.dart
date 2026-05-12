import '../../core/dummy_data.dart';

class MockQuestionRepository {
  Future<List<DummyQuestion>> getFeedQuestions() async {
    return [
      const DummyQuestion(
        number: 1256,
        category: '生活',
        authorName: 'こうたろう',
        authorUsername: 'kotaro_123',
        text: '休日は外出派？家派？',
        optionA: '外出派',
        optionB: '家派',
        percentA: 64,
      ),
      const DummyQuestion(
        number: 1255,
        category: '生活',
        authorName: 'まなみ',
        authorUsername: 'manami_456',
        text: '朝型？夜型？',
        optionA: '朝型',
        optionB: '夜型',
        percentA: 38,
      ),
      const DummyQuestion(
        number: 1254,
        category: '性格',
        authorName: 'ゆうき',
        authorUsername: 'yuuki_789',
        text: 'LINEは即レス派？溜める派？',
        optionA: '即レス派',
        optionB: '溜める派',
        percentA: 55,
      ),
      const DummyQuestion(
        number: 1253,
        category: '恋愛',
        authorName: 'りな',
        authorUsername: 'rina_222',
        text: '恋愛は追う派？追われる派？',
        optionA: '追う派',
        optionB: '追われる派',
        percentA: 42,
      ),
    ];
  }

  Future<DummyQuestion> getCurrentQuestion() async {
    return const DummyQuestion(
      number: 1256,
      category: '生活',
      authorName: 'こうたろう',
      authorUsername: 'kotaro_123',
      text: '休日は外出派？家派？',
      optionA: '外出派',
      optionB: '家派',
      percentA: 64,
    );
  }

  Future<List<DummyQuestion>> getHistory() async {
    return [
      const DummyQuestion(
        number: 1256,
        category: '生活',
        authorName: 'こうたろう',
        authorUsername: 'kotaro_123',
        text: '休日は外出派？家派？',
        optionA: '外出派',
        optionB: '家派',
        myAnswer: '外出派',
        percentA: 64,
      ),
      const DummyQuestion(
        number: 1255,
        category: '生活',
        authorName: 'まなみ',
        authorUsername: 'manami_456',
        text: '朝型？夜型？',
        optionA: '朝型',
        optionB: '夜型',
        myAnswer: '夜型',
        percentA: 38,
      ),
      const DummyQuestion(
        number: 1254,
        category: '性格',
        authorName: 'ゆうき',
        authorUsername: 'yuuki_789',
        text: 'LINEは即レス派？溜める派？',
        optionA: '即レス派',
        optionB: '溜める派',
        myAnswer: '即レス派',
        percentA: 55,
      ),
      const DummyQuestion(
        number: 1253,
        category: '恋愛',
        authorName: 'りな',
        authorUsername: 'rina_222',
        text: '恋愛は追う派？追われる派？',
        optionA: '追う派',
        optionB: '追われる派',
        myAnswer: '追う派',
        percentA: 42,
      ),
      const DummyQuestion(
        number: 1252,
        category: '旅行',
        authorName: 'たくみ',
        authorUsername: 'takumi_111',
        text: '旅行は計画派？ノープラン派？',
        optionA: '計画派',
        optionB: 'ノープラン派',
        myAnswer: '計画派',
        percentA: 61,
      ),
    ];
  }

  Future<List<DummyQuestion>> search(String keyword) async {
    return [
      const DummyQuestion(
        number: 1234,
        category: '恋愛',
        authorName: 'りな',
        authorUsername: 'rina_222',
        text: '恋愛は追う派？追われる派？',
        optionA: '追う派',
        optionB: '追われる派',
        percentA: 42,
      ),
      const DummyQuestion(
        number: 1156,
        category: '恋愛',
        authorName: 'あやか',
        authorUsername: 'ayaka_012',
        text: '束縛する系？される系？',
        optionA: 'する系',
        optionB: 'される系',
        percentA: 38,
      ),
      const DummyQuestion(
        number: 1098,
        category: '恋愛',
        authorName: 'しょうた',
        authorUsername: 'shota_345',
        text: '告白は自分から？相手から？',
        optionA: '自分から',
        optionB: '相手から',
        percentA: 55,
      ),
      const DummyQuestion(
        number: 1055,
        category: '恋愛',
        authorName: 'まなみ',
        authorUsername: 'manami_456',
        text: '好きになるのは見た目？中身？',
        optionA: '見た目',
        optionB: '中身',
        percentA: 29,
      ),
      const DummyQuestion(
        number: 1023,
        category: '恋愛',
        authorName: 'ゆうき',
        authorUsername: 'yuuki_789',
        text: '恋人とは毎日会う？会わない？',
        optionA: '毎日会う',
        optionB: '会わない',
        percentA: 48,
      ),
    ];
  }
}
