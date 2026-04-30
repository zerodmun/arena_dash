import 'dart:convert';

class Task {
  final String id;
  final String memoId;
  final String title;
  final bool isCompleted;
  final DateTime? deadline;
  final bool notificationSent;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.memoId,
    required this.title,
    this.isCompleted = false,
    this.deadline,
    this.notificationSent = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memo_id': memoId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'deadline': deadline?.toIso8601String(),
      'notification_sent': notificationSent ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'].toString(),
      memoId: map['memo_id'].toString(),
      title: map['title'] ?? '',
      isCompleted: map['is_completed'] == 1 || map['is_completed'] == true,
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      notificationSent: map['notification_sent'] == 1 || map['notification_sent'] == true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Task copyWith({
    String? id,
    String? memoId,
    String? title,
    bool? isCompleted,
    DateTime? deadline,
    bool? notificationSent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      memoId: memoId ?? this.memoId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      deadline: deadline ?? this.deadline,
      notificationSent: notificationSent ?? this.notificationSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOverdue {
    if (deadline == null || isCompleted) return false;
    return DateTime.now().isAfter(deadline!);
  }

  String get deadlineFormatted {
    if (deadline == null) return '';
    final date = '${deadline!.day}/${deadline!.month}/${deadline!.year}';
    final time = '${deadline!.hour.toString().padLeft(2, '0')}:${deadline!.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
