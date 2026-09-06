import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/providers.dart';
import '../../../data/models/question_model.dart';

/// Mandatory OCR & Vision Verification Modal.
/// Never trusts OCR automatically. Presents extracted question, options,
/// solution, difficulty, and source metadata for User Edit / Approval / Rejection.
class OCRVerificationDialog extends ConsumerStatefulWidget {
  final String fileName;
  final String initialQuestionText;
  final List<String> initialOptions;
  final String initialCorrectAnswer;
  final String initialSolution;
  final String initialSubject;
  final String initialTopic;
  final Difficulty initialDifficulty;

  const OCRVerificationDialog({
    super.key,
    required this.fileName,
    required this.initialQuestionText,
    required this.initialOptions,
    required this.initialCorrectAnswer,
    required this.initialSolution,
    this.initialSubject = 'Network Theory',
    this.initialTopic = 'Network Analysis',
    this.initialDifficulty = Difficulty.medium,
  });

  @override
  ConsumerState<OCRVerificationDialog> createState() => _OCRVerificationDialogState();
}

class _OCRVerificationDialogState extends ConsumerState<OCRVerificationDialog> {
  late TextEditingController _qTextCtrl;
  late TextEditingController _optACtrl;
  late TextEditingController _optBCtrl;
  late TextEditingController _optCCtrl;
  late TextEditingController _optDCtrl;
  late TextEditingController _answerCtrl;
  late TextEditingController _solutionCtrl;
  late TextEditingController _subjectCtrl;
  late TextEditingController _topicCtrl;
  late Difficulty _difficulty;

  @override
  void initState() {
    super.initState();
    _qTextCtrl = TextEditingController(text: widget.initialQuestionText);
    _optACtrl = TextEditingController(text: widget.initialOptions.isNotEmpty ? widget.initialOptions[0] : '');
    _optBCtrl = TextEditingController(text: widget.initialOptions.length > 1 ? widget.initialOptions[1] : '');
    _optCCtrl = TextEditingController(text: widget.initialOptions.length > 2 ? widget.initialOptions[2] : '');
    _optDCtrl = TextEditingController(text: widget.initialOptions.length > 3 ? widget.initialOptions[3] : '');
    _answerCtrl = TextEditingController(text: widget.initialCorrectAnswer);
    _solutionCtrl = TextEditingController(text: widget.initialSolution);
    _subjectCtrl = TextEditingController(text: widget.initialSubject);
    _topicCtrl = TextEditingController(text: widget.initialTopic);
    _difficulty = widget.initialDifficulty;
  }

  @override
  void dispose() {
    _qTextCtrl.dispose();
    _optACtrl.dispose();
    _optBCtrl.dispose();
    _optCCtrl.dispose();
    _optDCtrl.dispose();
    _answerCtrl.dispose();
    _solutionCtrl.dispose();
    _subjectCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  void _handleApprove() {
    final user = ref.read(authRepositoryProvider).currentUser;
    final options = [
      _optACtrl.text.trim(),
      _optBCtrl.text.trim(),
      _optCCtrl.text.trim(),
      _optDCtrl.text.trim(),
    ].where((o) => o.isNotEmpty).toList();

    final approvedQuestion = QuestionModel(
      questionId: const Uuid().v4(),
      userId: user?.id ?? '',
      questionText: _qTextCtrl.text.trim(),
      options: options,
      correctAnswer: _answerCtrl.text.trim(),
      solution: _solutionCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      topic: _topicCtrl.text.trim(),
      difficulty: _difficulty,
      sourceId: 'ocr_${widget.fileName}',
      sourceName: widget.fileName,
      sourceLocation: 'Image OCR Extraction',
      sourceChunk: _qTextCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    ref.read(questionsRepositoryProvider).addQuestion(approvedQuestion);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Warning header
            Row(
              children: [
                const Icon(Icons.visibility_rounded, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'OCR & VISION VERIFICATION',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Review Before Saving',
                    style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Extracted from: ${widget.fileName}. Please review equation text, options, and topic classification before saving into your Question Bank.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Divider(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _qTextCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Extracted Question Text (LaTeX supported)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Extracted Options:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _optACtrl,
                            decoration: const InputDecoration(labelText: 'Option A'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _optBCtrl,
                            decoration: const InputDecoration(labelText: 'Option B'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _optCCtrl,
                            decoration: const InputDecoration(labelText: 'Option C'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _optDCtrl,
                            decoration: const InputDecoration(labelText: 'Option D'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _answerCtrl,
                            decoration: const InputDecoration(labelText: 'Correct Answer (e.g. A or Value)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<Difficulty>(
                            initialValue: _difficulty,
                            decoration: const InputDecoration(labelText: 'Difficulty'),
                            items: Difficulty.values.map((d) {
                              return DropdownMenuItem(value: d, child: Text(d.label));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _difficulty = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subjectCtrl,
                            decoration: const InputDecoration(labelText: 'Subject Classification'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _topicCtrl,
                            decoration: const InputDecoration(labelText: 'Topic Classification'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _solutionCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Source-Grounded Solution / Explanation',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons: Reject, Edit/Save, Approve
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Reject Question', style: TextStyle(color: Colors.red)),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Approve & Save to Question Bank'),
                  onPressed: _handleApprove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

