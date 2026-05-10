class DummyUser {
  final String name;
  final String id;
  final int matchRate;

  const DummyUser({required this.name, required this.id, required this.matchRate});
}

class DummyQuestion {
  final int number;
  final String category;
  final String text;
  final String optionA;
  final String optionB;
  final String? myAnswer;
  final int percentA;

  const DummyQuestion({
    required this.number,
    required this.category,
    required this.text,
    required this.optionA,
    required this.optionB,
    this.myAnswer,
    required this.percentA,
  });
}

class DummyMessage {
  final String text;
  final bool isMe;
  final String time;
  final String? senderName;

  const DummyMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.senderName,
  });
}

class DummyGroup {
  final String name;
  final int avgMatchRate;
  final List<String> members;
  final String type;

  const DummyGroup({
    required this.name,
    required this.avgMatchRate,
    required this.members,
    required this.type,
  });
}

final similarUsers = [
  DummyUser(name: 'こうたろう', id: 'kotaro_123', matchRate: 92),
  DummyUser(name: 'まなみ', id: 'manami_456', matchRate: 88),
  DummyUser(name: 'ゆうき', id: 'yuuki_789', matchRate: 84),
  DummyUser(name: 'あやか', id: 'ayaka_012', matchRate: 77),
  DummyUser(name: 'しょうた', id: 'shota_345', matchRate: 71),
];

final oppositeUsers = [
  DummyUser(name: 'たくみ', id: 'takumi_111', matchRate: 29),
  DummyUser(name: 'りな', id: 'rina_222', matchRate: 31),
  DummyUser(name: 'しょう', id: 'sho_333', matchRate: 33),
  DummyUser(name: 'けんじ', id: 'kenji_444', matchRate: 35),
  DummyUser(name: 'ゆうすけ', id: 'yusuke_555', matchRate: 37),
];

final middleUsers = [
  DummyUser(name: 'さくら', id: 'sakura_001', matchRate: 51),
  DummyUser(name: 'だいき', id: 'daiki_002', matchRate: 49),
  DummyUser(name: 'みほ', id: 'miho_003', matchRate: 52),
  DummyUser(name: 'けいた', id: 'keita_004', matchRate: 48),
  DummyUser(name: 'なな', id: 'nana_005', matchRate: 50),
];

final historyQuestions = [
  DummyQuestion(number: 1256, category: '生活', text: '休日は外出派？家派？', optionA: '外出派', optionB: '家派', myAnswer: '外出派', percentA: 64),
  DummyQuestion(number: 1255, category: '生活', text: '朝型？夜型？', optionA: '朝型', optionB: '夜型', myAnswer: '夜型', percentA: 38),
  DummyQuestion(number: 1254, category: '性格', text: 'LINEは即レス派？溜める派？', optionA: '即レス派', optionB: '溜める派', myAnswer: '即レス派', percentA: 55),
  DummyQuestion(number: 1253, category: '恋愛', text: '恋愛は追う派？追われる派？', optionA: '追う派', optionB: '追われる派', myAnswer: '追う派', percentA: 42),
  DummyQuestion(number: 1252, category: '旅行', text: '旅行は計画派？ノープラン派？', optionA: '計画派', optionB: 'ノープラン派', myAnswer: '計画派', percentA: 61),
];

final currentQuestion = DummyQuestion(
  number: 1256,
  category: '生活',
  text: '休日は外出派？家派？',
  optionA: '外出派',
  optionB: '家派',
  percentA: 64,
);

final directMessages = [
  DummyMessage(text: '今日の質問見た？俺らまた一致してたね', isMe: true, time: '12:20'),
  DummyMessage(text: '見た見た！外出派そろいだったね！嬉しい😊', isMe: false, time: '12:20'),
  DummyMessage(text: 'ほんとだね〜価値観近いかも！', isMe: true, time: '12:32'),
  DummyMessage(text: 'もっと質問答えてもっと一致率上げよう🔥', isMe: false, time: '12:33'),
];

final groupMessages = [
  DummyMessage(text: '今日の質問おもしろかったね！', isMe: false, time: '12:40', senderName: 'こうたろう'),
  DummyMessage(text: 'わかる〜！みんな外出派だったの嬉しい😊', isMe: false, time: '12:41', senderName: 'まなみ'),
  DummyMessage(text: 'ほんと価値観近いわ笑', isMe: false, time: '12:41', senderName: 'ゆうき'),
  DummyMessage(text: '次はどっち派トークしよう？', isMe: true, time: '12:42'),
];

final groups = [
  DummyGroup(name: 'ほぼ同じパンダ部屋', avgMatchRate: 91, members: ['こうたろう', 'まなみ', 'ゆうき'], type: 'high'),
  DummyGroup(name: 'なんか似てるパンダ部屋', avgMatchRate: 62, members: ['りな', 'しょう', 'けんじ'], type: 'middle'),
  DummyGroup(name: '真逆パンダ部屋', avgMatchRate: 32, members: ['たくみ', 'あやか', 'ゆうすけ'], type: 'low'),
];

final compareAnswers = [
  {'question': '休日は外出派？家派？', 'mine': '外出派', 'theirs': '外出派', 'match': true},
  {'question': '朝型？夜型？', 'mine': '夜型', 'theirs': '夜型', 'match': true},
  {'question': 'LINEは即レス派？溜める派？', 'mine': '即レス派', 'theirs': '即レス派', 'match': true},
  {'question': '旅行は計画派？ノープラン派？', 'mine': '計画派', 'theirs': 'ノープラン派', 'match': false},
];

final searchResults = [
  DummyQuestion(number: 1234, category: '恋愛', text: '恋愛は追う派？追われる派？', optionA: '追う派', optionB: '追われる派', percentA: 42),
  DummyQuestion(number: 1156, category: '恋愛', text: '束縛する系？される系？', optionA: 'する系', optionB: 'される系', percentA: 38),
  DummyQuestion(number: 1098, category: '恋愛', text: '告白は自分から？相手から？', optionA: '自分から', optionB: '相手から', percentA: 55),
  DummyQuestion(number: 1055, category: '恋愛', text: '好きになるのは見た目？中身？', optionA: '見た目', optionB: '中身', percentA: 29),
  DummyQuestion(number: 1023, category: '恋愛', text: '恋人とは毎日会う？会わない？', optionA: '毎日会う', optionB: '会わない', percentA: 48),
];
