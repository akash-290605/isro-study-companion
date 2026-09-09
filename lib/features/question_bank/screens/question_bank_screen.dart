import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/providers.dart';
import '../../../core/utils/math_renderer.dart';
import '../../../core/widgets/technical_diagram_widget.dart';
import '../../../data/models/question_model.dart';
import '../../../data/repositories/questions_repository.dart';
import '../widgets/import_material_dialog.dart';

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
  QuestionStatus? _selectedStatus;
  QuestionType? _selectedType;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openImportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ImportMaterialDialog(),
    );
  }

  void _openCreateQuestionDialog() {
    final textCtrl = TextEditingController();
    final optACtrl = TextEditingController();
    final optBCtrl = TextEditingController();
    final optCCtrl = TextEditingController();
    final optDCtrl = TextEditingController();
    final solCtrl = TextEditingController();
    final topicCtrl = TextEditingController(text: 'RLC Circuits');
    String subject = 'Network Theory';
    String correctAns = 'A';
    Difficulty diff = Difficulty.medium;
    QuestionType qType = QuestionType.mcq;
    DiagramType dType = DiagramType.none;

    final subjects = [
      'Network Theory',
      'Digital Electronics',
      'Signals & Systems',
      'Electronic Devices & Circuits',
      'Control Systems',
      'Communications',
      'Electromagnetics',
      'Computer Science / Microprocessors',
      'General Engineering Mathematics',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF1E3A8A)),
              SizedBox(width: 8),
              Text('Create New Question', style: TextStyle(fontSize: 17)),
            ],
          ),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: subject,
                          decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                          items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setDlgState(() => subject = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: topicCtrl,
                          decoration: const InputDecoration(labelText: 'Topic', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Difficulty>(
                          value: diff,
                          decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                          items: Difficulty.values.map((d) => DropdownMenuItem(value: d, child: Text(d.label))).toList(),
                          onChanged: (v) => setDlgState(() => diff = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<QuestionType>(
                          value: qType,
                          decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                          items: QuestionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                          onChanged: (v) => setDlgState(() => qType = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<DiagramType>(
                          value: dType,
                          decoration: const InputDecoration(labelText: 'Diagram', border: OutlineInputBorder()),
                          items: DiagramType.values.map((dt) => DropdownMenuItem(value: dt, child: Text(dt.name))).toList(),
                          onChanged: (v) => setDlgState(() => dType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: r'Question Text (Supports LaTeX e.g. $f_0 = \frac{1}{2\pi\sqrt{LC}}$)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(controller: optACtrl, decoration: const InputDecoration(labelText: 'Option A', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 6),
                  TextField(controller: optBCtrl, decoration: const InputDecoration(labelText: 'Option B', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 6),
                  TextField(controller: optCCtrl, decoration: const InputDecoration(labelText: 'Option C', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 6),
                  TextField(controller: optDCtrl, decoration: const InputDecoration(labelText: 'Option D', border: OutlineInputBorder(), isDense: true)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Correct Answer:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: correctAns,
                        items: const [
                          DropdownMenuItem(value: 'A', child: Text('A')),
                          DropdownMenuItem(value: 'B', child: Text('B')),
                          DropdownMenuItem(value: 'C', child: Text('C')),
                          DropdownMenuItem(value: 'D', child: Text('D')),
                        ],
                        onChanged: (v) => setDlgState(() => correctAns = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: solCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Explanation / Solution',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (textCtrl.text.trim().isEmpty) return;

                final userId = ref.read(authRepositoryProvider).currentUser?.id ?? 'user';
                final newQ = QuestionModel(
                  questionId: 'q_${const Uuid().v4()}',
                  userId: userId,
                  questionText: textCtrl.text.trim(),
                  options: [
                    'A. ${optACtrl.text.trim()}',
                    'B. ${optBCtrl.text.trim()}',
                    'C. ${optCCtrl.text.trim()}',
                    'D. ${optDCtrl.text.trim()}',
                  ],
                  correctAnswer: correctAns,
                  solution: solCtrl.text.trim(),
                  subject: subject,
                  topic: topicCtrl.text.trim(),
                  difficulty: diff,
                  questionType: qType,
                  status: QuestionStatus.unsolved,
                  verificationStatus: VerificationStatus.sourceVerified,
                  diagramType: dType,
                  sourceId: 'manual',
                  sourceName: 'Created by User',
                  sourceLocation: 'Personal Question Bank',
                  sourceChunk: '',
                  createdAt: DateTime.now(),
                );

                await ref.read(questionsRepositoryProvider).addQuestion(newQ);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Question added successfully!'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Save Question'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qRepo = ref.watch(questionsRepositoryProvider);
    final filtered = qRepo.filterQuestions(
      subject: _selectedSubject,
      difficulty: _selectedDifficulty,
      status: _selectedStatus,
      questionType: _selectedType,
      searchQuery: _searchQuery,
    );

    final allSubjects = qRepo.questions.map((q) => q.subject).where((s) => s.isNotEmpty).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Bank', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.add_to_photos_rounded, size: 18),
            label: const Text('Import Material'),
            onPressed: _openImportDialog,
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Question'),
            onPressed: _openCreateQuestionDialog,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
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
            // Top Status & Analytics Counter Row
            _buildStatsHeader(qRepo),
            const SizedBox(height: 12),

            // Search and Filters Bar
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search questions, topics, formulas, or source documents...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Subject Dropdown
                          DropdownButton<String?>(
                            value: _selectedSubject,
                            hint: const Text('Subject: All'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Subject: All')),
                              ...allSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                            ],
                            onChanged: (v) => setState(() => _selectedSubject = v),
                          ),
                          const SizedBox(width: 14),

                          // Status Dropdown
                          DropdownButton<QuestionStatus?>(
                            value: _selectedStatus,
                            hint: const Text('Status: All'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Status: All')),
                              ...QuestionStatus.values.map((st) => DropdownMenuItem(value: st, child: Text(st.label))),
                            ],
                            onChanged: (v) => setState(() => _selectedStatus = v),
                          ),
                          const SizedBox(width: 14),

                          // Difficulty Dropdown
                          DropdownButton<Difficulty?>(
                            value: _selectedDifficulty,
                            hint: const Text('Difficulty: All'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Difficulty: All')),
                              ...Difficulty.values.map((d) => DropdownMenuItem(value: d, child: Text(d.label))),
                            ],
                            onChanged: (v) => setState(() => _selectedDifficulty = v),
                          ),
                          const SizedBox(width: 14),

                          // Question Type Dropdown
                          DropdownButton<QuestionType?>(
                            value: _selectedType,
                            hint: const Text('Type: All'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Type: All')),
                              ...QuestionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
                            ],
                            onChanged: (v) => setState(() => _selectedType = v),
                          ),

                          if (_selectedSubject != null || _selectedStatus != null || _selectedDifficulty != null || _selectedType != null || _searchQuery.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            TextButton.icon(
                              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                              label: const Text('Reset Filters'),
                              onPressed: () {
                                setState(() {
                                  _selectedSubject = null;
                                  _selectedStatus = null;
                                  _selectedDifficulty = null;
                                  _selectedType = null;
                                  _searchQuery = '';
                                  _searchCtrl.clear();
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Questions List
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final q = filtered[i];
                        return _buildQuestionCardItem(q, qRepo);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(QuestionsRepository qRepo) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            label: 'Total Questions',
            count: qRepo.totalCount,
            color: Colors.blue,
            icon: Icons.quiz_rounded,
            isSelected: _selectedStatus == null,
            onTap: () => setState(() => _selectedStatus = null),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            label: 'Unsolved',
            count: qRepo.unsolvedCount,
            color: Colors.red,
            icon: Icons.radio_button_unchecked_rounded,
            isSelected: _selectedStatus == QuestionStatus.unsolved,
            onTap: () => setState(() => _selectedStatus = QuestionStatus.unsolved),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            label: 'Partially Solved',
            count: qRepo.partiallySolvedCount,
            color: Colors.amber.shade800,
            icon: Icons.adjust_rounded,
            isSelected: _selectedStatus == QuestionStatus.partiallySolved,
            onTap: () => setState(() => _selectedStatus = QuestionStatus.partiallySolved),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            label: 'Solved',
            count: qRepo.solvedCount,
            color: Colors.green,
            icon: Icons.check_circle_rounded,
            isSelected: _selectedStatus == QuestionStatus.solved,
            onTap: () => setState(() => _selectedStatus = QuestionStatus.solved),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatTile(
            label: 'Needs Review',
            count: qRepo.needsReviewCount,
            color: Colors.purple,
            icon: Icons.help_outline_rounded,
            isSelected: _selectedStatus == QuestionStatus.needsReview,
            onTap: () => setState(() => _selectedStatus = QuestionStatus.needsReview),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 0.18 : 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          const Text(
            'No Questions in Question Bank',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Import your PDF question papers, syllabus notes, Word docs, or photos to automatically extract questions with AI.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.add_to_photos_rounded),
                label: const Text('Import Study Material'),
                onPressed: _openImportDialog,
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Question Manually'),
                onPressed: _openCreateQuestionDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCardItem(QuestionModel q, QuestionsRepository qRepo) {
    if (QuestionsRepository.isCorruptedQuestion(q)) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
          title: const Text('Corrupted Document Stream Isolated', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
          subtitle: const Text('Contains unparsed document stream data. Click to remove permanently.', style: TextStyle(fontSize: 12)),
          trailing: IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Delete Corrupted Entry',
            onPressed: () => qRepo.deleteQuestion(q.questionId),
          ),
        ),
      );
    }

    Color diffColor = Colors.orange;
    if (q.difficulty == Difficulty.easy) diffColor = Colors.green;
    if (q.difficulty == Difficulty.hard) diffColor = Colors.red;

    Color statusColor = Colors.grey;
    switch (q.status) {
      case QuestionStatus.solved:
        statusColor = Colors.green;
        break;
      case QuestionStatus.partiallySolved:
        statusColor = Colors.amber.shade800;
        break;
      case QuestionStatus.attempted:
        statusColor = Colors.orange;
        break;
      case QuestionStatus.unsolved:
        statusColor = Colors.red;
        break;
      case QuestionStatus.needsReview:
        statusColor = Colors.purple;
        break;
    }

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top metadata row
            Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    q.status.label,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),

                // Difficulty Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: diffColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    q.difficulty.label,
                    style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),

                // Subject • Topic
                Expanded(
                  child: Text(
                    '${q.subject} • ${q.topic}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Quick Status Dropdown Menu
                PopupMenuButton<QuestionStatus>(
                  tooltip: 'Update Question Status',
                  icon: const Icon(Icons.more_vert, size: 18),
                  itemBuilder: (ctx) => QuestionStatus.values.map((st) {
                    return PopupMenuItem(
                      value: st,
                      child: Text('Mark as ${st.label}'),
                    );
                  }).toList(),
                  onSelected: (st) => qRepo.updateQuestionStatus(q.questionId, st),
                ),

                // Delete Button
                IconButton(
                  tooltip: 'Delete Question',
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                  onPressed: () => qRepo.deleteQuestion(q.questionId),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Question Text with Math rendering
            MathFormulaView(
              formula: q.questionText,
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Procedural Diagram Preview if present
            if (q.diagramType != DiagramType.none || q.diagramData != null || q.diagramImageBase64 != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: TechnicalDiagramWidget.fromQuestion(
                    q,
                    height: 150,
                  ),
                ),
              ),
            ],

            // Options summary (if MCQ)
            if (q.options.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: q.options.take(4).map((opt) {
                  final isAnswer = opt.startsWith(q.correctAnswer) || opt == q.correctAnswer;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isAnswer ? Colors.green.shade50 : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: isAnswer ? Border.all(color: Colors.green.shade300) : null,
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isAnswer ? FontWeight.bold : FontWeight.normal,
                        color: isAnswer ? Colors.green.shade900 : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Bottom Actions & Source Info
            Row(
              children: [
                Text(
                  'Source: ${q.sourceName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View & Solve', style: TextStyle(fontSize: 12)),
                  onPressed: () => context.go('/question-bank/detail/${q.questionId}'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
