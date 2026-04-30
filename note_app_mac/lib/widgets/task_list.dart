import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../database/database_service.dart';

class TaskList extends StatefulWidget {
  final String memoId;
  const TaskList({super.key, required this.memoId});

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  final DatabaseService _db = DatabaseService();
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _db.getTasks(widget.memoId);
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tasks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Tasks (${_tasks.where((t) => !t.isCompleted).length} active)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._tasks.map((task) => _buildTaskItem(task)).toList(),
        ],
      ],
    );
  }

  Widget _buildTaskItem(Task task) {
    final isOverdue = task.isOverdue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? Colors.green.withOpacity(0.05)
            : isOverdue
                ? Colors.red.withOpacity(0.05)
                : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isCompleted
              ? Colors.green.withOpacity(0.3)
              : isOverdue
                  ? Colors.red.withOpacity(0.3)
                  : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () async {
              await _db.toggleTaskCompletion(task.id);
              _loadTasks();
            },
            child: Container(
              width: 24,
              height: 24,
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
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted
                        ? Colors.grey
                        : isOverdue
                            ? Colors.red
                            : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                if (task.deadline != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: isOverdue ? Colors.red : Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.deadlineFormatted,
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red : Theme.of(context).hintColor,
                          fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isOverdue && !task.isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OVERDUE',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
