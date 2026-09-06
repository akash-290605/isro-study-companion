import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/rag_service.dart';
import '../../../data/models/test_model.dart';
import '../../test_engine/screens/test_runner_screen.dart';

class TestPreviewScreen extends ConsumerWidget {
  final TestModel test;
  final RAGGenerationResult ragResult;

  const TestPreviewScreen({
    super.key,
    required this.test,
    required this.ragResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Summary Preview'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MANDATORY TEST SUMMARY',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      test.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Test Type
                    _summaryItem('Test Type:', test.testType.label),
                    const Divider(height: 20),

                    // Selected Topics
                    _summaryItem(
                      'Selected Topics:',
                      ragResult.topicDistribution.entries
                          .map((e) => '${e.key} (${e.value} Qs)')
                          .join('\n'),
                    ),
                    const Divider(height: 20),

                    // Questions & Difficulty breakdown
                    _summaryItem(
                      'Total Questions:',
                      '${test.questionCount} Questions',
                      boldValue: true,
                    ),
                    _summaryItem(
                      'Difficulty Breakdown:',
                      'Easy: ${ragResult.difficultyDistribution['EASY'] ?? 0} | '
                      'Medium: ${ragResult.difficultyDistribution['MEDIUM'] ?? 0} | '
                      'Hard: ${ragResult.difficultyDistribution['HARD'] ?? 0}',
                    ),
                    const Divider(height: 20),

                    // Per-question timer
                    _summaryItem(
                      'Per-Question Timer:',
                      'Easy: ${test.easyTime}s | Medium: ${test.mediumTime}s | Hard: ${test.hardTime}s',
                    ),
                    const Divider(height: 20),

                    // Marking Scheme
                    _summaryItem(
                      'Marking Scheme:',
                      'Correct: +${test.correctMarks} | '
                      'Wrong: ${test.negativeMarkingEnabled ? test.negativeMarks : 0} | '
                      'Unattempted: ${test.unattemptedMarks}',
                    ),
                    _summaryItem(
                      'Negative Marking:',
                      test.negativeMarkingEnabled ? 'ENABLED (-${test.negativeMarks.abs()})' : 'DISABLED (0 deduction)',
                      valueColor: test.negativeMarkingEnabled ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                    const Divider(height: 20),

                    // Sources used
                    _summaryItem(
                      'Source Materials:',
                      '${test.selectedSources.length} uploaded study materials (RAG Grounded)',
                    ),
                    if (test.strictModeNoPrevious) ...[
                      const Divider(height: 20),
                      _summaryItem(
                        'Strict Mode:',
                        'ENABLED (No returning to previous questions)',
                        valueColor: Colors.amber.shade900,
                      ),
                    ],
                    const SizedBox(height: 28),

                    // Start Test CTA
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (ctx) => TestRunnerScreen(test: test),
                          ),
                        );
                      },
                      child: const Text(
                        'START TEST NOW',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(
    String title,
    String value, {
    bool boldValue = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: boldValue ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

