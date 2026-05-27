// クラス定義のみ。データはMockRepositoryに移動。

class DummyUser {
  final String name;
  final String id;
  final int matchRate;
  final String? avatarUrl;
  const DummyUser({
    required this.name,
    required this.id,
    required this.matchRate,
    this.avatarUrl,
  });
}

class DummyQuestion {
  final String? apiId;
  final int number;
  final String category;
  final String authorName;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String text;
  final String optionA;
  final String optionB;
  final String? myAnswer;
  final int percentA;
  final int countA;
  final int countB;
  final int likeCount;
  final int commentCount;
  const DummyQuestion({
    this.apiId,
    required this.number,
    required this.category,
    this.authorName = 'ぱんだ好き',
    this.authorUsername = 'panda_love',
    this.authorAvatarUrl,
    required this.text,
    required this.optionA,
    required this.optionB,
    this.myAnswer,
    required this.percentA,
    this.countA = 0,
    this.countB = 0,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  DummyQuestion copyWith({
    String? category,
    String? text,
    String? optionA,
    String? optionB,
    String? myAnswer,
    int? percentA,
    int? countA,
    int? countB,
    int? likeCount,
    int? commentCount,
  }) {
    return DummyQuestion(
      apiId: apiId,
      number: number,
      category: category ?? this.category,
      authorName: authorName,
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      text: text ?? this.text,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      myAnswer: myAnswer ?? this.myAnswer,
      percentA: percentA ?? this.percentA,
      countA: countA ?? this.countA,
      countB: countB ?? this.countB,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }
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
  final String id;
  final String name;
  final int avgMatchRate;
  final List<String> members;
  final String type;
  const DummyGroup({
    required this.id,
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
  final String id;
  final String title;
  final String body;
  final String time;
  final bool isRead;
  final String targetLabel;
  const DummyNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.targetLabel,
  });

  DummyNotification copyWith({bool? isRead}) {
    return DummyNotification(
      id: id,
      title: title,
      body: body,
      time: time,
      isRead: isRead ?? this.isRead,
      targetLabel: targetLabel,
    );
  }
}

class DummyComment {
  final String id;
  final String option;
  final String body;
  final int likes;
  final bool isMine;
  final bool likedByMe;

  const DummyComment({
    required this.id,
    required this.option,
    required this.body,
    required this.likes,
    required this.isMine,
    this.likedByMe = false,
  });

  DummyComment copyWith({int? likes, bool? likedByMe}) {
    return DummyComment(
      id: id,
      option: option,
      body: body,
      likes: likes ?? this.likes,
      isMine: isMine,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}

class DummyNotificationSettings {
  final bool friendRequests;
  final bool questionLikes;
  final bool messages;
  final bool groupUpdates;

  const DummyNotificationSettings({
    required this.friendRequests,
    required this.questionLikes,
    required this.messages,
    required this.groupUpdates,
  });

  DummyNotificationSettings copyWith({
    bool? friendRequests,
    bool? questionLikes,
    bool? messages,
    bool? groupUpdates,
  }) {
    return DummyNotificationSettings(
      friendRequests: friendRequests ?? this.friendRequests,
      questionLikes: questionLikes ?? this.questionLikes,
      messages: messages ?? this.messages,
      groupUpdates: groupUpdates ?? this.groupUpdates,
    );
  }
}

class DummyProfile {
  final String name;
  final String username;
  final String bio;
  final String? avatarUrl;
  final int answerCount;
  final int postCount;
  final int friendCount;
  final int oddballScore;
  final List<String> tags;
  final String? pandaTypeSlug;
  final int? typeAffectionPct;
  final int? typeThinkingPct;
  final int? typeActionPct;
  final int? typeLifePct;
  final DateTime? diagnosed16At;

  const DummyProfile({
    required this.name,
    required this.username,
    required this.bio,
    this.avatarUrl,
    required this.answerCount,
    required this.postCount,
    required this.friendCount,
    required this.oddballScore,
    required this.tags,
    this.pandaTypeSlug,
    this.typeAffectionPct,
    this.typeThinkingPct,
    this.typeActionPct,
    this.typeLifePct,
    this.diagnosed16At,
  });

  bool get hasDiagnosis16 =>
      pandaTypeSlug != null &&
      typeAffectionPct != null &&
      typeThinkingPct != null &&
      typeActionPct != null &&
      typeLifePct != null;

  DummyProfile copyWith({
    String? name,
    String? username,
    String? bio,
    String? avatarUrl,
    String? pandaTypeSlug,
    int? typeAffectionPct,
    int? typeThinkingPct,
    int? typeActionPct,
    int? typeLifePct,
    DateTime? diagnosed16At,
  }) {
    return DummyProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      answerCount: answerCount,
      postCount: postCount,
      friendCount: friendCount,
      oddballScore: oddballScore,
      tags: tags,
      pandaTypeSlug: pandaTypeSlug ?? this.pandaTypeSlug,
      typeAffectionPct: typeAffectionPct ?? this.typeAffectionPct,
      typeThinkingPct: typeThinkingPct ?? this.typeThinkingPct,
      typeActionPct: typeActionPct ?? this.typeActionPct,
      typeLifePct: typeLifePct ?? this.typeLifePct,
      diagnosed16At: diagnosed16At ?? this.diagnosed16At,
    );
  }
}
