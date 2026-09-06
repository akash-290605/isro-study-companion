import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/providers.dart';

class RevisionScreen extends ConsumerWidget {
  const RevisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revRepo = ref.watch(revisionRepositoryProvider);
    final mistakesRepo = ref.watch(mistakesRepositoryProvider);
    final flashcardsRepo = ref.watch(flashcardsRepositoryProvider);
    final testRepo = ref.watch(testRepositoryProvider);

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

