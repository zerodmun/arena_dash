import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../database/database_service.dart';
import '../models/memo.dart';
import '../models/task.dart';

enum MemoType { text, list }

class NewMemoScreen extends StatefulWidget {
  const NewMemoScreen({super.key});

  @override
  State<NewMemoScreen> createState() => _NewMemoScreenState();
}

class _NewMemoScreenState extends State<NewMemoScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _taskController = TextEditingController();
  MemoVisibility _visibility = MemoVisibility.private;
  List<String> _tags = [];
  List<Task> _tasks = [];
  bool _isPreview = false;
  bool _isSaving = false;
  MemoType _memoType = MemoType.text;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _insertText('![${image.name}](${image.path})');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
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
    if (_controller.text.trim().isEmpty && _tasks.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final memo = await _db.captureMemo(
        _controller.text,
        visibility: _visibility,
        tags: _tags,
      );
      for (var task in _tasks) {
        await _db.addTask(memo.id, task.title, deadline: task.deadline);
      }
      if (mounted) Navigator.pop(context, memo);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addTask() {
    if (_taskController.text.trim().isEmpty) return;
    setState(() {
      _tasks.add(Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        memoId: 'temp',
        title: _taskController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      _taskController.clear();
    });
  }

  String _formatDeadline(DateTime? deadline) {
    if (deadline == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(deadline);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Memo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          Text(
                            'Share your thoughts',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isPreview ? Icons.edit : Icons.preview),
                      onPressed: () => setState(() => _isPreview = !_isPreview),
                      tooltip: _isPreview ? 'Edit' : 'Preview',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTypeButton(MemoType.text, Icons.text_fields, 'Text'),
                    const SizedBox(width: 8),
                    _buildTypeButton(MemoType.list, Icons.checklist, 'List'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButton<MemoVisibility>(
                        value: _visibility,
                        underline: const SizedBox(),
                        isDense: true,
                        items: MemoVisibility.values.map((v) {
                          return DropdownMenuItem(
                            value: v,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(v.icon, size: 14),
                                const SizedBox(width: 4),
                                Text(v.label, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _visibility = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isPreview ? _buildPreview() : _buildEditor(),
          ),
          if (!_isPreview) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTypeButton(MemoType type, IconData icon, String label) {
    final isSelected = _memoType == type;
    return InkWell(
      onTap: () => setState(() => _memoType = type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: _memoType == MemoType.text ? 'What\'s on your mind?' : '- [ ] Task 1\n- [ ] Task 2\n- [ ] Task 3',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Theme.of(context).hintColor),
              ),
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          if (_memoType == MemoType.list) ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      hintText: 'Add task...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._tasks.map((task) => _buildTaskItem(task)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator, size: 16, color: Theme.of(context).hintColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (task.deadline != null)
            Text(
              DateFormat('dd/MM HH:mm').format(task.deadline!),
              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
            ),
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            onPressed: () => _editTaskDeadline(task),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _tasks.remove(task)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, size: 20),
            onPressed: _pickImage,
            color: Theme.of(context).hintColor,
          ),
          IconButton(
            icon: const Icon(Icons.attach_file, size: 20),
            onPressed: _pickFile,
            color: Theme.of(context).hintColor,
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveMemo,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, size: 16),
            label: const Text('Post'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editTaskDeadline(Task task) async {
    DateTime? selectedDeadline = task.deadline;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Deadline'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: selectedDeadline != null,
                title: const Text('Set deadline'),
                onChanged: (value) {
                  setState(() {
                    selectedDeadline = value == true ? DateTime.now().add(const Duration(hours: 1)) : null;
                  });
                },
              ),
              if (selectedDeadline != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline!,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDeadline = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          selectedDeadline!.hour,
                          selectedDeadline!.minute,
                        );
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(DateFormat('dd/MM/yyyy').format(selectedDeadline!)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDeadline!),
                    );
                    if (time != null) {
                      setState(() {
                        selectedDeadline = DateTime(
                          selectedDeadline!.year,
                          selectedDeadline!.month,
                          selectedDeadline!.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 8),
                        Text(DateFormat('HH:mm').format(selectedDeadline!)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                task.copyWith(deadline: selectedDeadline);
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _taskController.dispose();
    super.dispose();
  }
}
