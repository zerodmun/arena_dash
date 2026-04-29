import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../models/note.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  Color? _getNoteColor(String colorName) {
    switch (colorName) {
      case 'red': return Colors.red.shade50;
      case 'orange': return Colors.orange.shade50;
      case 'yellow': return Colors.yellow.shade50;
      case 'green': return Colors.green.shade50;
      case 'blue': return Colors.blue.shade50;
      case 'purple': return Colors.purple.shade50;
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
                      ).then((_) => context.read<NoteProvider>().loadNotes());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Note'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                    ),
                  ),
                ),
                _buildSidebarItem(context, Icons.lightbulb_outline, 'All Notes', 'All'),
                _buildSidebarItem(context, Icons.push_pin_outlined, 'Pinned', 'Pinned'),
                _buildSidebarItem(context, Icons.archive_outlined, 'Archive', 'Archive'),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Notebooks', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Consumer<NoteProvider>(
                    builder: (context, provider, _) {
                      return FutureBuilder<List<String>>(
                        future: provider.getNotebooks(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          return ListView(
                            children: snapshot.data!.map((notebook) =>
                              _buildSidebarItem(context, Icons.folder_outlined, notebook, notebook)
                            ).toList(),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) => context.read<NoteProvider>().search(value),
                  ),
                ),
                Expanded(
                  child: Consumer<NoteProvider>(
                    builder: (context, provider, _) {
                      final notes = provider.notes;
                      if (notes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.note_add, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                provider.selectedNotebook == 'All' && _searchController.text.isEmpty
                                    ? 'No notes yet'
                                    : 'No notes found',
                                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return _buildNoteCard(context, note);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String label, String value) {
    return Consumer<NoteProvider>(
      builder: (context, provider, _) {
        final isSelected = provider.selectedNotebook == value ||
          (value == 'Pinned' && provider.selectedNotebook == 'Pinned') ||
          (value == 'Archive' && provider.showArchived);
        
        return ListTile(
          leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
          title: Text(label),
          selected: isSelected,
          selectedTileColor: Colors.blue.shade50,
          onTap: () {
            if (value == 'Archive') {
              provider.toggleArchived(true);
              provider.filterByNotebook('All');
            } else if (value == 'Pinned') {
              provider.toggleArchived(false);
              provider.filterByNotebook('Pinned');
            } else {
              provider.toggleArchived(false);
              provider.filterByNotebook(value);
            }
          },
        );
      },
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    final noteColor = _getNoteColor(note.color);
    
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => context.read<NoteProvider>().deleteNote(note.id),
      child: Card(
        color: noteColor,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
            ).then((_) => context.read<NoteProvider>().loadNotes());
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (note.isPinned) const Icon(Icons.push_pin, size: 16, color: Colors.grey),
                    if (note.isPinned) const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 20),
                      onPressed: () => context.read<NoteProvider>().togglePin(note.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    note.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(note.updatedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
