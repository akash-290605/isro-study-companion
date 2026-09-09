import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/providers.dart';
import '../../../core/utils/math_renderer.dart';
import '../../../core/widgets/technical_diagram_widget.dart';
import '../../../data/models/question_model.dart';
import '../../../data/repositories/questions_repository.dart';
import '../widgets/edit_solution_dialog.dart';
import '../widgets/import_material_dialog.dart';
import '../widgets/manual_question_dialog.dart';
import '../../../data/datasources/smart_question_generator_service.dart';

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
    ManualQuestionDialog.show(context);
  }

  Future<void> _openAiSearchSimilarDialog(QuestionModel seedQuestion) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF7C3AED)),
                SizedBox(height: 16),
                Text('Searching & Generating Similar Questions...', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Grounded in engineering curriculum & verified web references', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );

    final userId = ref.read(authRepositoryProvider).currentUser?.id ?? 'user';
    List<QuestionModel> similarQuestions = [];
    try {
      similarQuestions = await SmartQuestionGeneratorService.searchAndGenerateSimilarQuestions(
        seedQuestion: seedQuestion,
        count: 3,
        currentUserId: userId,
      );
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

    if (similarQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate similar questions. Please try again.')),
      );
      return;
    }

    final Set<String> selectedIds = similarQuestions.map((q) => q.questionId).toSet();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Searched Similar Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      'Based on: ${seedQuestion.topic.isNotEmpty ? seedQuestion.topic : seedQuestion.subject}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Color(0xFF7C3AED)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'These questions have been synthesized with verified step-by-step solutions and web citations based on your seed question.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF5B21B6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...similarQuestions.map((simQ) {
                    final isSelected = selectedIds.contains(simQ.questionId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF7C3AED) : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  activeColor: const Color(0xFF7C3AED),
                                  onChanged: (v) {
                                    setModalState(() {
                                      if (v == true) {
                                        selectedIds.add(simQ.questionId);
                                      } else {
                                        selectedIds.remove(simQ.questionId);
                                      }
                                    });
                                  },
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    simQ.questionType.label,
                                    style: TextStyle(fontSize: 10, color: Colors.purple.shade800, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  simQ.difficulty.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: simQ.difficulty == Difficulty.easy ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(simQ.questionText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            if (simQ.options.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              ...simQ.options.map((opt) => Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 2),
                                child: Text(opt, style: const TextStyle(fontSize: 12)),
                              )),
                            ],
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Answer: ${simQ.correctAnswer} — ${simQ.solution}',
                                      style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_task_rounded, size: 16),
              label: Text('Add ${selectedIds.length} to Question Bank'),
              onPressed: selectedIds.isEmpty
                  ? null
                  : () async {
                      final toAdd = similarQuestions.where((q) => selectedIds.contains(q.questionId)).toList();
                      await ref.read(questionsRepositoryProvider).addQuestions(toAdd);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Successfully added ${toAdd.length} AI-searched questions to Question Bank!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAiTopicGeneratorDialog() async {
    final qRepo = ref.read(questionsRepositoryProvider);
    final existingTopics = qRepo.questions.map((q) => q.topic).where((t) => t.isNotEmpty).toSet().toList();
    final allTopics = {
      ...existingTopics,
      'Network Analysis',
      'RLC Transient Circuits',
      'Two-Port Networks',
      'Boolean Algebra & Logic Gates',
      'Sequential Circuits & Timing',
      'Control Systems & Nyquist Analysis',
      'Bode Plots & Frequency Response',
      'Op-Amp Configurations',
      'Signals & Sampling Theorem',
      'Fourier & Laplace Transforms',
    }.toList();

    String selectedTopic = allTopics.first;
    int countToGen = 5;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text('AI Question Generator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-generate syllabus-aligned questions with verified solutions and web citations to expand your Question Bank:',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedTopic,
                  decoration: const InputDecoration(
                    labelText: 'Engineering Topic',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: allTopics.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setDlgState(() => selectedTopic = v!),
                ),
                const SizedBox(height: 14),
                const Text('Number of Questions to Generate:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [3, 5, 10].map((c) {
                    return ChoiceChip(
                      label: Text('$c Questions'),
                      selected: countToGen == c,
                      onSelected: (_) => setDlgState(() => countToGen = c),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.bolt_rounded, size: 16),
              label: const Text('Generate Now'),
              onPressed: () async {
                Navigator.pop(ctx);
                final dummySeed = QuestionModel(
                  questionId: 'seed_gen',
                  userId: 'user',
                  sourceId: 'syllabus',
                  sourceName: 'ISRO ECE Syllabus',
                  questionText: 'Topic question on $selectedTopic',
                  options: const [],
                  correctAnswer: 'A',
                  subject: 'Electronics & Communication',
                  topic: selectedTopic,
                  createdAt: DateTime.now(),
                );
                await _openAiSearchSimilarDialog(dummySeed);
              },
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
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED),
              side: const BorderSide(color: Color(0xFF7C3AED)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('AI Question Generator'),
            onPressed: _openAiTopicGeneratorDialog,
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

            // Solving photo indicator
            if (q.solutionImageBase64 != null && q.solutionImageBase64!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment_turned_in_rounded, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('Solving Photo Attached', style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],

            // Bottom Actions & Source Info
            Row(
              children: [
                Text(
                  'Source: ${q.sourceName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF7C3AED),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                  label: const Text('AI Search Similar', style: TextStyle(fontSize: 12)),
                  onPressed: () => _openAiSearchSimilarDialog(q),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(
                    q.solution.isEmpty ? Icons.upload_file_rounded : Icons.edit_note_rounded,
                    size: 14,
                    color: q.solution.isEmpty ? Colors.amber.shade900 : const Color(0xFF1E3A8A),
                  ),
                  label: Text(
                    q.solution.isEmpty ? 'Upload Solution' : 'Edit Solution',
                    style: TextStyle(
                      fontSize: 12,
                      color: q.solution.isEmpty ? Colors.amber.shade900 : const Color(0xFF1E3A8A),
                    ),
                  ),
                  onPressed: () => EditSolutionDialog.show(context, q),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
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
