class Comment {
  final String id;
  final String memoId;
  final String content;
  final String authorName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.memoId,
    required this.content,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memo_id': memoId,
      'content': content,
      'author_name': authorName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'].toString(),
      memoId: map['memo_id'].toString(),
      content: map['content'] ?? '',
      authorName: map['author_name'] ?? 'Anonymous',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
