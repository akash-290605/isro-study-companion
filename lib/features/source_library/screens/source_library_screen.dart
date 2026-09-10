import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../data/models/source_model.dart';

class SourceLibraryScreen extends ConsumerStatefulWidget {
  const SourceLibraryScreen({super.key});

  @override
  ConsumerState<SourceLibraryScreen> createState() => _SourceLibraryScreenState();
}

class _SourceLibraryScreenState extends ConsumerState<SourceLibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  Future<void> _confirmDeleteSource(SourceDocumentModel doc) async {
    final questionsRepo = ref.read(questionsRepositoryProvider);
    final associatedQuestions = questionsRepo.questions.where((q) => q.sourceId == doc.sourceId).toList();

    final result = await DeleteConfirmationDialog.show(
      context: context,
      itemType: 'Study Material',
      itemName: doc.sourceName,
      hasAssociatedQuestions: associatedQuestions.isNotEmpty,
      associatedQuestionsCount: associatedQuestions.length,
    );

    if (result == null || !mounted) return;

    final sourcesRepo = ref.read(sourcesRepositoryProvider);
    await sourcesRepo.deleteSource(
      doc.sourceId,
      permanent: result.isPermanent,
      deleteAssociatedQuestions: result.deleteAssociatedQuestions,
      associatedQuestionIds: associatedQuestions.map((q) => q.questionId).toList(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isPermanent
                ? 'Permanently deleted "${doc.sourceName}" from cloud and device'
                : 'Removed "${doc.sourceName}" from this device',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showRenameDialog(SourceDocumentModel doc) {
    final nameCtrl = TextEditingController(text: doc.sourceName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Study Material'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Document Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                ref.read(sourcesRepositoryProvider).renameSource(doc.sourceId, nameCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showChunksDialog(SourceDocumentModel doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${doc.sourceName} - Indexed RAG Chunks (${doc.chunks.length})'),
        content: SizedBox(
          width: 600,
          height: 480,
          child: doc.chunks.isEmpty
              ? const Center(child: Text('No chunks indexed.'))
              : ListView.builder(
                  itemCount: doc.chunks.length,
                  itemBuilder: (ctx, i) {
                    final chunk = doc.chunks[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.grey.withOpacity(0.04),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Chunk ${i + 1} • Page ${chunk.pageNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    chunk.section,
                                    style: TextStyle(fontSize: 10, color: Colors.blue.shade900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              chunk.content,
                              style: const TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourcesRepo = ref.watch(sourcesRepositoryProvider);
    final sources = sourcesRepo.searchSources(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Study Materials (Source Library)'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.quiz_rounded, size: 18),
            label: const Text('Question Bank / Import'),
            onPressed: () => context.go('/question-bank'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search materials by title, subject or topic...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: sources.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No study materials yet.',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Upload your first PDF, question paper, note, image or URL to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.quiz_rounded),
                            label: const Text('Go to Question Bank & Import Material'),
                            onPressed: () => context.go('/question-bank'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: sources.length,
                      itemBuilder: (ctx, i) {
                        final doc = sources[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getIconForType(doc.sourceType),
                                    color: const Color(0xFF1E3A8A),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              doc.sourceName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              doc.processedStatus.label,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.green.shade800,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${doc.subject} • ${doc.topic} • ${doc.sourceType.label} • ${doc.chunks.length} RAG chunks',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            ),
                                            icon: const Icon(Icons.view_headline_rounded, size: 14),
                                            label: const Text('View Chunks', style: TextStyle(fontSize: 11)),
                                            onPressed: () => _showChunksDialog(doc),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            ),
                                            icon: const Icon(Icons.edit_outlined, size: 14),
                                            label: const Text('Rename', style: TextStyle(fontSize: 11)),
                                            onPressed: () => _showRenameDialog(doc),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Delete Source',
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                            onPressed: () => _confirmDeleteSource(doc),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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

  IconData _getIconForType(SourceType type) {
    switch (type) {
      case SourceType.pdf:
        return Icons.picture_as_pdf_rounded;
      case SourceType.document:
        return Icons.description_rounded;
      case SourceType.questionImage:
        return Icons.image_rounded;
      case SourceType.questionPaper:
        return Icons.assignment_rounded;
      case SourceType.note:
        return Icons.edit_note_rounded;
      case SourceType.url:
        return Icons.link_rounded;
      case SourceType.manualText:
        return Icons.text_snippet_rounded;
    }
  }
}

