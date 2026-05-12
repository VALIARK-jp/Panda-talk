import '../../core/dummy_data.dart';

class MockMessageRepository {
  final Map<String, List<DummyMessage>> _directMessages = {
    'kotaro_123': [
      const DummyMessage(text: '今日の質問見た？俺らまた一致してたね', isMe: true, time: '12:20'),
      const DummyMessage(
        text: '見た見た！外出派そろいだったね！嬉しい😊',
        isMe: false,
        time: '12:20',
      ),
      const DummyMessage(text: 'ほんとだね〜価値観近いかも！', isMe: true, time: '12:32'),
      const DummyMessage(
        text: 'もっと質問答えてもっと一致率上げよう🔥',
        isMe: false,
        time: '12:33',
      ),
    ],
  };

  final Map<String, List<DummyMessage>> _groupMessages = {
    'ほぼ同じパンダ部屋': [
      const DummyMessage(
        text: '今日の質問おもしろかったね！',
        isMe: false,
        time: '12:40',
        senderName: 'こうたろう',
      ),
      const DummyMessage(
        text: 'わかる〜！みんな外出派だったの嬉しい😊',
        isMe: false,
        time: '12:41',
        senderName: 'まなみ',
      ),
      const DummyMessage(
        text: 'ほんと価値観近いわ笑',
        isMe: false,
        time: '12:41',
        senderName: 'ゆうき',
      ),
      const DummyMessage(text: '次はどっち派トークしよう？', isMe: true, time: '12:42'),
    ],
  };

  List<DummyDirectThread> getDirectThreads() {
    return const [
      DummyDirectThread(
        user: DummyUser(name: 'こうたろう', id: 'kotaro_123', matchRate: 92),
        lastMessage: '今日の質問見た？俺らまた一致してたね',
        time: '12:20',
        unreadCount: 2,
      ),
      DummyDirectThread(
        user: DummyUser(name: 'まなみ', id: 'manami_456', matchRate: 88),
        lastMessage: '次の質問も答えてみるね',
        time: '昨日',
      ),
    ];
  }

  Future<List<DummyMessage>> getGroupMessages(String groupId) async {
    return List.unmodifiable(
      _groupMessages[groupId] ?? _defaultGroupMessages(),
    );
  }

  Future<List<DummyMessage>> getDirectMessages(String userId) async {
    return List.unmodifiable(
      _directMessages[userId] ?? _defaultDirectMessages(),
    );
  }

  void sendDirectMessage(String userId, String text) {
    final messages = _directMessages.putIfAbsent(
      userId,
      _defaultDirectMessages,
    );
    messages.add(DummyMessage(text: text, isMe: true, time: '今'));
  }

  void sendGroupMessage(String groupId, String text) {
    final messages = _groupMessages.putIfAbsent(groupId, _defaultGroupMessages);
    messages.add(DummyMessage(text: text, isMe: true, time: '今'));
  }

  List<DummyMessage> _defaultDirectMessages() {
    return [
      const DummyMessage(text: '今日の質問見た？俺らまた一致してたね', isMe: true, time: '12:20'),
      const DummyMessage(
        text: '見た見た！外出派そろいだったね！嬉しい😊',
        isMe: false,
        time: '12:20',
      ),
    ];
  }

  List<DummyMessage> _defaultGroupMessages() {
    return [
      const DummyMessage(
        text: '今日の質問おもしろかったね！',
        isMe: false,
        time: '12:40',
        senderName: 'こうたろう',
      ),
      const DummyMessage(text: '次はどっち派トークしよう？', isMe: true, time: '12:42'),
    ];
  }
}
