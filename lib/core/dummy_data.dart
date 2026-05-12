// クラス定義のみ。データはMockRepositoryに移動。

class DummyUser {
  final String name;
  final String id;
  final int matchRate;
  const DummyUser({
    required this.name,
    required this.id,
    required this.matchRate,
  });
}

class DummyQuestion {
  final int number;
  final String category;
  final String authorName;
  final String authorUsername;
  final String text;
  final String optionA;
  final String optionB;
  final String? myAnswer;
  final int percentA;
  const DummyQuestion({
    required this.number,
    required this.category,
    this.authorName = 'ぱんだ好き',
    this.authorUsername = 'panda_love',
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

class DummyDirectThread {
  final DummyUser user;
  final String lastMessage;
  final String time;
  final int unreadCount;
  const DummyDirectThread({
    required this.user,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
  });
}

class DummyFriendRequest {
  final DummyUser user;
  final String message;
  const DummyFriendRequest({required this.user, required this.message});
}

class DummyNotification {
  final String title;
  final String body;
  final String time;
  final bool isRead;
  final String targetLabel;
  const DummyNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.targetLabel,
  });
}
