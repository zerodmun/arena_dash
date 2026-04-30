import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../database/database_service.dart';
import '../models/memo.dart';
import 'memo_editor_screen.dart';

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({super.key});

  @override
  State<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends State<MemoListScreen> {
  final DatabaseService _db = DatabaseService();
  List<Memo> _memos = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _includeArchived = false;

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  Future<void> _loadMemos() async {
    setState(() => _isLoading = true);
    try {
      final memos = _searchQuery.isNotEmpty
          ? await _db.searchMemos(_searchQuery)
          : await _db.getTimeline(includeArchived: _includeArchived);
      setState(() {
        _memos = memos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.year == date.year && now.month == date.month && now.day == date.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
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
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _loadMemos();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search memos...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() => _includeArchived = !_includeArchived);
                    _loadMemos();
                  },
                  icon: Icon(_includeArchived ? Icons.archive : Icons.archive_outlined, size: 16),
                  label: Text(_includeArchived ? 'Hide Archived' : 'Show Archived', style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: _includeArchived ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadMemos,
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                        padding: const EdgeInsets.all(8),
                        itemCount: _memos.length,
                        itemBuilder: (context, index) {
                          final memo = _memos[index];
                          return _buildMemoTile(memo);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoTile(Memo memo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MemoEditorScreen(memo: memo)),
          );
          _loadMemos();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (memo.isPinned)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.push_pin, size: 12, color: Colors.orange),
                    ),
                  if (memo.isArchived)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.archive, size: 12, color: Colors.grey),
                    ),
                  Expanded(
                    child: Text(
                      memo.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDate(memo.updatedAt),
                    style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                  ),
                ],
              ),
              if (memo.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: memo.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('#$tag', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                memo.preview,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
