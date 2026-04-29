import 'package:flutter/material.dart';
import '../database/database_service.dart';
import '../models/note.dart';

class NoteProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  String _searchQuery = '';
  String _selectedNotebook = 'All';
  bool _showArchived = false;

  List<Note> get notes => _filteredNotes;
  String get selectedNotebook => _selectedNotebook;
  bool get showArchived => _showArchived;

  NoteProvider() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    _notes = await _db.getAllNotes(includeArchived: _showArchived);
    _applyFilters();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByNotebook(String notebook) {
    _selectedNotebook = notebook;
    _applyFilters();
    notifyListeners();
  }

  void toggleArchived(bool show) {
    _showArchived = show;
    loadNotes();
  }

  void _applyFilters() {
    _filteredNotes = _notes.where((note) {
      if (_selectedNotebook != 'All' && note.notebook != _selectedNotebook) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return note.title.toLowerCase().contains(query) ||
               note.content.toLowerCase().contains(query) ||
               note.tags.any((tag) => tag.toLowerCase().contains(query));
      }
      return true;
    }).toList();
  }

  Future<void> saveNote(Note note) async {
    await _db.saveNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _db.deleteNote(id);
    await loadNotes();
  }

  Future<void> togglePin(String id) async {
    await _db.togglePin(id);
    await loadNotes();
  }

  Future<List<String>> getNotebooks() async {
    return await _db.getNotebooks();
  }
}
