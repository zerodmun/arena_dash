import 'dart:convert';

class Memo {
  final String id;
  final String content;
  final String visibility;
  final List<String> tags;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Memo({
    required this.id,
    required this.content,
    this.visibility = 'PRIVATE',
    this.tags = const [],
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'visibility': visibility,
      'tags': jsonEncode(tags),
      'is_pinned': isPinned ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Memo.fromMap(Map<String, dynamic> map) {
    List<String> parseTags(dynamic tags) {
      if (tags == null) return [];
      if (tags is String) {
        try {
          return List<String>.from(jsonDecode(tags));
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    return Memo(
      id: map['id'].toString(),
      content: map['content'] ?? '',
      visibility: map['visibility'] ?? 'PRIVATE',
      tags: parseTags(map['tags']),
      isPinned: map['is_pinned'] == 1 || map['is_pinned'] == true,
      isArchived: map['is_archived'] == 1 || map['is_archived'] == true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Memo copyWith({
    String? id,
    String? content,
    String? visibility,
    List<String>? tags,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Memo(
      id: id ?? this.id,
      content: content ?? this.content,
      visibility: visibility ?? this.visibility,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get title {
    final firstLine = content.split('\n').first.trim();
    if (firstLine.startsWith('#')) {
      return firstLine.replaceAll(RegExp(r'^#+\s*'), '').trim();
    }
    return firstLine.length > 50 ? '${firstLine.substring(0, 50)}...' : firstLine;
  }

  String get preview {
    var text = content.replaceAll(RegExp(r'#+\s*|[*_`~]'), '').trim();
    return text.length > 200 ? '${text.substring(0, 200)}...' : text;
  }

  static List<String> extractTagsFromContent(String content) {
    final tagRegex = RegExp(r'(?<=^|\s)#(\w+)');
    return tagRegex.allMatches(content).map((m) => m.group(1)!).toSet().toList();
  }
}
