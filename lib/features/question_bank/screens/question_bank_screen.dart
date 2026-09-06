import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/math_renderer.dart';
import '../../../data/models/question_model.dart';

class QuestionBankScreen extends ConsumerStatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  ConsumerState<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends ConsumerState<QuestionBankScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedSubject;
  Difficulty? _selectedDifficulty;
  bool? _isAttemptedFilter;

  void _showSourceChunkDialog(QuestionModel q) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            const Text('Source Grounding Verification', style: TextStyle(fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Source Document: ${q.sourceName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('Location: ${q.sourceLocation}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                q.sourceChunk.isNotEmpty ? q.sourceChunk : 'Verified from user document: ${q.sourceName}',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
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
    final qRepo = ref.watch(questionsRepositoryProvider);
    final filtered = qRepo.filterQuestions(
      subject: _selectedSubject,
      difficulty: _selectedDifficulty,
      isAttempted: _isAttemptedFilter,
      searchQuery: _searchQuery,
    );

    final allSubjects = qRepo.questions.map((q) => q.subject).where((s) => s.isNotEmpty).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Question Bank'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Generate AI Test'),
            onPressed: () => context.go('/ai-test'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search and Filters Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search questions, formulas, or sources...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          DropdownButton<String?>(
                            value: _selectedSubject,
                            hint: const Text('Subject: All'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Subject: All')),
                              ...allSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                            ],
                            onChanged: (v) => setState(() => _selectedSubject = v),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<Difficulty?>(
                            value: _selectedDifficulty,
                            hint: const Text('Difficulty: All'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Difficulty: All')),
                              ...Difficulty.values.map((d) => DropdownMenuItem(value: d, child: Text(d.label))),
                            ],
                            onChanged: (v) => setState(() => _selectedDifficulty = v),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<bool?>(
                            value: _isAttemptedFilter,
                            hint: const Text('Status: All'),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Status: All')),
                              DropdownMenuItem(value: false, child: Text('Unattempted')),
                              DropdownMenuItem(value: true, child: Text('Attempted')),
                            ],
                            onChanged: (v) => setState(() => _isAttemptedFilter = v),
                          ),
                          if (_selectedSubject != null || _selectedDifficulty != null || _isAttemptedFilter != null) ...[
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedSubject = null;
                                  _selectedDifficulty = null;
                                  _isAttemptedFilter = null;
                                });
                              },
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Questions List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No questions match the current filters.'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Upload Question Image / Paper'),
                            onPressed: () => context.go('/uploads'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final q = filtered[i];
                        Color diffColor = Colors.orange;
                        if (q.difficulty == Difficulty.easy) diffColor = Colors.green;
                        if (q.difficulty == Difficulty.hard) diffColor = Colors.red;

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
                                        color: diffColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        q.difficulty.label,
                                        style: TextStyle(
                                          color: diffColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${q.subject} • ${q.topic}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Delete Question',
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                      onPressed: () => qRepo.deleteQuestion(q.questionId),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                MathFormulaView(
                                  formula: q.questionText,
                                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                const SizedBox(height: 12),
                                ...q.options.asMap().entries.map((entry) {
                                  final isCorrect = entry.value == q.correctAnswer;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isCorrect ? Colors.green.shade50 : Colors.grey.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(6),
                                      border: isCorrect
                                          ? Border.all(color: Colors.green.shade300)
                                          : Border.all(color: Colors.transparent),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${String.fromCharCode(65 + entry.key)}. ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isCorrect ? Colors.green.shade900 : null,
                                          ),
                                        ),
                                        Expanded(
                                          child: MathFormulaView(formula: entry.value),
                                        ),
                                        if (isCorrect)
                                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      icon: const Icon(Icons.visibility_rounded, size: 14),
                                      label: const Text('View Source', style: TextStyle(fontSize: 11)),
                                      onPressed: () => _showSourceChunkDialog(q),
                                    ),
                                    Text(
                                      'Source: ${q.sourceName}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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

