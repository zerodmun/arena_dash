import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../database/database_service.dart';
import '../models/memo.dart';
import '../models/attachment.dart';
import '../models/task.dart';
import '../widgets/task_list.dart';

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
  final TextEditingController _taskController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  MemoVisibility _visibility = MemoVisibility.private;
  List<String> _tags = [];
  List<Attachment> _attachments = [];
  List<Task> _tasks = [];
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
      _loadTasks();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.memo == null) _focusNode.requestFocus();
    });
  }

  Future<void> _loadTasks() async {
    if (widget.memo != null) {
      final tasks = await _db.getTasks(widget.memo!.id);
      setState(() => _tasks = tasks);
    }
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
          if (widget.memo != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Tasks',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _showAddTaskDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Task'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  if (_tasks.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._tasks.map((task) => _buildTaskItem(task)).toList(),
                  ],
                ],
              ),
            ),
          ],
          Expanded(
            child: _isPreview
                ? _buildPreview()
                : _buildEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final isOverdue = task.isOverdue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          InkWell(
            onTap: () async {
              await _db.toggleTaskCompletion(task.id);
              _loadTasks();
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted
                      ? Colors.green
                      : isOverdue
                          ? Colors.red
                          : Colors.grey,
                  width: 2,
                ),
                color: task.isCompleted ? Colors.green : Colors.transparent,
              ),
              child: task.isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 13,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? Colors.grey
                        : isOverdue
                            ? Colors.red
                            : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                if (task.deadline != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 12, color: isOverdue ? Colors.red : Theme.of(context).hintColor),
                      const SizedBox(width: 4),
                      Text(
                        task.deadlineFormatted,
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue ? Colors.red : Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 16, color: Theme.of(context).hintColor),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: const [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Edit Deadline')],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: const [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') _showEditDeadlineDialog(task);
              if (value == 'delete') _deleteTask(task.id);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    _taskController.clear();
    DateTime? selectedDeadline;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Task title...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: selectedDeadline != null,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedDeadline = DateTime.now().add(const Duration(hours: 1));
                            } else {
                              selectedDeadline = null;
                            }
                          });
                        },
                      ),
                      const Text('Set deadline'),
                    ],
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_taskController.text.trim().isNotEmpty) {
                await _db.addTask(
                  widget.memo!.id,
                  _taskController.text.trim(),
                  deadline: selectedDeadline,
                );
                _loadTasks();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDeadlineDialog(Task task) async {
    DateTime? selectedDeadline = task.deadline;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Deadline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: selectedDeadline != null,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedDeadline = DateTime.now().add(const Duration(hours: 1));
                            } else {
                              selectedDeadline = null;
                            }
                          });
                        },
                      ),
                      const Text('Set deadline'),
                    ],
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.updateTaskDeadline(task.id, selectedDeadline);
              _loadTasks();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(String taskId) async {
    // Implement task deletion if needed
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
