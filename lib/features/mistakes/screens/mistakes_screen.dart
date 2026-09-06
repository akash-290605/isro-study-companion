import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/math_renderer.dart';
import '../../../data/models/mistake_model.dart';

class MistakesScreen extends ConsumerStatefulWidget {
  const MistakesScreen({super.key});

  @override
  ConsumerState<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends ConsumerState<MistakesScreen> {
  bool _hideResolved = false;

  void _showNoteDialog(MistakeModel m) {
    final noteCtrl = TextEditingController(text: m.userNotes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Personal Learning Note'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'What went wrong? E.g., Forgot that efficiency is 50% under max power transfer...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(mistakesRepositoryProvider).updateNotes(m.mistakeId, noteCtrl.text.trim());
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
    final mistakesRepo = ref.watch(mistakesRepositoryProvider);
    final allMistakes = mistakesRepo.mistakes;
    final displayMistakes = _hideResolved
        ? allMistakes.where((m) => !m.isResolved).toList()
        : allMistakes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mistake Notebook'),
        actions: [
          // Filter toggle
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: const Text('Hide Resolved', style: TextStyle(fontSize: 12)),
              selected: _hideResolved,
              onSelected: (v) => setState(() => _hideResolved = v),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('Revise Mistakes', style: TextStyle(fontSize: 12)),
            onPressed: () => context.go('/revision'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Info Header Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Every question answered incorrectly in your tests is automatically logged here. Add personal notes and mark them resolved once understood.',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: displayMistakes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.green.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No active mistakes recorded!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Complete mock tests in AI Test to track questions needing revision.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.go('/ai-test'),
                            child: const Text('Take Practice Test'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: displayMistakes.length,
                      itemBuilder: (ctx, i) {
                        final m = displayMistakes[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: m.isResolved ? Colors.green.shade100 : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        m.isResolved ? 'RESOLVED ✓' : 'UNRESOLVED ⚠',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: m.isResolved ? Colors.green.shade900 : Colors.red.shade900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${m.subject} • ${m.topic}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Delete Entry',
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                      onPressed: () => mistakesRepo.deleteMistake(m.mistakeId),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                MathFormulaView(
                                  formula: m.questionText,
                                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text('Your Answer: ', style: TextStyle(fontSize: 12, color: Colors.red)),
                                          Expanded(
                                            child: MathFormulaView(
                                              formula: m.userAnswer,
                                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Text('Correct Answer: ', style: TextStyle(fontSize: 12, color: Colors.green)),
                                          Expanded(
                                            child: MathFormulaView(
                                              formula: m.correctAnswer,
                                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (m.solution.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Explanation: ${m.solution}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                ],
                                if (m.userNotes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.amber.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit_note, size: 16, color: Colors.amber),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'My Note: ${m.userNotes}',
                                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.note_add_outlined, size: 16),
                                      label: Text(m.userNotes.isEmpty ? 'Add Personal Note' : 'Edit Note'),
                                      onPressed: () => _showNoteDialog(m),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: m.isResolved ? Colors.grey : Colors.green,
                                      ),
                                      icon: Icon(m.isResolved ? Icons.replay : Icons.check, size: 16),
                                      label: Text(m.isResolved ? 'Mark Unresolved' : 'Mark as Resolved'),
                                      onPressed: () => mistakesRepo.toggleResolved(m.mistakeId),
                                    ),
                                  ],
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

