import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../models/note.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  
  late String _selectedNotebook;
  late List<String> _tags;
  late bool _isPinned;
  late bool _isArchived;
  late String _selectedColor;
  bool _isEditing = false;

  final List<ColorOption> _colorOptions = [
    ColorOption('default', 'Default', null),
    ColorOption('red', 'Red', Colors.red.shade100),
    ColorOption('orange', 'Orange', Colors.orange.shade100),
    ColorOption('yellow', 'Yellow', Colors.yellow.shade100),
    ColorOption('green', 'Green', Colors.green.shade100),
    ColorOption('blue', 'Blue', Colors.blue.shade100),
    ColorOption('purple', 'Purple', Colors.purple.shade100),
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note != null;
    if (_isEditing) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedNotebook = widget.note!.notebook;
      _tags = List.from(widget.note!.tags);
      _isPinned = widget.note!.isPinned;
      _isArchived = widget.note!.isArchived;
      _selectedColor = widget.note!.color;
    } else {
      _selectedNotebook = 'Personal';
      _tags = [];
      _isPinned = false;
      _isArchived = false;
      _selectedColor = 'default';
    }
  }

  Future<void> _saveNote() async {
    final provider = context.read<NoteProvider>();
    final now = DateTime.now();
    
    final note = Note(
      id: _isEditing ? widget.note!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      notebook: _selectedNotebook,
      tags: _tags,
      isPinned: _isPinned,
      isArchived: _isArchived,
      createdAt: _isEditing ? widget.note!.createdAt : now,
      updatedAt: now,
      color: _selectedColor,
    );

    await provider.saveNote(note);
    if (mounted) Navigator.pop(context);
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'New Note'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Note'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<NoteProvider>().deleteNote(widget.note!.id);
                          Navigator.pop(context); // close dialog
                          Navigator.pop(context); // close editor
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          TextButton(
            onPressed: _saveNote,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Editor
          Expanded(
            flex: 3,
            child: Container(
              color: _colorOptions.firstWhere((c) => c.value == _selectedColor).color ?? Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 24, color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (_isEditing)
                      Text(
                        'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.note!.createdAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          hintText: 'Start writing...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(fontSize: 16, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Sidebar options
          Container(
            width: 280,
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const Text('Notebook', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                FutureBuilder<List<String>>(
                  future: context.read<NoteProvider>().getNotebooks(),
                  builder: (context, snapshot) {
                    final notebooks = snapshot.data ?? ['Personal'];
                    if (!notebooks.contains(_selectedNotebook)) {
                      _selectedNotebook = 'Personal';
                    }
                    return DropdownButton<String>(
                      value: _selectedNotebook,
                      isExpanded: true,
                      items: notebooks.map((nb) => DropdownMenuItem(
                        value: nb,
                        child: Text(nb),
                      )).toList()..add(
                        DropdownMenuItem(
                          value: 'New',
                          child: Row(
                            children: const [
                              Icon(Icons.add, size: 16),
                              SizedBox(width: 4),
                              Text('New Notebook'),
                            ],
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value == 'New') {
                          _showNewNotebookDialog();
                        } else {
                          setState(() => _selectedNotebook = value!);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        decoration: const InputDecoration(
                          hintText: 'Add tag',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addTag,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: _tags.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
                const SizedBox(height: 24),
                const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _colorOptions.map((color) => GestureDetector(
                    onTap: () => setState(() => _selectedColor = color.value),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.color ?? Colors.white,
                        border: Border.all(
                          color: _selectedColor == color.value ? Colors.blue : Colors.grey.shade300,
                          width: _selectedColor == color.value ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Pinned'),
                  value: _isPinned,
                  onChanged: (v) => setState(() => _isPinned = v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Archive'),
                  value: _isArchived,
                  onChanged: (v) => setState(() => _isArchived = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNewNotebookDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Notebook'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Notebook name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _selectedNotebook = controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}

class ColorOption {
  final String value;
  final String label;
  final Color? color;

  ColorOption(this.value, this.label, this.color);
}
