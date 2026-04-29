import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/note.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static SharedPreferences? _prefs;
  static const String _webNotesKey = 'evernote_notes';

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
    final path = '$dbPath/evernote.db';
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            notebook TEXT DEFAULT 'Personal',
            tags TEXT DEFAULT '[]',
            is_pinned INTEGER DEFAULT 0,
            is_archived INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            color TEXT DEFAULT 'default'
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE notes ADD COLUMN color TEXT DEFAULT "default"');
        }
      },
    );
  }

  Future<List<Note>> getAllNotes({bool includeArchived = false}) async {
    if (kIsWeb) return _getWebNotes(includeArchived: includeArchived);
    final db = await _db;
    final where = includeArchived ? null : 'is_archived = 0';
    final result = await db.query('notes', where: where, orderBy: 'is_pinned DESC, updated_at DESC');
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> searchNotes(String query) async {
    if (kIsWeb) {
      final notes = await _getWebNotes();
      return notes.where((note) =>
        note.title.toLowerCase().contains(query.toLowerCase()) ||
        note.content.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    final db = await _db;
    return (await db.query('notes',
      where: 'is_archived = 0 AND (title LIKE ? OR content LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC'
    )).map((map) => Note.fromMap(map)).toList();
  }

  Future<void> saveNote(Note note) async {
    if (kIsWeb) {
      final notes = await _getWebNotes(includeArchived: true);
      final index = notes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        notes[index] = note;
      } else {
        notes.add(note);
      }
      await _saveWebNotes(notes);
      return;
    }
    final db = await _db;
    await db.insert('notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteNote(String id) async {
    if (kIsWeb) {
      final notes = await _getWebNotes(includeArchived: true);
      notes.removeWhere((n) => n.id == id);
      await _saveWebNotes(notes);
      return;
    }
    final db = await _db;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> togglePin(String id) async {
    if (kIsWeb) {
      final notes = await _getWebNotes(includeArchived: true);
      final index = notes.indexWhere((n) => n.id == id);
      if (index >= 0) {
        notes[index] = notes[index].copyWith(isPinned: !notes[index].isPinned);
        await _saveWebNotes(notes);
      }
      return;
    }
    final db = await _db;
    final note = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (note.isNotEmpty) {
      final current = Note.fromMap(note.first);
      await db.update('notes', {'is_pinned': current.isPinned ? 0 : 1}, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<String>> getNotebooks() async {
    if (kIsWeb) {
      final notes = await _getWebNotes(includeArchived: true);
      return notes.map((n) => n.notebook).toSet().toList()..sort();
    }
    final db = await _db;
    final result = await db.rawQuery('SELECT DISTINCT notebook FROM notes ORDER BY notebook');
    return result.map((row) => row['notebook'] as String).toList();
  }

  // Web storage helper
  Future<List<Note>> _getWebNotes({bool includeArchived = false}) async {
    final prefs = await _webPrefs;
    final notesJson = prefs.getStringList(_webNotesKey) ?? [];
    var notes = notesJson.map((json) => Note.fromMap(jsonDecode(json))).toList();
    if (!includeArchived) notes.removeWhere((n) => n.isArchived);
    notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  Future<void> _saveWebNotes(List<Note> notes) async {
    final prefs = await _webPrefs;
    final notesJson = notes.map((n) => jsonEncode(n.toMap())).toList();
    await prefs.setStringList(_webNotesKey, notesJson);
  }
}
