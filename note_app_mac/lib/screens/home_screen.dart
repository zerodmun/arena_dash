import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../database/database_service.dart';
import '../models/memo.dart';
import 'new_memo_screen.dart';
import 'memo_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  List<Memo> _memos = [];
  bool _isLoading = true;
  Memo? _selectedMemo;
  bool _isCreatingNew = false;

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  Future<void> _loadMemos() async {
    setState(() => _isLoading = true);
    try {
      final memos = await _db.getTimeline();
      setState(() {
        _memos = memos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _createNewMemo() {
    setState(() {
      _isCreatingNew = true;
      _selectedMemo = null;
    });
  }

  void _selectMemo(Memo memo) {
    setState(() {
      _selectedMemo = memo;
      _isCreatingNew = false;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.year == date.year && now.month == date.month && now.day == date.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('dd/MM/yy').format(date);
  }

  Future<void> _handleDeleteMemo(String id) async {
    await _db.deleteMemo(id);
    _loadMemos();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.note_alt_outlined, color: Theme.of(context).colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Memos',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: _createNewMemo,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Memo'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                    : _memos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.note_add_outlined, size: 48, color: Theme.of(context).hintColor),
                                const SizedBox(height: 12),
                                Text('No memos yet', style: TextStyle(color: Theme.of(context).hintColor)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: _memos.length,
                            itemBuilder: (context, index) {
                              final memo = _memos[index];
                              final isSelected = _selectedMemo?.id == memo.id;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: InkWell(
                                  onTap: () => _selectMemo(memo),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (memo.isPinned)
                                              Container(
                                                  margin: const EdgeInsets.only(right: 4),
                                                  child: const Icon(Icons.push_pin, size: 12, color: Colors.orange),
                                              ),
                                            Expanded(
                                              child: Text(
                                                memo.title,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.titleMedium?.color,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(memo.createdAt),
                                          style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isCreatingNew
              ? const NewMemoScreen()
              : _selectedMemo != null
                  ? _buildMemoDetail(_selectedMemo!)
                  : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.note_add_outlined, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'No memos yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first memo!',
            style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoDetail(Memo memo) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: null,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(memo.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () async {
              await _db.togglePin(memo.id);
              _loadMemos();
            },
            tooltip: memo.isPinned ? 'Unpin' : 'Pin',
          ),
          IconButton(
            icon: Icon(memo.isArchived ? Icons.unarchive : Icons.archive_outlined),
            onPressed: () async {
              await _db.toggleArchive(memo.id);
              _loadMemos();
            },
            tooltip: memo.isArchived ? 'Unarchive' : 'Archive',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: const [Icon(Icons.edit, size: 18), SizedBox(width: 12), Text('Edit')],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: const [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'edit') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MemoEditorScreen(memo: memo)),
                );
                _loadMemos();
              }
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Memo'),
                    content: const Text('This action cannot be undone. Are you sure?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _handleDeleteMemo(memo.id);
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(memo.visibility.icon, size: 16, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 8),
              Text(
                memo.visibility.label,
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
              ),
              const Spacer(),
              Text(
                _formatDate(memo.createdAt),
                style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
              ),
            ],
          ),
          if (memo.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: memo.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('#$tag', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          MarkdownBody(
            data: memo.content,
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
        ],
      ),
    );
  }
}
