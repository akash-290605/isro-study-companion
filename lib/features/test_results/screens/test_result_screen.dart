import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/test_result_model.dart';
import 'question_review_screen.dart';

class TestResultScreen extends ConsumerWidget {
  final TestResultModel result;

  const TestResultScreen({super.key, required this.result});

  String _formatTime(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPassed = result.percentage >= 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results & Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Score Hero Card
                Card(
                  color: isPassed ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isPassed ? Colors.green.shade300 : Colors.red.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          result.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${result.score.toStringAsFixed(2)} / ${result.maxScore.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: isPassed ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                        Text(
                          'Final Score: ${result.percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isPassed ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _statBadge('Correct: ${result.correctCount}', Colors.green),
                            const SizedBox(width: 8),
                            _statBadge('Wrong: ${result.wrongCount}', Colors.red),
                            const SizedBox(width: 8),
                            _statBadge('Unattempted: ${result.unattemptedCount}', Colors.grey),
                            const SizedBox(width: 8),
                            _statBadge('Negative Marks: -${result.negativeMarksDeducted.toStringAsFixed(2)}', Colors.amber.shade900),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Total Time Used: ${_formatTime(result.timeUsedSeconds)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Review Questions Button CTA
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.rate_review_rounded),
                  label: const Text(
                    'Review All Questions & Source Traces',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => QuestionReviewScreen(result: result),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Topic Performance Breakdown
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOPIC PERFORMANCE BREAKDOWN',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 16),
                        ...result.topicBreakdown.entries.map((entry) {
                          final tp = entry.value;
                          Color color = Colors.orange;
                          if (tp.accuracy >= 75) color = Colors.green;
                          if (tp.accuracy < 55) color = Colors.red;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(tp.topic, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text(
                                      '${tp.accuracy.toStringAsFixed(0)}% (${tp.correct}/${tp.total})',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: tp.accuracy / 100,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Difficulty Performance Breakdown
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DIFFICULTY PERFORMANCE',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: result.difficultyBreakdown.entries.map((entry) {
                            final dp = entry.value;
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(dp.difficulty, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('${dp.accuracy.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text('${dp.correct} / ${dp.total} correct', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bottom Navigation actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.error_outline_rounded, color: Colors.red),
                        label: const Text('View Mistake Notebook'),
                        onPressed: () => context.go('/mistakes'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Back to Dashboard'),
                        onPressed: () => context.go('/'),
                      ),
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

  Widget _statBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

