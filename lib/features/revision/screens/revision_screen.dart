import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/providers.dart';
import '../../../data/models/note_model.dart';

class RevisionScreen extends ConsumerWidget {
  const RevisionScreen({super.key});

  void _showImagePreviewDialog(BuildContext context, NoteModel note) {
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${note.subject} • ${note.topic}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                          ),
                        ],
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
                if (note.imageBase64 != null)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.memory(
                            base64Decode(note.imageBase64!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark Diagram Reviewed'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Marked "${note.title}" diagram as reviewed!'),
                            backgroundColor: const Color(0xFF10B981),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revRepo = ref.watch(revisionRepositoryProvider);
    final mistakesRepo = ref.watch(mistakesRepositoryProvider);
    final flashcardsRepo = ref.watch(flashcardsRepositoryProvider);
    final testRepo = ref.watch(testRepositoryProvider);
    final notesRepo = ref.watch(notesRepositoryProvider);
    final visualNotes = notesRepo.notes.where((n) => n.imageBase64 != null && n.imageBase64!.isNotEmpty).toList();

    // Compute weak topics from tests
    final Map<String, List<double>> topicScores = {};
    for (final r in testRepo.results) {
      for (final entry in r.topicBreakdown.entries) {
        topicScores.putIfAbsent(entry.key, () => []).add(entry.value.accuracy);
      }
    }
    final List<String> weakTopics = [];
    topicScores.forEach((topic, scores) {
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      if (avg < 75) weakTopics.add(topic);
    });
    if (weakTopics.isEmpty) {
      weakTopics.addAll(['Mesh Analysis', 'Boolean Algebra & Gates', 'Thevenin Theorem']);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision Hub'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('Generate Smart Session'),
            onPressed: () async {
              final dueCards = flashcardsRepo.dueCards.map((c) => c.cardId).toList();
              final mistakes = mistakesRepo.mistakes.where((m) => !m.isResolved).map((m) => m.mistakeId).toList();

              await revRepo.generateSmartRevision(
                weakTopics: weakTopics,
                mistakeIds: mistakes,
                dueFlashcardIds: dueCards,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generated new revision session tailored to your weak topics & mistakes!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Revision Banner (Section 32)
            Card(
              color: const Color(0xFFEFF6FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.repeat_rounded, color: Color(0xFF1E3A8A)),
                        SizedBox(width: 8),
                        Text(
                          "TODAY'S PRIORITY REVISION TOPICS",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Derived from your low test accuracy scores, unresolved mistakes, and spaced review schedule:',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    ...weakTopics.take(4).toList().asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            Text(
                              '${entry.key + 1}. ',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.timer_outlined, size: 14),
                              label: const Text('Study Now', style: TextStyle(fontSize: 11)),
                              onPressed: () => context.go('/timer'),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Visual Image Notes for Revision
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VISUAL NOTES & DIAGRAMS FOR REVISION',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.note_alt_outlined, size: 16),
                  label: const Text('Manage Notes', style: TextStyle(fontSize: 12)),
                  onPressed: () => context.go('/notes'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (visualNotes.isEmpty)
              Card(
                color: Colors.grey.withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Visual Notes Attached Yet',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Attach handwritten circuit diagrams or formula sheets to your study notes to review them here.',
                              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Note', style: TextStyle(fontSize: 12)),
                        onPressed: () => context.go('/notes'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 175,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visualNotes.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final note = visualNotes[i];
                    return Container(
                      width: 260,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(note.imageBase64!),
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${note.subject} • ${note.topic}',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF1E3A8A)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                icon: const Icon(Icons.zoom_in, size: 16),
                                label: const Text('View & Zoom', style: TextStyle(fontSize: 11)),
                                onPressed: () => _showImagePreviewDialog(context, note),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  textStyle: const TextStyle(fontSize: 11),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Visual note "${note.title}" revised!'),
                                      backgroundColor: const Color(0xFF10B981),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Text('Revise'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Revision Sessions List
            const Text(
              'SCHEDULED REVISION SESSIONS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),
            if (revRepo.revisions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No revision sessions generated yet.'),
                ),
              )
            else
              ...revRepo.revisions.map((session) {
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
                                session.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: session.isCompleted ? Colors.green.shade50 : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                session.isCompleted ? 'COMPLETED ✓' : 'SCHEDULED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: session.isCompleted ? Colors.green.shade800 : Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Topics: ${session.topicsDue.join(", ")}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mistakes to review: ${session.mistakesToReview.length} • Flashcards: ${session.flashcardsDue.length}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!session.isCompleted)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                onPressed: () => revRepo.markCompleted(session.sessionId),
                                child: const Text('Mark Completed', style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

