import '../../core/dummy_data.dart';
import '../question_repository.dart';

class MockQuestionRepository implements QuestionRepository {
  final List<DummyQuestion> _feedQuestions = [
    const DummyQuestion(
      number: 1,
      category: '生活',
      authorName: 'こうたろう',
      authorUsername: 'kotaro_123',
      text: '休日は外出派？家派？',
      optionA: '外出派',
      optionB: '家派',
      percentA: 64,
      likeCount: 12,
      commentCount: 5,
    ),
    const DummyQuestion(
      number: 2,
      category: '生活',
      authorName: 'まなみ',
      authorUsername: 'manami_456',
      text: '朝型？夜型？',
      optionA: '朝型',
      optionB: '夜型',
      percentA: 38,
      likeCount: 8,
      commentCount: 3,
    ),
    const DummyQuestion(
      number: 3,
      category: '性格',
      authorName: 'ゆうき',
      authorUsername: 'yuuki_789',
      text: 'LINEは即レス派？溜める派？',
      optionA: '即レス派',
      optionB: '溜める派',
      percentA: 55,
      likeCount: 24,
      commentCount: 9,
    ),
    const DummyQuestion(
      number: 4,
      category: '恋愛',
      authorName: 'りな',
      authorUsername: 'rina_222',
      text: '恋愛は追う派？追われる派？',
      optionA: '追う派',
      optionB: '追われる派',
      percentA: 42,
      likeCount: 6,
      commentCount: 2,
    ),
  ];

  final List<DummyQuestion> _myQuestions = [
    const DummyQuestion(
      number: 5,
      category: '食べ物',
      authorName: 'ぱんだちゃん',
      authorUsername: 'panda_123',
      text: '朝はパン派？ごはん派？',
      optionA: 'パン派',
      optionB: 'ごはん派',
      percentA: 47,
    ),
    const DummyQuestion(
      number: 6,
      category: '生活',
      authorName: 'ぱんだちゃん',
      authorUsername: 'panda_123',
      text: '連絡は電話派？チャット派？',
      optionA: '電話派',
      optionB: 'チャット派',
      percentA: 24,
    ),
  ];

  @override
  Future<List<DummyQuestion>> getFeedQuestions() async {
    return List.unmodifiable([..._myQuestions, ..._feedQuestions]);
  }

  @override
  Future<DummyQuestion> getCurrentQuestion() async {
    return const DummyQuestion(
      number: 1,
      category: '生活',
      authorName: 'こうたろう',
      authorUsername: 'kotaro_123',
      text: '休日は外出派？家派？',
      optionA: '外出派',
      optionB: '家派',
      percentA: 64,
    );
  }

  @override
  Future<List<DummyQuestion>> getHistory() async {
    return [
      const DummyQuestion(
        number: 1,
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
        number: 2,
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
        number: 3,
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
        number: 4,
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
        number: 7,
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

  @override
  Future<List<DummyQuestion>> search(String keyword) async {
    return [
      const DummyQuestion(
        number: 8,
        category: '恋愛',
        authorName: 'りな',
        authorUsername: 'rina_222',
        text: '恋愛は追う派？追われる派？',
        optionA: '追う派',
        optionB: '追われる派',
        percentA: 42,
      ),
      const DummyQuestion(
        number: 9,
        category: '恋愛',
        authorName: 'あやか',
        authorUsername: 'ayaka_012',
        text: '束縛する系？される系？',
        optionA: 'する系',
        optionB: 'される系',
        percentA: 38,
      ),
      const DummyQuestion(
        number: 10,
        category: '恋愛',
        authorName: 'しょうた',
        authorUsername: 'shota_345',
        text: '告白は自分から？相手から？',
        optionA: '自分から',
        optionB: '相手から',
        percentA: 55,
      ),
      const DummyQuestion(
        number: 11,
        category: '恋愛',
        authorName: 'まなみ',
        authorUsername: 'manami_456',
        text: '好きになるのは見た目？中身？',
        optionA: '見た目',
        optionB: '中身',
        percentA: 29,
      ),
      const DummyQuestion(
        number: 12,
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

  @override
  Future<List<DummyQuestion>> getMyQuestions() async {
    return List.unmodifiable(_myQuestions);
  }

  @override
  Future<void> postQuestion({
    required String text,
    required String optionA,
    required String optionB,
    required String category,
  }) async {
    final nextNumber = _myQuestions.isEmpty
        ? 1
        : _myQuestions.map((q) => q.number).reduce((a, b) => a > b ? a : b) + 1;
    _myQuestions.insert(
      0,
      DummyQuestion(
        number: nextNumber,
        category: category,
        authorName: 'ぱんだちゃん',
        authorUsername: 'panda_123',
        text: text,
        optionA: optionA,
        optionB: optionB,
        percentA: 50,
      ),
    );
  }

  @override
  Future<void> editQuestion({
    required int number,
    required String text,
    required String optionA,
    required String optionB,
    required String category,
  }) async {
    final index = _myQuestions.indexWhere(
      (question) => question.number == number,
    );
    if (index == -1) return;
    _myQuestions[index] = _myQuestions[index].copyWith(
      text: text,
      optionA: optionA,
      optionB: optionB,
      category: category,
    );
  }

  @override
  Future<void> deleteQuestion(int number) async {
    _myQuestions.removeWhere((question) => question.number == number);
  }

  @override
  Future<int> answerQuestion({
    required DummyQuestion question,
    required String selectedOption,
  }) async {
    return question.percentA;
  }

  @override
  Future<int> fetchQuestionPercentA(String questionId) async => 50;
}
