import '../../core/dummy_data.dart';

class MockMessageRepository {
  Future<List<DummyMessage>> getGroupMessages(String groupId) async {
    return [
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
    ];
  }

  Future<List<DummyMessage>> getDirectMessages(String userId) async {
    return [
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
    ];
  }
}
