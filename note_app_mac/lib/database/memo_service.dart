import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/memo.dart';

class MemoService {
  static final MemoService _instance = MemoService._internal();
  factory MemoService() => _instance;
  MemoService._internal();

  static Database? _database;
  static SharedPreferences? _prefs;
  static const String _webMemosKey = 'memos_timeline';

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
      version: 2,
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
        await db.execute('CREATE INDEX idx_pinned_created ON memos(is_pinned DESC, updated_at DESC)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE memos ADD COLUMN tags TEXT DEFAULT "[]"');
          await db.execute('ALTER TABLE memos ADD COLUMN is_pinned INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE memos ADD COLUMN is_archived INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future<List<Memo>> getTimeline({bool includeArchived = false}) async {
    if (kIsWeb) return _getWebMemos(includeArchived: includeArchived);
    final db = await _db;
    final where = includeArchived ? null : 'is_archived = 0';
    final result = await db.query(
      'memos',
      where: where,
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return result.map((map) => Memo.fromMap(map)).toList();
  }

  Future<Memo> captureMemo(String markdownContent) async {
    final now = DateTime.now();
    final tags = Memo.extractTagsFromContent(markdownContent);
    final memo = Memo(
      id: now.millisecondsSinceEpoch.toString(),
      content: markdownContent,
      tags: tags,
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
    await db.update(
      'memos',
      updatedMemo.toMap(),
      where: 'id = ?',
      whereArgs: [memo.id],
    );
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
      await db.update(
        'memos',
        {'is_pinned': current.isPinned ? 0 : 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
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
      await db.update(
        'memos',
        {'is_archived': current.isArchived ? 0 : 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
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
      return memos.where((m) =>
        m.content.toLowerCase().contains(lowerQuery) ||
        m.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
      ).toList();
    }
    final db = await _db;
    final result = await db.query(
      'memos',
      where: 'is_archived = 0 AND (content LIKE ? OR tags LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return result.map((map) => Memo.fromMap(map)).toList();
  }

  Future<List<Memo>> _getWebMemos({bool includeArchived = false}) async {
    final prefs = await _webPrefs;
    final memosJson = prefs.getStringList(_webMemosKey) ?? [];
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
    await prefs.setStringList(_webMemosKey, memosJson);
  }
}
