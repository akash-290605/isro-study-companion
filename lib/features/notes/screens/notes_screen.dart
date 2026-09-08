import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
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

  void _showImagePreviewDialog(BuildContext context, String title, String base64Str) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 650),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pinch or scroll to zoom in/out for detailed formulas and circuits',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: Image.memory(
                          base64Decode(base64Str),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openNoteEditor([NoteModel? note]) {
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');
    final subjectCtrl = TextEditingController(text: note?.subject ?? 'Network Theory');
    final topicCtrl = TextEditingController(text: note?.topic ?? 'Network Analysis');
    final tagsCtrl = TextEditingController(text: note?.tags.join(', ') ?? '');
    String? attachedImageBase64 = note?.imageBase64;
    String? attachedImageName = note?.imageName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(note == null ? 'Create Study Note' : 'Edit Note'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    maxLines: 6,
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
                  const SizedBox(height: 16),

                  // Image / Diagram Attachment Section
                  const Text(
                    'VISUAL DIAGRAM / FORMULA SHEET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (attachedImageBase64 != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(
                              base64Decode(attachedImageBase64!),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attachedImageName ?? 'Attached Image',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Ready for spaced revision & visual review',
                                  style: TextStyle(fontSize: 11, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Remove Image',
                            onPressed: () {
                              setDialogState(() {
                                attachedImageBase64 = null;
                                attachedImageName = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                    label: Text(attachedImageBase64 == null ? 'Attach Image / Diagram' : 'Replace Image'),
                    onPressed: () async {
                      final files = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
                      );
                      if (files.isNotEmpty) {
                        final file = files.first;
                        final bytes = await file.readAsBytes();
                        setDialogState(() {
                          attachedImageBase64 = base64Encode(bytes);
                          attachedImageName = file.name;
                        });
                      }
                    },
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
                  imageBase64: attachedImageBase64,
                  imageName: attachedImageName,
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
                                 if (note.imageBase64 != null) ...[
                                   InkWell(
                                     onTap: () => _showImagePreviewDialog(
                                       context,
                                       note.title,
                                       note.imageBase64!,
                                     ),
                                     borderRadius: BorderRadius.circular(8),
                                     child: Container(
                                       margin: const EdgeInsets.only(bottom: 12),
                                       padding: const EdgeInsets.all(8),
                                       decoration: BoxDecoration(
                                         color: Colors.blueGrey.withOpacity(0.06),
                                         borderRadius: BorderRadius.circular(8),
                                         border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
                                       ),
                                       child: Row(
                                         children: [
                                           ClipRRect(
                                             borderRadius: BorderRadius.circular(6),
                                             child: Image.memory(
                                               base64Decode(note.imageBase64!),
                                               width: 64,
                                               height: 64,
                                               fit: BoxFit.cover,
                                             ),
                                           ),
                                           const SizedBox(width: 12),
                                           Expanded(
                                             child: Column(
                                               crossAxisAlignment: CrossAxisAlignment.start,
                                               children: [
                                                 Row(
                                                   children: [
                                                     const Icon(Icons.image_rounded, size: 14, color: Color(0xFF1E3A8A)),
                                                     const SizedBox(width: 4),
                                                     Expanded(
                                                       child: Text(
                                                         note.imageName ?? 'Visual Diagram / Formula Note',
                                                         style: const TextStyle(
                                                           fontWeight: FontWeight.bold,
                                                           fontSize: 13,
                                                         ),
                                                         overflow: TextOverflow.ellipsis,
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                                 const SizedBox(height: 4),
                                                 const Text(
                                                   'Tap to view & zoom full diagram (Revision Ready)',
                                                   style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                                                 ),
                                               ],
                                             ),
                                           ),
                                           const Icon(Icons.zoom_in_rounded, color: Color(0xFF1E3A8A)),
                                         ],
                                       ),
                                     ),
                                   ),
                                 ],
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

