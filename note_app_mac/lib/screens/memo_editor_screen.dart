import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_service.dart';
import '../models/memo.dart';
import '../models/attachment.dart';

class MemoEditorScreen extends StatefulWidget {
  final Memo? memo;
  const MemoEditorScreen({super.key, this.memo});

  @override
  State<MemoEditorScreen> createState() => _MemoEditorScreenState();
}

class _MemoEditorScreenState extends State<MemoEditorScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  MemoVisibility _visibility = MemoVisibility.private;
  List<String> _tags = [];
  List<Attachment> _attachments = [];
  bool _isPreview = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.memo != null) {
      _controller.text = widget.memo!.content;
      _visibility = widget.memo!.visibility;
      _tags = List.from(widget.memo!.tags);
      _loadAttachments();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.memo == null) _focusNode.requestFocus();
    });
  }

  Future<void> _loadAttachments() async {
    if (widget.memo != null) {
      final attachments = await _db.getAttachments(widget.memo!.id);
      setState(() => _attachments = attachments);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final attachment = await _db.addAttachment(
        widget.memo?.id ?? 'temp',
        image.name,
        image.path,
        'image/${image.name.split('.').last}',
        size: File(image.path).lengthSync(),
      );
      setState(() => _attachments.add(attachment));
      _insertText('![${image.name}](${image.path})');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      final attachment = await _db.addAttachment(
        widget.memo?.id ?? 'temp',
        file.name,
        file.path!,
        'file/${file.extension ?? "unknown"}',
        size: file.size,
      );
      setState(() => _attachments.add(attachment));
      _insertText('[${file.name}](${file.path})');
    }
  }

  void _insertText(String text) {
    final current = _controller.text;
    final selection = _controller.selection;
    final newText = current.substring(0, selection.start) + text + current.substring(selection.end);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: selection.start + text.length);
  }

  Future<void> _saveMemo() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      if (widget.memo != null) {
        final updatedMemo = widget.memo!.copyWith(
          content: _controller.text,
          visibility: _visibility,
          tags: _tags,
          updatedAt: DateTime.now(),
        );
        await _db.updateMemo(updatedMemo);
      } else {
        await _db.captureMemo(
          _controller.text,
          visibility: _visibility,
          tags: _tags,
        );
      }
      if (mounted) Navigator.pop(context, _controller.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
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

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.memo != null ? 'Edit Memo' : 'New Memo'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.preview),
            onPressed: () => setState(() => _isPreview = !_isPreview),
            tooltip: _isPreview ? 'Edit' : 'Preview',
          ),
          TextButton(
            onPressed: _isSaving ? null : _saveMemo,
            child: _isSaving
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: Theme.of(context).hintColor),
                const SizedBox(width: 8),
                DropdownButton<MemoVisibility>(
                  value: _visibility,
                  underline: const SizedBox(),
                  onChanged: (value) => setState(() => _visibility = value!),
                  items: MemoVisibility.values.map((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(v.icon, size: 16),
                          const SizedBox(width: 8),
                          Text(v.label),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image, size: 18),
                  label: const Text('Image'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).hintColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('File'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).hintColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
          if (_tags.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#$tag', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _removeTag(tag),
                          child: Icon(Icons.close, size: 14, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: 'Add tag...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isPreview
                ? _buildPreview()
                : _buildEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: 'Write your memo in Markdown...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Theme.of(context).hintColor),
        ),
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Markdown(
        data: _controller.text.isEmpty ? '*Nothing to preview*' : _controller.text,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(fontSize: 16, height: 1.6, color: Theme.of(context).textTheme.bodyLarge?.color),
          h1: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.titleLarge?.color),
          h2: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.titleLarge?.color),
          h3: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.titleLarge?.color),
          code: TextStyle(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
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
    _tagController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
