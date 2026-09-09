import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/providers.dart';
import '../../../core/widgets/sketch_drawing_dialog.dart';
import '../../../data/models/question_model.dart';

class ManualQuestionDialog extends ConsumerStatefulWidget {
  const ManualQuestionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ManualQuestionDialog(),
    );
  }

  @override
  ConsumerState<ManualQuestionDialog> createState() => _ManualQuestionDialogState();
}

class _ManualQuestionDialogState extends ConsumerState<ManualQuestionDialog> {
  final _textCtrl = TextEditingController();
  final _topicCtrl = TextEditingController(text: 'General Engineering Concepts');
  final _numericalAnsCtrl = TextEditingController();
  final _conceptualAnsCtrl = TextEditingController();
  final _solutionTextCtrl = TextEditingController();

  // Dynamic options for MCQ / Multiple Correct
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(text: ''),
    TextEditingController(text: ''),
    TextEditingController(text: ''),
    TextEditingController(text: ''),
  ];
  int _selectedMcqIndex = 0;
  final Set<int> _selectedMultiIndices = {};
  bool _trueFalseValue = true;

  // Metadata
  String _subject = 'Network Theory';
  Difficulty _difficulty = Difficulty.medium;
  QuestionType _questionType = QuestionType.mcq;

  // Question Diagram / Picture Attachment
  DiagramType _diagramType = DiagramType.none;
  String? _diagramImageBase64;
  String? _diagramFileName;

  // Solution Completed Workflow
  bool _isSolutionCompleted = false;
  String? _solutionImageBase64;
  bool _isSaving = false;

  final List<String> _subjects = [
    'Network Theory',
    'Digital Electronics',
    'Signals & Systems',
    'Electronic Devices & Circuits',
    'Analog Circuits',
    'Control Systems',
    'Communications',
    'Electromagnetics',
    'Computer Science / Microprocessors',
    'General Engineering Mathematics',
    'ISRO Previous Year Questions (PYQs)',
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    _topicCtrl.dispose();
    _numericalAnsCtrl.dispose();
    _conceptualAnsCtrl.dispose();
    _solutionTextCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionCtrls.length < 6) {
      setState(() {
        _optionCtrls.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionCtrls.length > 2) {
      setState(() {
        _optionCtrls[index].dispose();
        _optionCtrls.removeAt(index);
        if (_selectedMcqIndex >= _optionCtrls.length) {
          _selectedMcqIndex = _optionCtrls.length - 1;
        }
        _selectedMultiIndices.remove(index);
      });
    }
  }

  // --- Picture / Diagram Pickers ---
  Future<void> _pickQuestionImage() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        setState(() {
          _diagramImageBase64 = base64Encode(bytes);
          _diagramFileName = file.name;
          _diagramType = DiagramType.customImage;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick diagram image: $e')),
        );
      }
    }
  }

  Future<void> _drawQuestionSketch() async {
    final sketchBase64 = await SketchDrawingDialog.show(
      context,
      title: 'Draw Question Diagram / Circuit',
    );
    if (sketchBase64 != null) {
      setState(() {
        _diagramImageBase64 = sketchBase64;
        _diagramFileName = 'Hand-drawn Diagram';
        _diagramType = DiagramType.customImage;
      });
    }
  }

  // --- Solving Photo Pickers ---
  Future<void> _pickSolutionPhoto() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        setState(() {
          _solutionImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick solving photo: $e')),
        );
      }
    }
  }

  Future<void> _drawSolutionSketch() async {
    final sketchBase64 = await SketchDrawingDialog.show(
      context,
      title: 'Draw Solution / Derivation Work',
    );
    if (sketchBase64 != null) {
      setState(() {
        _solutionImageBase64 = sketchBase64;
      });
    }
  }

  // --- Form Validation & Submission ---
  Future<void> _saveQuestion() async {
    final questionText = _textCtrl.text.trim();
    if (questionText.isEmpty && _diagramImageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter question text or upload a question picture.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    List<String> finalOptions = [];
    String finalCorrectAnswer = '';

    // Handle different question types dynamically
    switch (_questionType) {
      case QuestionType.mcq:
        final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
        finalOptions = [];
        for (int i = 0; i < _optionCtrls.length; i++) {
          final optText = _optionCtrls[i].text.trim();
          final label = labels[i];
          finalOptions.add('$label. ${optText.isNotEmpty ? optText : "Option $label"}');
        }
        if (_isSolutionCompleted) {
          finalCorrectAnswer = labels[_selectedMcqIndex];
        }
        break;

      case QuestionType.multipleCorrect:
        final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
        finalOptions = [];
        final List<String> correctKeys = [];
        for (int i = 0; i < _optionCtrls.length; i++) {
          final optText = _optionCtrls[i].text.trim();
          final label = labels[i];
          finalOptions.add('$label. ${optText.isNotEmpty ? optText : "Option $label"}');
          if (_selectedMultiIndices.contains(i)) {
            correctKeys.add(label);
          }
        }
        if (_isSolutionCompleted) {
          finalCorrectAnswer = correctKeys.join(', ');
        }
        break;

      case QuestionType.trueFalse:
        finalOptions = ['True', 'False'];
        if (_isSolutionCompleted) {
          finalCorrectAnswer = _trueFalseValue ? 'True' : 'False';
        }
        break;

      case QuestionType.numerical:
        finalOptions = const [];
        if (_isSolutionCompleted) {
          finalCorrectAnswer = _numericalAnsCtrl.text.trim();
        }
        break;

      case QuestionType.conceptual:
      case QuestionType.shortAnswer:
      case QuestionType.longAnswer:
      case QuestionType.formulaBased:
      case QuestionType.calculationBased:
      case QuestionType.diagramBased:
      case QuestionType.matchFollowing:
      case QuestionType.assertionReason:
      case QuestionType.coding:
      case QuestionType.debugging:
      case QuestionType.fillInBlank:
        finalOptions = const [];
        if (_isSolutionCompleted) {
          finalCorrectAnswer = _conceptualAnsCtrl.text.trim();
        }
        break;
    }

    final userId = ref.read(authRepositoryProvider).currentUser?.id ?? 'user';

    final newQuestion = QuestionModel(
      questionId: 'q_${const Uuid().v4()}',
      userId: userId,
      questionText: questionText.isNotEmpty ? questionText : 'Refer to attached diagram.',
      options: finalOptions,
      correctAnswer: _isSolutionCompleted ? (finalCorrectAnswer.isNotEmpty ? finalCorrectAnswer : 'Answer verified') : '',
      solution: _isSolutionCompleted
          ? (_solutionTextCtrl.text.trim().isNotEmpty
              ? _solutionTextCtrl.text.trim()
              : (_solutionImageBase64 != null ? 'Solution attached in solving photo.' : 'Solution completed.'))
          : '',
      subject: _subject,
      topic: _topicCtrl.text.trim().isNotEmpty ? _topicCtrl.text.trim() : 'General',
      difficulty: _difficulty,
      questionType: _diagramImageBase64 != null ? QuestionType.diagramBased : _questionType,
      status: _isSolutionCompleted ? QuestionStatus.solved : QuestionStatus.unsolved,
      verificationStatus: _isSolutionCompleted ? VerificationStatus.sourceVerified : VerificationStatus.unknown,
      diagramType: _diagramType,
      diagramImageBase64: _diagramImageBase64,
      solutionImageBase64: _isSolutionCompleted ? _solutionImageBase64 : null,
      sourceId: 'manual',
      sourceName: 'Created by User',
      sourceLocation: 'Personal Question Bank',
      createdAt: DateTime.now(),
    );

    await ref.read(questionsRepositoryProvider).addQuestion(newQuestion);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSolutionCompleted
              ? 'Question added with solution successfully!'
              : 'Question added (marked as Unsolved - solve anytime)!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.post_add_rounded, color: Color(0xFF1E3A8A)),
          SizedBox(width: 10),
          Text('Create Question Manually', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ],
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject and Topic Row
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: DropdownButtonFormField<String>(
                      value: _subject,
                      decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder(), isDense: true),
                      items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _subject = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _topicCtrl,
                      decoration: const InputDecoration(labelText: 'Topic / Chapter', border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Difficulty & Question Type Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Difficulty>(
                      value: _difficulty,
                      decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder(), isDense: true),
                      items: Difficulty.values.map((d) => DropdownMenuItem(value: d, child: Text(d.label))).toList(),
                      onChanged: (v) => setState(() => _difficulty = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<QuestionType>(
                      value: _questionType,
                      decoration: const InputDecoration(labelText: 'Question Type', border: OutlineInputBorder(), isDense: true),
                      items: [
                        QuestionType.mcq,
                        QuestionType.multipleCorrect,
                        QuestionType.trueFalse,
                        QuestionType.numerical,
                        QuestionType.conceptual,
                        QuestionType.shortAnswer,
                        QuestionType.longAnswer,
                        QuestionType.formulaBased,
                        QuestionType.diagramBased,
                      ].map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _questionType = v!;
                          if (v == QuestionType.diagramBased && _diagramType == DiagramType.none) {
                            _diagramType = DiagramType.customImage;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Question Text
              TextField(
                controller: _textCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: r'Question Prompt (Supports LaTeX formulas e.g. $f = \frac{1}{2\pi\sqrt{LC}}$)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              // Question Picture / Diagram Section
              _buildDiagramAttachmentSection(),
              const SizedBox(height: 14),

              // Dynamic Question Type Input (Options or Numerical or True/False)
              _buildDynamicQuestionTypeSection(),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Solution Completed Section
              _buildSolutionSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          ),
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline_rounded, size: 18),
          label: const Text('Save to Question Bank'),
          onPressed: _isSaving ? null : _saveQuestion,
        ),
      ],
    );
  }

  // --- Dynamic Question Type Inputs ---
  Widget _buildDynamicQuestionTypeSection() {
    switch (_questionType) {
      case QuestionType.mcq:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Options & Correct Answer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (_optionCtrls.length < 6)
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Option', style: TextStyle(fontSize: 12)),
                    onPressed: _addOption,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ...List.generate(_optionCtrls.length, (i) {
              final label = String.fromCharCode(65 + i);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: _selectedMcqIndex,
                      onChanged: (v) => setState(() => _selectedMcqIndex = v!),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _optionCtrls[i],
                        decoration: InputDecoration(
                          labelText: 'Option $label',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_optionCtrls.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                        tooltip: 'Remove Option',
                        onPressed: () => _removeOption(i),
                      ),
                  ],
                ),
              );
            }),
            Text(
              '💡 Select the radio button corresponding to the correct answer choice.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        );

      case QuestionType.multipleCorrect:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Options (Select All Correct):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (_optionCtrls.length < 6)
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Option', style: TextStyle(fontSize: 12)),
                    onPressed: _addOption,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ...List.generate(_optionCtrls.length, (i) {
              final label = String.fromCharCode(65 + i);
              final isChecked = _selectedMultiIndices.contains(i);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: isChecked,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedMultiIndices.add(i);
                          } else {
                            _selectedMultiIndices.remove(i);
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _optionCtrls[i],
                        decoration: InputDecoration(
                          labelText: 'Option $label',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_optionCtrls.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                        onPressed: () => _removeOption(i),
                      ),
                  ],
                ),
              );
            }),
          ],
        );

      case QuestionType.trueFalse:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Correct Statement Value:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('True', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: true,
                    groupValue: _trueFalseValue,
                    onChanged: (v) => setState(() => _trueFalseValue = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('False', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: false,
                    groupValue: _trueFalseValue,
                    onChanged: (v) => setState(() => _trueFalseValue = v!),
                  ),
                ),
              ],
            ),
          ],
        );

      case QuestionType.numerical:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Numerical Answer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _numericalAnsCtrl,
              decoration: const InputDecoration(
                labelText: 'Numerical Value (e.g. 15.5, 3.3V, 20 mA)',
                prefixIcon: Icon(Icons.numbers_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        );

      case QuestionType.conceptual:
      case QuestionType.shortAnswer:
      case QuestionType.longAnswer:
      case QuestionType.formulaBased:
      case QuestionType.calculationBased:
      case QuestionType.diagramBased:
      case QuestionType.matchFollowing:
      case QuestionType.assertionReason:
      case QuestionType.coding:
      case QuestionType.debugging:
      case QuestionType.fillInBlank:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Answer Key / Key Concept:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _conceptualAnsCtrl,
              decoration: const InputDecoration(
                labelText: 'Key Concept / Expected Conclusion',
                prefixIcon: Icon(Icons.key_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        );
    }
  }

  // --- Diagram & Picture Attachment ---
  Widget _buildDiagramAttachmentSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_rounded, size: 18, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              const Text('Question Picture / Diagram Attachment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              if (_diagramImageBase64 != null)
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                  label: const Text('Remove Picture', style: TextStyle(color: Colors.red, fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      _diagramImageBase64 = null;
                      _diagramFileName = null;
                      _diagramType = DiagramType.none;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_diagramImageBase64 != null) ...[
            Center(
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(_diagramImageBase64!),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Text('Invalid image')),
                  ),
                ),
              ),
            ),
            if (_diagramFileName != null) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Attached: $_diagramFileName',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Upload Picture / Paint File', style: TextStyle(fontSize: 12)),
                    onPressed: _pickQuestionImage,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.brush_rounded, size: 18),
                    label: const Text('Draw / Sketch Diagram', style: TextStyle(fontSize: 12)),
                    onPressed: _drawQuestionSketch,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- Solution Completed Workflow Section ---
  Widget _buildSolutionSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isSolutionCompleted ? Colors.green.withOpacity(0.04) : Colors.grey.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isSolutionCompleted ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isSolutionCompleted ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                color: _isSolutionCompleted ? Colors.green : Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Is the Solution Completed?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Yes, Solved')),
                  ButtonSegment(value: false, label: Text('No, Solve Later')),
                ],
                selected: {_isSolutionCompleted},
                onSelectionChanged: (set) => setState(() => _isSolutionCompleted = set.first),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isSolutionCompleted) ...[
            // Solution Text Field
            TextField(
              controller: _solutionTextCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: r'Detailed Solution / Derivation (Supports LaTeX formulas e.g. $Z_{in} = R + j\omega L$)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Handwritten Solving Photo / Sketch Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Solving Photo / Handwritten Work:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (_solutionImageBase64 != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 14),
                    label: const Text('Remove Photo', style: TextStyle(color: Colors.red, fontSize: 11)),
                    onPressed: () => setState(() => _solutionImageBase64 = null),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            if (_solutionImageBase64 != null) ...[
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(_solutionImageBase64!),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Text('Invalid image')),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                      label: const Text('Upload Solving Photo', style: TextStyle(fontSize: 12)),
                      onPressed: _pickSolutionPhoto,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.draw_rounded, size: 16),
                      label: const Text('Draw Solution Steps', style: TextStyle(fontSize: 12)),
                      onPressed: _drawSolutionSketch,
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber.shade900, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This question will be saved as UNSOLVED. You can solve it later and upload your handwritten solving photo and answer whenever you want.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

