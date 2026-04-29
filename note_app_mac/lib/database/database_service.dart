import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/memo.dart';
import '../models/attachment.dart';
import '../models/comment.dart';
import '../models/reaction.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static SharedPreferences? _prefs;

  Future<Database> get _db async {
    if (kIsWeb) throw UnsupportedError('Web uses SharedPreferences');
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<SharedPreferences> get _webPrefs async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/memos.db';
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE memos(
            id TEXT PRIMARY KEY,
            content TEXT NOT NULL,
            visibility TEXT DEFAULT 'PRIVATE',
            tags TEXT DEFAULT '[]',
            is_pinned INTEGER DEFAULT 0,
            is_archived INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_memos_pinned ON memos(is_pinned DESC, updated_at DESC)');
        await db.execute('''
          CREATE TABLE attachments(
            id TEXT PRIMARY KEY,
            memo_id TEXT NOT NULL,
            name TEXT NOT NULL,
            path TEXT NOT NULL,
            url TEXT,
            type TEXT NOT NULL,
            size INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (memo_id) REFERENCES memos(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE comments(
            id TEXT PRIMARY KEY,
            memo_id TEXT NOT NULL,
            content TEXT NOT NULL,
            author_name TEXT DEFAULT 'Anonymous',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (memo_id) REFERENCES memos(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE reactions(
            id TEXT PRIMARY KEY,
            memo_id TEXT NOT NULL,
            emoji TEXT NOT NULL,
            user_id TEXT DEFAULT 'local',
            created_at TEXT NOT NULL,
            FOREIGN KEY (memo_id) REFERENCES memos(id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE memos ADD COLUMN tags TEXT DEFAULT "[]"');
          await db.execute('ALTER TABLE memos ADD COLUMN is_pinned INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE memos ADD COLUMN is_archived INTEGER DEFAULT 0');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS attachments(
              id TEXT PRIMARY KEY,
              memo_id TEXT NOT NULL,
              name TEXT NOT NULL,
              path TEXT NOT NULL,
              url TEXT,
              type TEXT NOT NULL,
              size INTEGER DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS comments(
              id TEXT PRIMARY KEY,
              memo_id TEXT NOT NULL,
              content TEXT NOT NULL,
              author_name TEXT DEFAULT 'Anonymous',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS reactions(
              id TEXT PRIMARY KEY,
              memo_id TEXT NOT NULL,
              emoji TEXT NOT NULL,
              user_id TEXT DEFAULT 'local',
              created_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<List<Memo>> getTimeline({bool includeArchived = false}) async {
    if (kIsWeb) return _getWebMemos(includeArchived: includeArchived);
    final db = await _db;
    final where = includeArchived ? null : 'is_archived = 0';
    final result = await db.query('memos', where: where, orderBy: 'is_pinned DESC, updated_at DESC');
    return result.map((map) => Memo.fromMap(map)).toList();
  }

  Future<Memo> captureMemo(String content, {MemoVisibility visibility = MemoVisibility.private, List<String> tags = const []}) async {
    final now = DateTime.now();
    final extractedTags = tags.isNotEmpty ? tags : Memo.extractTagsFromContent(content);
    final memo = Memo(
      id: now.millisecondsSinceEpoch.toString(),
      content: content,
      visibility: visibility,
      tags: extractedTags,
      createdAt: now,
      updatedAt: now,
    );

    if (kIsWeb) {
      final memos = await _getWebMemos(includeArchived: true);
      memos.insert(0, memo);
      await _saveWebMemos(memos);
    } else {
      final db = await _db;
      await db.insert('memos', memo.toMap());
    }
    return memo;
  }

  Future<void> updateMemo(Memo memo) async {
    final updatedMemo = memo.copyWith(
      tags: Memo.extractTagsFromContent(memo.content),
      updatedAt: DateTime.now(),
    );

    if (kIsWeb) {
      final memos = await _getWebMemos(includeArchived: true);
      final index = memos.indexWhere((m) => m.id == memo.id);
      if (index >= 0) {
        memos[index] = updatedMemo;
        await _saveWebMemos(memos);
      }
      return;
    }
    final db = await _db;
    await db.update('memos', updatedMemo.toMap(), where: 'id = ?', whereArgs: [memo.id]);
  }

  Future<void> togglePin(String id) async {
    if (kIsWeb) {
      final memos = await _getWebMemos(includeArchived: true);
      final index = memos.indexWhere((m) => m.id == id);
      if (index >= 0) {
        memos[index] = memos[index].copyWith(isPinned: !memos[index].isPinned);
        await _saveWebMemos(memos);
      }
      return;
    }
    final db = await _db;
    final memo = await db.query('memos', where: 'id = ?', whereArgs: [id]);
    if (memo.isNotEmpty) {
      final current = Memo.fromMap(memo.first);
      await db.update('memos', {'is_pinned': current.isPinned ? 0 : 1, 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> toggleArchive(String id) async {
    if (kIsWeb) {
      final memos = await _getWebMemos(includeArchived: true);
      final index = memos.indexWhere((m) => m.id == id);
      if (index >= 0) {
        memos[index] = memos[index].copyWith(isArchived: !memos[index].isArchived);
        await _saveWebMemos(memos);
      }
      return;
    }
    final db = await _db;
    final memo = await db.query('memos', where: 'id = ?', whereArgs: [id]);
    if (memo.isNotEmpty) {
      final current = Memo.fromMap(memo.first);
      await db.update('memos', {'is_archived': current.isArchived ? 0 : 1, 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> deleteMemo(String id) async {
    if (kIsWeb) {
      final memos = await _getWebMemos(includeArchived: true);
      memos.removeWhere((m) => m.id == id);
      await _saveWebMemos(memos);
      return;
    }
    final db = await _db;
    await db.delete('memos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Memo>> searchMemos(String query) async {
    if (kIsWeb) {
      final memos = await _getWebMemos();
      final lowerQuery = query.toLowerCase();
      return memos.where((m) => m.content.toLowerCase().contains(lowerQuery) || m.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))).toList();
    }
    final db = await _db;
    final result = await db.query('memos', where: 'is_archived = 0 AND (content LIKE ? OR tags LIKE ?)', whereArgs: ['%$query%', '%$query%'], orderBy: 'is_pinned DESC, updated_at DESC');
    return result.map((map) => Memo.fromMap(map)).toList();
  }

  Future<List<Attachment>> getAttachments(String memoId) async {
    if (kIsWeb) return [];
    final db = await _db;
    final result = await db.query('attachments', where: 'memo_id = ?', whereArgs: [memoId], orderBy: 'created_at DESC');
    return result.map((map) => Attachment.fromMap(map)).toList();
  }

  Future<Attachment> addAttachment(String memoId, String name, String path, String type, {int size = 0}) async {
    final now = DateTime.now();
    final attachment = Attachment(
      id: now.millisecondsSinceEpoch.toString(),
      memoId: memoId,
      name: name,
      path: path,
      type: type,
      size: size,
      createdAt: now,
    );
    if (!kIsWeb) {
      final db = await _db;
      await db.insert('attachments', attachment.toMap());
    }
    return attachment;
  }

  Future<List<Comment>> getComments(String memoId) async {
    if (kIsWeb) return [];
    final db = await _db;
    final result = await db.query('comments', where: 'memo_id = ?', whereArgs: [memoId], orderBy: 'created_at ASC');
    return result.map((map) => Comment.fromMap(map)).toList();
  }

  Future<Comment> addComment(String memoId, String content, {String authorName = 'Anonymous'}) async {
    final now = DateTime.now();
    final comment = Comment(
      id: now.millisecondsSinceEpoch.toString(),
      memoId: memoId,
      content: content,
      authorName: authorName,
      createdAt: now,
      updatedAt: now,
    );
    if (!kIsWeb) {
      final db = await _db;
      await db.insert('comments', comment.toMap());
    }
    return comment;
  }

  Future<List<ReactionGroup>> getReactions(String memoId) async {
    if (kIsWeb) return [];
    final db = await _db;
    final result = await db.query('reactions', where: 'memo_id = ?', whereArgs: [memoId]);
    final reactions = result.map((map) => Reaction.fromMap(map)).toList();
    final groups = <String, ReactionGroup>{};
    for (var r in reactions) {
      if (groups.containsKey(r.emoji)) {
        groups[r.emoji] = ReactionGroup(emoji: r.emoji, count: groups[r.emoji]!.count + 1, reactedByMe: groups[r.emoji]!.reactedByMe || r.userId == 'local');
      } else {
        groups[r.emoji] = ReactionGroup(emoji: r.emoji, count: 1, reactedByMe: r.userId == 'local');
      }
    }
    return groups.values.toList();
  }

  Future<void> toggleReaction(String memoId, String emoji) async {
    if (kIsWeb) return;
    final db = await _db;
    final existing = await db.query('reactions', where: 'memo_id = ? AND emoji = ? AND user_id = ?', whereArgs: [memoId, emoji, 'local']);
    if (existing.isNotEmpty) {
      await db.delete('reactions', where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      final reaction = Reaction(id: DateTime.now().millisecondsSinceEpoch.toString(), memoId: memoId, emoji: emoji, userId: 'local', createdAt: DateTime.now());
      await db.insert('reactions', reaction.toMap());
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    if (kIsWeb) {
      final memos = await _getWebMemos(includeArchived: true);
      return {'total': memos.length, 'pinned': memos.where((m) => m.isPinned).length, 'archived': memos.where((m) => m.isArchived).length, 'tags': _getAllTags(memos).length};
    }
    final db = await _db;
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM memos');
    final total = totalResult.first['count'] as int? ?? 0;
    final pinnedResult = await db.rawQuery('SELECT COUNT(*) as count FROM memos WHERE is_pinned = 1');
    final pinned = pinnedResult.first['count'] as int? ?? 0;
    final archivedResult = await db.rawQuery('SELECT COUNT(*) as count FROM memos WHERE is_archived = 1');
    final archived = archivedResult.first['count'] as int? ?? 0;
    final tagsResult = await db.rawQuery('SELECT tags FROM memos WHERE tags != "[]"');
    final allTags = <String>{};
    for (var row in tagsResult) {
      final tags = jsonDecode(row['tags'] as String) as List;
      allTags.addAll(tags.cast<String>());
    }
    return {'total': total, 'pinned': pinned, 'archived': archived, 'tags': allTags.length};
  }

  Set<String> _getAllTags(List<Memo> memos) {
    final tags = <String>{};
    for (var memo in memos) {
      tags.addAll(memo.tags);
    }
    return tags;
  }

  Future<List<Memo>> _getWebMemos({bool includeArchived = false}) async {
    final prefs = await _webPrefs;
    final memosJson = prefs.getStringList('memos_timeline') ?? [];
    var memos = memosJson.map((json) => Memo.fromMap(jsonDecode(json))).toList();
    if (!includeArchived) memos.removeWhere((m) => m.isArchived);
    memos.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return memos;
  }

  Future<void> _saveWebMemos(List<Memo> memos) async {
    final prefs = await _webPrefs;
    final memosJson = memos.map((m) => jsonEncode(m.toMap())).toList();
    await prefs.setStringList('memos_timeline', memosJson);
  }

  Future<void> clearAllData() async {
    if (kIsWeb) {
      final prefs = await _webPrefs;
      await prefs.clear();
    } else {
      final db = await _db;
      await db.delete('reactions');
      await db.delete('comments');
      await db.delete('attachments');
      await db.delete('memos');
    }
  }
}
