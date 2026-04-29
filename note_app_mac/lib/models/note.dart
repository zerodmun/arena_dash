import 'dart:convert';

class Note {
  final String id;
  final String title;
  final String content;
  final String notebook;
  final List<String> tags;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String color;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.notebook = 'Personal',
    this.tags = const [],
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.color = 'default',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'notebook': notebook,
      'tags': jsonEncode(tags),
      'is_pinned': isPinned ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'color': color,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    List<String> parseTags(dynamic tags) {
      if (tags == null) return [];
      if (tags is String) {
        try {
          final decoded = jsonDecode(tags);
          return decoded is List ? List<String>.from(decoded) : [];
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    return Note(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      notebook: map['notebook'] ?? 'Personal',
      tags: parseTags(map['tags']),
      isPinned: map['is_pinned'] == 1 || map['is_pinned'] == true,
      isArchived: map['is_archived'] == 1 || map['is_archived'] == true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      color: map['color'] ?? 'default',
    );
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? notebook,
    List<String>? tags,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      notebook: notebook ?? this.notebook,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
    );
  }
}
