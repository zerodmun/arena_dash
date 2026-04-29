import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/memo.dart';

class MemoEditorScreen extends StatefulWidget {
  final Memo? memo;

  const MemoEditorScreen({super.key, this.memo});

  @override
  State<MemoEditorScreen> createState() => _MemoEditorScreenState();
}

class _MemoEditorScreenState extends State<MemoEditorScreen> {
  late TextEditingController _controller;
  late String _visibility;
  late bool _isPinned;
  late bool _isArchived;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.memo?.content ?? '');
    _visibility = widget.memo?.visibility ?? 'PRIVATE';
    _isPinned = widget.memo?.isPinned ?? false;
    _isArchived = widget.memo?.isArchived ?? false;
  }

  Future<String?> _save() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      Navigator.pop(context);
      return null;
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memo == null ? 'New Memo' : 'Edit Memo'),
        actions: [
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.preview),
            onPressed: () => setState(() => _isPreview = !_isPreview),
            tooltip: _isPreview ? 'Edit' : 'Preview',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final content = await _save();
              if (content != null) Navigator.pop(context, content);
            },
            tooltip: 'Save',
          ),
        ],
      ),
      body: Column(
        children: [
          // Settings bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            child: Row(
              children: [
                // Visibility dropdown
                Expanded(
                  child: DropdownButton<String>(
                    value: _visibility,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'PRIVATE', child: Text('Private')),
                      DropdownMenuItem(value: 'PUBLIC', child: Text('Public')),
                      DropdownMenuItem(value: 'PROTECTED', child: Text('Protected')),
                    ],
                    onChanged: (value) => setState(() => _visibility = value!),
                  ),
                ),
                const SizedBox(width: 16),
                // Pin toggle
                Row(
                  children: [
                    Text('Pin', style: TextStyle(color: Theme.of(context).hintColor)),
                    Switch(
                      value: _isPinned,
                      onChanged: (v) => setState(() => _isPinned = v),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Archive toggle
                Row(
                  children: [
                    Text('Archive', style: TextStyle(color: Theme.of(context).hintColor)),
                    Switch(
                      value: _isArchived,
                      onChanged: (v) => setState(() => _isArchived = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Editor/Preview
          Expanded(
            child: _isPreview ? _buildPreview() : _buildEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Write in Markdown... (use #tag for tags)',
          border: InputBorder.none,
        ),
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(fontSize: 16, height: 1.6),
      ),
    );
  }

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Markdown(
        data: _controller.text.isEmpty ? '*Nothing to preview*' : _controller.text,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 16, height: 1.6),
          h1: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          h2: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          code: TextStyle(
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey.shade800 
                : Colors.grey.shade200,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
