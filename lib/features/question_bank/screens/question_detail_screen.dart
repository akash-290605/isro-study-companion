import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/providers.dart';
import '../../../core/utils/math_renderer.dart';
import '../../../core/widgets/technical_diagram_widget.dart';
import '../../../data/datasources/ai_answer_search_service.dart';
import '../../../data/datasources/ai_solution_evaluator_service.dart';
import '../../../data/datasources/smart_question_generator_service.dart';
import '../../../data/models/question_model.dart';
import '../widgets/edit_solution_dialog.dart';

class QuestionDetailScreen extends ConsumerStatefulWidget {
  final String questionId;

  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  ConsumerState<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends ConsumerState<QuestionDetailScreen> {
  bool _showSolution = false;
  bool _isSearchingAnswer = false;
  bool _isEvaluatingSolution = false;
  bool _isGeneratingVariation = false;

  // Student Solving
  final TextEditingController _studentSolutionCtrl = TextEditingController();
  String? _handwrittenImageBase64;
  String? _handwrittenImageName;
  SolutionEvaluationResult? _evaluationResult;

  // Notes
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = _getQuestion();
      if (q != null) {
        _notesCtrl.text = q.userNotes;
      }
    });
  }

  @override
  void dispose() {
    _studentSolutionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  QuestionModel? _getQuestion() {
    final questions = ref.read(questionsRepositoryProvider).questions;
    final index = questions.indexWhere((q) => q.questionId == widget.questionId);
    return index >= 0 ? questions[index] : null;
  }

  Future<void> _pickHandwrittenPhoto() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        setState(() {
          _handwrittenImageBase64 = base64Encode(bytes);
          _handwrittenImageName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    }
  }

  Future<void> _evaluateSolutionWithAI(QuestionModel q) async {
    if (_studentSolutionCtrl.text.trim().isEmpty && _handwrittenImageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your written solution or upload a photo of your work.')),
      );
      return;
    }

    setState(() => _isEvaluatingSolution = true);

    final result = await AISolutionEvaluatorService.evaluateUserSolution(
      question: q,
      userTextAnswer: _studentSolutionCtrl.text,
      handwrittenImageBase64: _handwrittenImageBase64,
    );

    final isCorrect = result.scoreOutOfTen >= 7.0;
    await ref.read(questionsRepositoryProvider).recordDetailedAttempt(
      q.questionId,
      isCorrect,
    );
    await ref.read(questionsRepositoryProvider).updateQuestionStatus(
      q.questionId,
      result.resultingStatus,
    );

    if (!mounted) return;

    setState(() {
      _evaluationResult = result;
      _isEvaluatingSolution = false;
      _showSolution = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Evaluation complete! Status updated to ${result.resultingStatus.label}'),
        backgroundColor: isCorrect ? Colors.green.shade700 : Colors.amber.shade900,
      ),
    );
  }

  Future<void> _searchAndVerifyAnswer(QuestionModel q) async {
    setState(() => _isSearchingAnswer = true);

    final webResult = await AIAnswerSearchService.searchAndVerifyAnswer(q);

    final updated = q.copyWith(
      correctAnswer: webResult.answer,
      solution: webResult.explanation,
      verificationStatus: VerificationStatus.aiVerified,
      webReferences: webResult.referenceSources,
    );

    await ref.read(questionsRepositoryProvider).saveQuestion(updated);

    if (!mounted) return;

    setState(() {
      _isSearchingAnswer = false;
      _showSolution = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Answer verified & synthesized from engineering references!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _generateVariation(QuestionModel q, VariationType type) async {
    setState(() => _isGeneratingVariation = true);

    final userId = ref.read(authRepositoryProvider).currentUser?.id ?? 'user';
    final variation = await SmartQuestionGeneratorService.generateVariation(
      baseQuestion: q,
      variationType: type,
      currentUserId: userId,
    );

    if (!mounted) return;
    setState(() => _isGeneratingVariation = false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            Text('Generated ${type.label}', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${variation.subject} • ${variation.topic} • ${variation.difficulty.label}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                  ),
                ),
                const SizedBox(height: 12),
                MathFormulaView(
                  formula: variation.questionText,
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (variation.options.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...variation.options.map((opt) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(opt, style: const TextStyle(fontSize: 13)),
                      )),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'Answer: ${variation.correctAnswer}\n${variation.solution}',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add to Question Bank'),
            onPressed: () async {
              await ref.read(questionsRepositoryProvider).addQuestion(variation);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Variation added to Question Bank!'), backgroundColor: Colors.green),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _bookmarkForRevision(QuestionModel q) async {
    final revRepo = ref.read(revisionRepositoryProvider);

    await revRepo.generateSmartRevision(
      weakTopics: [q.topic],
      mistakeIds: [q.questionId],
      dueFlashcardIds: const [],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to Revision Schedule!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch repository for real-time updates
    final qRepo = ref.watch(questionsRepositoryProvider);
    final questionList = qRepo.questions;
    final index = questionList.indexWhere((item) => item.questionId == widget.questionId);

    if (index < 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Question Detail')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Question not found or has been deleted.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/question-bank'),
                child: const Text('Back to Question Bank'),
              ),
            ],
          ),
        ),
      );
    }

    final q = questionList[index];

    return Scaffold(
      appBar: AppBar(
        title: Text('${q.subject} • ${q.topic}', style: const TextStyle(fontSize: 16)),
        actions: [
          // Question Status Badge & Dropdown
          _buildStatusDropdown(q),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Bookmark for Revision',
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () => _bookmarkForRevision(q),
          ),
          IconButton(
            tooltip: 'Delete Question',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final navigator = GoRouter.of(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Question?'),
                  content: const Text('Are you sure you want to remove this question from your Question Bank?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                await qRepo.deleteQuestion(q.questionId);
                navigator.go('/question-bank');
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Metadata & Badges Card
            _buildQuestionCard(q),
            const SizedBox(height: 20),

            // Missing Answer / Web Verification Card
            if (q.correctAnswer.isEmpty || q.correctAnswer == 'ANSWER UNKNOWN' || q.verificationStatus == VerificationStatus.unknown)
              _buildAnswerVerificationCard(q),

            const SizedBox(height: 20),

            // Interactive Solve & AI Solution Evaluation Section
            _buildInteractiveSolveSection(q),

            const SizedBox(height: 20),

            // AI Targeted Practice & Variations
            _buildVariationsSection(q),

            const SizedBox(height: 20),

            // Personal Notes Section
            _buildNotesSection(q),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(QuestionModel q) {
    Color badgeColor = Colors.grey;
    switch (q.status) {
      case QuestionStatus.solved:
        badgeColor = Colors.green;
        break;
      case QuestionStatus.partiallySolved:
        badgeColor = Colors.amber.shade800;
        break;
      case QuestionStatus.attempted:
        badgeColor = Colors.orange;
        break;
      case QuestionStatus.unsolved:
        badgeColor = Colors.red;
        break;
      case QuestionStatus.needsReview:
        badgeColor = Colors.purple;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<QuestionStatus>(
          value: q.status,
          icon: Icon(Icons.arrow_drop_down, color: badgeColor),
          dropdownColor: Theme.of(context).cardColor,
          items: QuestionStatus.values.map((st) {
            return DropdownMenuItem(
              value: st,
              child: Text(
                st.label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: badgeColor),
              ),
            );
          }).toList(),
          onChanged: (newStatus) {
            if (newStatus != null) {
              ref.read(questionsRepositoryProvider).updateQuestionStatus(q.questionId, newStatus);
            }
          },
        ),
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel q) {
    Color diffColor = Colors.orange;
    if (q.difficulty == Difficulty.easy) diffColor = Colors.green;
    if (q.difficulty == Difficulty.hard) diffColor = Colors.red;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top badges row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    q.difficulty.label,
                    style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    q.questionType.label,
                    style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    q.verificationStatus.label,
                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const Spacer(),
                Text(
                  'Source: ${q.sourceName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question Text with Math rendering
            MathFormulaView(
              formula: q.questionText,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Procedural Technical Diagram
            if (q.diagramType != DiagramType.none || q.diagramData != null || q.diagramImageBase64 != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schema_rounded, size: 16, color: Color(0xFF1E3A8A)),
                        const SizedBox(width: 6),
                        Text(
                          'Technical Diagram / Circuit Representation',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TechnicalDiagramWidget.fromQuestion(
                        q,
                        height: 220,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Options List
            if (q.options.isNotEmpty) ...[
              const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              ...q.options.asMap().entries.map((entry) {
                final opt = entry.value;
                final isAnswer = opt.startsWith(q.correctAnswer) || opt == q.correctAnswer;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isAnswer && _showSolution ? Colors.green.shade50 : Colors.grey.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAnswer && _showSolution ? Colors.green.shade300 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAnswer && _showSolution ? Colors.green : Colors.grey.shade300,
                        ),
                        child: Text(
                          String.fromCharCode(65 + entry.key),
                          style: TextStyle(
                            color: isAnswer && _showSolution ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MathFormulaView(formula: opt),
                      ),
                      if (isAnswer && _showSolution)
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 12),

            // Solution Reveal Toggle
            Row(
              children: [
                OutlinedButton.icon(
                  icon: Icon(_showSolution ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16),
                  label: Text(_showSolution ? 'Hide Solution' : 'Show Answer & Detailed Solution'),
                  onPressed: () => setState(() => _showSolution = !_showSolution),
                ),
                const Spacer(),
                Text(
                  'Attempts: ${q.attemptCount} (${q.correctAttempts} correct)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),

            if (_showSolution) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_rounded, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Correct Answer: ${q.correctAnswer}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade900),
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: const Icon(Icons.edit_note_rounded, size: 16),
                          label: const Text('Edit Solution', style: TextStyle(fontSize: 12)),
                          onPressed: () => EditSolutionDialog.show(context, q),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    MathFormulaView(
                      formula: q.solution.isNotEmpty ? q.solution : 'No detailed solution provided.',
                      textStyle: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    if (q.solutionImageBase64 != null && q.solutionImageBase64!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Handwritten Solving Work / Solution Photo:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Image.memory(
                            base64Decode(q.solutionImageBase64!),
                            fit: BoxFit.contain,
                            height: 240,
                            errorBuilder: (context, error, stackTrace) => const Center(child: Text('Invalid solution image')),
                          ),
                        ),
                      ),
                    ],
                    if (q.webReferences.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const Text(
                        'Verified Sources & References:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      ...q.webReferences.map((ref) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.open_in_new, size: 12, color: Colors.blue),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(ref, style: const TextStyle(fontSize: 11, color: Colors.blue)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerVerificationCard(QuestionModel q) {
    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: Colors.amber, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Answer Not Fully Verified Yet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This question was imported without an answer key or flagged as Needs Review. Run AI Web Research to find and verify the correct solution.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              icon: _isSearchingAnswer
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.travel_explore_rounded, size: 18),
              label: Text(_isSearchingAnswer ? 'Researching...' : 'Search & Verify Answer'),
              onPressed: _isSearchingAnswer ? null : () => _searchAndVerifyAnswer(q),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveSolveSection(QuestionModel q) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.mode_edit_outline_rounded, color: Color(0xFF1E3A8A), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solve Question & AI Evaluation Studio',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Type your solution or upload a photo of your handwritten paper work for automated scoring & conceptual feedback.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Solution Text Field
            TextField(
              controller: _studentSolutionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your step-by-step solution, formulas used, or final calculated value here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            // Handwritten Photo Upload Row
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: Text(_handwrittenImageBase64 == null ? 'Upload Handwritten Work Photo' : 'Replace Photo'),
                  onPressed: _pickHandwrittenPhoto,
                ),
                const SizedBox(width: 12),
                if (_handwrittenImageBase64 != null) ...[
                  Chip(
                    avatar: const Icon(Icons.image, size: 16, color: Colors.green),
                    label: Text(_handwrittenImageName ?? 'Handwritten Photo Attached'),
                    onDeleted: () => setState(() {
                      _handwrittenImageBase64 = null;
                      _handwrittenImageName = null;
                    }),
                  ),
                ],
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: _isEvaluatingSolution
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_isEvaluatingSolution ? 'Evaluating...' : 'Evaluate with AI'),
                  onPressed: _isEvaluatingSolution ? null : () => _evaluateSolutionWithAI(q),
                ),
              ],
            ),

            // AI Evaluation Result Card
            if (_evaluationResult != null) ...[
              const SizedBox(height: 18),
              _buildEvaluationFeedbackCard(_evaluationResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationFeedbackCard(SolutionEvaluationResult result) {
    Color scoreColor = Colors.green;
    if (result.scoreOutOfTen < 4) {
      scoreColor = Colors.red;
    } else if (result.scoreOutOfTen < 7.5) {
      scoreColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scoreColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Score: ${result.scoreOutOfTen.toStringAsFixed(1)} / 10',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                result.correctnessSummary,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: scoreColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Status: ${result.resultingStatus.label}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Correct Concepts
          if (result.coveredConcepts.isNotEmpty) ...[
            const Text('Concepts Correctly Applied:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: result.coveredConcepts.map((c) => Chip(
                backgroundColor: Colors.green.shade50,
                avatar: const Icon(Icons.check, size: 14, color: Colors.green),
                label: Text(c, style: TextStyle(fontSize: 11, color: Colors.green.shade900)),
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Missing Concepts
          if (result.missingConcepts.isNotEmpty) ...[
            const Text('Missing Steps / Potential Gaps:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: result.missingConcepts.map((c) => Chip(
                backgroundColor: Colors.amber.shade50,
                avatar: const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                label: Text(c, style: TextStyle(fontSize: 11, color: Colors.orange.shade900)),
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Guidance
          Text(
            result.constructiveFeedback,
            style: const TextStyle(fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildVariationsSection(QuestionModel q) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text(
                  'AI Targeted Practice & Concept Variations',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Generate new non-duplicate questions based on this question\'s concepts to reinforce mastery:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            if (_isGeneratingVariation) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    label: const Text('Similar Question'),
                    onPressed: () => _generateVariation(q, VariationType.similar),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.trending_down_rounded, size: 16),
                    label: const Text('Make Easier'),
                    onPressed: () => _generateVariation(q, VariationType.easier),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.trending_up_rounded, size: 16),
                    label: const Text('Make Harder'),
                    onPressed: () => _generateVariation(q, VariationType.harder),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.schema_rounded, size: 16),
                    label: const Text('Diagram Problem'),
                    onPressed: () => _generateVariation(q, VariationType.diagram),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calculate_rounded, size: 16),
                    label: const Text('Numerical Problem'),
                    onPressed: () => _generateVariation(q, VariationType.numerical),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(QuestionModel q) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note_alt_rounded, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text(
                  'My Personal Notes & Mnemonics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add personal study tips, tricky points, or memory hooks for this question...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Save Notes'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(questionsRepositoryProvider).updateUserNotes(q.questionId, _notesCtrl.text);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Notes saved successfully!')),
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
