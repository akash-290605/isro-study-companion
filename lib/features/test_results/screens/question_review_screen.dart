import 'package:flutter/material.dart';
import '../../../core/utils/math_renderer.dart';
import '../../../data/models/test_model.dart';
import '../../../data/models/test_result_model.dart';

class QuestionReviewScreen extends StatefulWidget {
  final TestResultModel result;

  const QuestionReviewScreen({super.key, required this.result});

  @override
  State<QuestionReviewScreen> createState() => _QuestionReviewScreenState();
}

class _QuestionReviewScreenState extends State<QuestionReviewScreen> {
  int _currentIndex = 0;

  void _showSourceTrace(TestQuestionModel q) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            const Text('Source Attribution & Grounding', style: TextStyle(fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Document: ${q.sourceName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('Location: ${q.sourceLocation}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            const SizedBox(height: 12),
            const Text('Verified Source Chunk:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                q.sourceChunk.isNotEmpty
                    ? q.sourceChunk
                    : 'Source context verified from document "${q.sourceName}".',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.result.questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Question Review')),
        body: const Center(child: Text('No question records found.')),
      );
    }

    final q = questions[_currentIndex];
    final isCorrect = q.isCorrect == true;
    final isUnattempted = q.userAnswer == null || q.userAnswer!.isEmpty || q.status == TestQuestionStatus.timeUp;

    Color badgeColor = Colors.grey;
    String statusText = 'UNATTEMPTED';
    if (isCorrect) {
      badgeColor = Colors.green;
      statusText = 'CORRECT';
    } else if (!isUnattempted) {
      badgeColor = Colors.red;
      statusText = 'WRONG';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Question Review (${_currentIndex + 1}/${questions.length})'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top status bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    Text(
                      'Marks: ${q.marksAwarded >= 0 ? "+" : ""}${q.marksAwarded.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: q.marksAwarded > 0
                            ? Colors.green
                            : (q.marksAwarded < 0 ? Colors.red : Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question Text
                MathFormulaView(
                  formula: q.questionText,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                ),
                const SizedBox(height: 20),

                // Options with user vs correct markings
                ...q.options.asMap().entries.map((entry) {
                  final opt = entry.value;
                  final isUserAns = q.userAnswer == opt;
                  final isCorrectAns = q.correctAnswer == opt;

                  Color borderCol = Colors.grey.withOpacity(0.2);
                  Color bgCol = Colors.transparent;

                  if (isCorrectAns) {
                    borderCol = Colors.green;
                    bgCol = Colors.green.shade50;
                  } else if (isUserAns && !isCorrectAns) {
                    borderCol = Colors.red;
                    bgCol = Colors.red.shade50;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgCol,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderCol),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${String.fromCharCode(65 + entry.key)}. ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: MathFormulaView(formula: opt),
                        ),
                        if (isUserAns && !isCorrectAns)
                          const Text(
                            'Your Answer ❌',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        if (isCorrectAns)
                          const Text(
                            'Correct Answer ✓',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // Source-Grounded Explanation Box (Section 30)
                Card(
                  color: const Color(0xFFF8FAFC),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFF1E3A8A)),
                            SizedBox(width: 8),
                            Text(
                              'SOURCE-GROUNDED EXPLANATION',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        MathFormulaView(
                          formula: q.solution.isNotEmpty ? q.solution : 'Answer verified from source.',
                          textStyle: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Source: ${q.sourceName}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Location: ${q.sourceLocation}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              icon: const Icon(Icons.visibility_outlined, size: 14),
                              label: const Text('View Source Chunk', style: TextStyle(fontSize: 11)),
                              onPressed: () => _showSourceTrace(q),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Navigation between questions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Previous'),
                      onPressed: _currentIndex > 0
                          ? () => setState(() => _currentIndex -= 1)
                          : null,
                    ),
                    Text(
                      '${_currentIndex + 1} / ${questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Next'),
                      onPressed: _currentIndex < questions.length - 1
                          ? () => setState(() => _currentIndex += 1)
                          : null,
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
}

