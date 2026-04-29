class Reaction {
  final String id;
  final String memoId;
  final String emoji;
  final String userId;
  final DateTime createdAt;

  Reaction({
    required this.id,
    required this.memoId,
    required this.emoji,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memo_id': memoId,
      'emoji': emoji,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Reaction.fromMap(Map<String, dynamic> map) {
    return Reaction(
      id: map['id'].toString(),
      memoId: map['memo_id'].toString(),
      emoji: map['emoji'] ?? '👍',
      userId: map['user_id'] ?? 'local',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class ReactionGroup {
  final String emoji;
  final int count;
  final bool reactedByMe;

  ReactionGroup({
    required this.emoji,
    required this.count,
    required this.reactedByMe,
  });
}
