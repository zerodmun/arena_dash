import 'dart:convert';
import 'package:flutter/material.dart';

enum MemoVisibility {
  private('PRIVATE', 'Private'),
  public('PUBLIC', 'Public'),
  protected('PROTECTED', 'Protected');

  final String value;
  final String label;
  const MemoVisibility(this.value, this.label);

  static MemoVisibility fromString(String value) {
    return MemoVisibility.values.firstWhere(
      (v) => v.value == value,
      orElse: () => MemoVisibility.private,
    );
  }

  IconData get icon {
    switch (this) {
      case MemoVisibility.private: return Icons.lock_outline;
      case MemoVisibility.public: return Icons.public;
      case MemoVisibility.protected: return Icons.shield_outlined;
    }
  }
}

class Memo {
  final String id;
  final String content;
  final MemoVisibility visibility;
  final List<String> tags;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Memo({
    required this.id,
    required this.content,
    this.visibility = MemoVisibility.private,
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
      'visibility': visibility.value,
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
      visibility: map['visibility'] is MemoVisibility 
          ? map['visibility'] as MemoVisibility 
          : MemoVisibility.fromString(map['visibility']?.toString() ?? 'PRIVATE'),
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
    MemoVisibility? visibility,
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
