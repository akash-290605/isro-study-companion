import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/math_renderer.dart';
import '../../../data/models/note_model.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedSubjectFilter;

  void _openNoteEditor([NoteModel? note]) {
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');
    final subjectCtrl = TextEditingController(text: note?.subject ?? 'Network Theory');
    final topicCtrl = TextEditingController(text: note?.topic ?? 'Network Analysis');
    final tagsCtrl = TextEditingController(text: note?.tags.join(', ') ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(note == null ? 'Create Study Note' : 'Edit Note'),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Note Title'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: subjectCtrl,
                        decoration: const InputDecoration(labelText: 'Subject'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: topicCtrl,
                        decoration: const InputDecoration(labelText: 'Topic'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Note Content (supports LaTeX like \$\\sum I = 0\$)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(labelText: 'Tags (comma-separated)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              final user = ref.read(authRepositoryProvider).currentUser;
              final newNote = NoteModel(
                noteId: note?.noteId ?? const Uuid().v4(),
                userId: user?.id ?? '',
                title: titleCtrl.text.trim(),
                content: contentCtrl.text.trim(),
                subject: subjectCtrl.text.trim(),
                topic: topicCtrl.text.trim(),
                tags: tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
                createdAt: note?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
              ref.read(notesRepositoryProvider).saveNote(newNote);
              Navigator.pop(ctx);
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesRepo = ref.watch(notesRepositoryProvider);
    var notes = notesRepo.searchNotes(_searchQuery);

    if (_selectedSubjectFilter != null) {
      notes = notes.where((n) => n.subject == _selectedSubjectFilter).toList();
    }

    final subjects = notesRepo.notes.map((n) => n.subject).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Study Notes'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Note'),
            onPressed: () => _openNoteEditor(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search and filter row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search notes by title, formulas, or tags...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String?>(
                  value: _selectedSubjectFilter,
                  hint: const Text('All Subjects'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Subjects')),
                    ...subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (v) => setState(() => _selectedSubjectFilter = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes List
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No notes found.'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _openNoteEditor(),
                            child: const Text('Create First Note'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (ctx, i) {
                        final note = notes[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      onPressed: () => _openNoteEditor(note),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      onPressed: () => notesRepo.deleteNote(note.noteId),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${note.subject} • ${note.topic}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                MathFormulaView(formula: note.content),
                                const SizedBox(height: 12),
                                if (note.tags.isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    children: note.tags.map((t) {
                                      return Chip(
                                        label: Text('#$t', style: const TextStyle(fontSize: 10)),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

