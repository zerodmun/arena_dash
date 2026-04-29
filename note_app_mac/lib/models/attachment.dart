import 'dart:io';
import 'package:flutter/material.dart';

class Attachment {
  final String id;
  final String memoId;
  final String name;
  final String path;
  final String? url;
  final String type;
  final int size;
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.memoId,
    required this.name,
    required this.path,
    this.url,
    required this.type,
    required this.size,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memo_id': memoId,
      'name': name,
      'path': path,
      'url': url,
      'type': type,
      'size': size,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'].toString(),
      memoId: map['memo_id'].toString(),
      name: map['name'] ?? '',
      path: map['path'] ?? '',
      url: map['url'],
      type: map['type'] ?? 'file',
      size: map['size'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  IconData get icon {
    if (type.startsWith('image/')) return Icons.image;
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('text')) return Icons.description;
    if (type.contains('video')) return Icons.videocam;
    if (type.contains('audio')) return Icons.audiotrack;
    return Icons.insert_drive_file;
  }

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage => type.startsWith('image/');
}
