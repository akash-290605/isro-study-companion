import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/math_renderer.dart';
import '../../../core/widgets/sketch_drawing_dialog.dart';
import '../../../data/models/question_model.dart';

class EditSolutionDialog extends ConsumerStatefulWidget {
  final QuestionModel question;

  const EditSolutionDialog({
    super.key,
    required this.question,
  });

  static Future<void> show(BuildContext context, QuestionModel question) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditSolutionDialog(question: question),
    );
  }

  @override
  ConsumerState<EditSolutionDialog> createState() => _EditSolutionDialogState();
}

class _EditSolutionDialogState extends ConsumerState<EditSolutionDialog> {
  late final TextEditingController _answerCtrl;
  late final TextEditingController _solutionCtrl;
  String? _solutionImageBase64;
  bool _markAsSolved = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _answerCtrl = TextEditingController(text: widget.question.correctAnswer == 'ANSWER UNKNOWN' ? '' : widget.question.correctAnswer);
    _solutionCtrl = TextEditingController(text: widget.question.solution);
    _solutionImageBase64 = widget.question.solutionImageBase64;
    _markAsSolved = true;
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    _solutionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImageFile() async {
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
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _drawSketch() async {
    final sketchBase64 = await SketchDrawingDialog.show(
      context,
      title: 'Draw Handwritten Solution / Derivation',
    );
    if (sketchBase64 != null) {
      setState(() {
        _solutionImageBase64 = sketchBase64;
      });
    }
  }

  Future<void> _saveSolution() async {
    final ans = _answerCtrl.text.trim();
    final sol = _solutionCtrl.text.trim();

    if (ans.isEmpty && sol.isEmpty && _solutionImageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an answer, explanation, or upload solving photo.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    await ref.read(questionsRepositoryProvider).updateQuestionSolution(
      widget.question.questionId,
      correctAnswer: ans.isNotEmpty ? ans : widget.question.correctAnswer,
      solution: sol.isNotEmpty ? sol : (widget.question.solution.isNotEmpty ? widget.question.solution : 'Solution provided with solving photo.'),
      solutionImageBase64: _solutionImageBase64,
      markAsSolved: _markAsSolved,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_markAsSolved ? 'Solution updated & marked as Solved!' : 'Solution saved.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          Icon(
            widget.question.solution.isEmpty ? Icons.add_task_rounded : Icons.edit_note_rounded,
            color: const Color(0xFF1E3A8A),
          ),
          const SizedBox(width: 8),
          Text(
            widget.question.solution.isEmpty ? 'Upload & Complete Solution' : 'Edit Solution & Derivation',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question snippet banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.question.subject} • ${widget.question.topic}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    MathFormulaView(
                      formula: widget.question.questionText,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Correct Answer input
              TextField(
                controller: _answerCtrl,
                decoration: InputDecoration(
                  labelText: 'Correct Answer / Key',
                  hintText: widget.question.options.isNotEmpty
                      ? 'e.g. A, B, C, or D'
                      : (widget.question.questionType == QuestionType.numerical ? 'e.g. 15.5 kHz' : 'e.g. True / Formula'),
                  prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              // Detailed solution text
              TextField(
                controller: _solutionCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: r'Detailed Solution & Derivation Steps (Supports LaTeX e.g. $V_o = -R_f/R_1 \cdot V_i$)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Solving Photo / Handwritten Work Attachment
              const Text(
                'Solving Photo / Handwritten Work:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),

              if (_solutionImageBase64 != null) ...[
                // Image preview with delete button
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(_solutionImageBase64!),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Text('Invalid image format'),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.red.withOpacity(0.85),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setState(() => _solutionImageBase64 = null),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(Icons.delete_outline, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else ...[
                // Buttons to upload image or draw
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                        label: const Text('Upload Photo / Paint File', style: TextStyle(fontSize: 12)),
                        onPressed: _pickImageFile,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.draw_rounded, size: 18),
                        label: const Text('Draw / Sketch Solution', style: TextStyle(fontSize: 12)),
                        onPressed: _drawSketch,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Mark as Solved toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mark question status as "SOLVED"', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Updates progress metrics & test readiness', style: TextStyle(fontSize: 11)),
                value: _markAsSolved,
                activeColor: Colors.green,
                onChanged: (v) => setState(() => _markAsSolved = v),
              ),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save Solution'),
          onPressed: _isSaving ? null : _saveSolution,
        ),
      ],
    );
  }
}

