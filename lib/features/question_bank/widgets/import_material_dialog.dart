import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/providers.dart';
import '../../../core/utils/math_renderer.dart';
import '../../../data/datasources/ai_question_extractor_service.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/source_model.dart';

class ImportMaterialDialog extends ConsumerStatefulWidget {
  const ImportMaterialDialog({super.key});

  @override
  ConsumerState<ImportMaterialDialog> createState() => _ImportMaterialDialogState();
}

enum _ImportStep {
  selectSource,
  processing,
  duplicateResolution,
  reviewQuestions,
  completed,
}

enum _DuplicateStrategy {
  skip,
  replace,
  keepBoth,
}

class _ImportMaterialDialogState extends ConsumerState<ImportMaterialDialog> {
  _ImportStep _currentStep = _ImportStep.selectSource;
  String _selectedFormat = 'PDF';
  String? _pickedFileName;
  Uint8List? _pickedBytes;
  String? _rawContent;

  final TextEditingController _textInputCtrl = TextEditingController();
  final TextEditingController _subjectCtrl = TextEditingController(text: 'Network Theory');
  final TextEditingController _topicCtrl = TextEditingController(text: 'RLC Circuits & Resonance');

  // Processing state
  String _processingStage = 'Initializing AI Engine...';
  double _processingProgress = 0.1;

  // Extracted questions & duplicates
  List<QuestionModel> _extractedQuestions = [];
  List<DuplicateComparison> _duplicates = [];
  _DuplicateStrategy _duplicateStrategy = _DuplicateStrategy.skip;
  final Set<String> _selectedQuestionIds = {};

  final List<String> _formatOptions = [
    'PDF',
    'Word (.doc/.docx)',
    'PowerPoint (.ppt/.pptx)',
    'Images / Photos',
    'Camera / Take Photo',
    'Direct Text / Paste Paper',
  ];

  final List<String> _subjects = [
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

  @override
  void dispose() {
    _textInputCtrl.dispose();
    _subjectCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      List<String>? allowedExtensions;
      FileType fileType = FileType.any;

      if (_selectedFormat == 'PDF') {
        fileType = FileType.custom;
        allowedExtensions = ['pdf'];
      } else if (_selectedFormat.contains('Word')) {
        fileType = FileType.custom;
        allowedExtensions = ['doc', 'docx', 'txt'];
      } else if (_selectedFormat.contains('PowerPoint')) {
        fileType = FileType.custom;
        allowedExtensions = ['ppt', 'pptx'];
      } else if (_selectedFormat.contains('Images') || _selectedFormat.contains('Camera')) {
        fileType = FileType.custom;
        allowedExtensions = ['png', 'jpg', 'jpeg', 'webp', 'bmp'];
      }

      final files = await FilePicker.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedFileName = file.name;
          _pickedBytes = bytes;
          if (_selectedFormat.contains('Images') || _selectedFormat.contains('Camera')) {
            _rawContent = base64Encode(bytes);
          } else if (file.name.toLowerCase().endsWith('.txt') || _selectedFormat == 'Direct Text / Paste Paper') {
            try {
              _rawContent = utf8.decode(bytes, allowMalformed: true);
            } catch (_) {
              _rawContent = null;
            }
          } else {
            // For binary documents (PDF, DOCX, PPTX), leave _rawContent null so DocumentTextExtractor extracts it asynchronously without blocking UI
            _rawContent = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  Future<void> _startAiExtraction() async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id ?? 'user';
    final existingQuestions = ref.read(questionsRepositoryProvider).questions;

    setState(() {
      _currentStep = _ImportStep.processing;
      _processingStage = '1/5 Reading document & parsing layout...';
      _processingProgress = 0.2;
    });

    final summary = await AIQuestionExtractorService.extractQuestionsFromMaterial(
      fileName: _pickedFileName ?? 'Study_Material_${DateTime.now().millisecondsSinceEpoch}',
      fileType: _selectedFormat,
      fileBytes: _pickedBytes,
      rawText: _selectedFormat == 'Direct Text / Paste Paper' ? _textInputCtrl.text : _rawContent,
      currentUserId: userId,
      existingQuestionBank: existingQuestions,
      onProgress: (stage, progress) {
        if (mounted) {
          setState(() {
            _processingStage = stage;
            _processingProgress = progress;
          });
        }
      },
    );

    final duplicates = AIQuestionExtractorService.findDuplicates(
      summary.extractedQuestions,
      existingQuestions,
    );

    _extractedQuestions = summary.extractedQuestions;
    _duplicates = duplicates;
    _selectedQuestionIds.clear();
    for (final q in _extractedQuestions) {
      _selectedQuestionIds.add(q.questionId);
    }

    if (mounted) {
      setState(() {
        if (_duplicates.isNotEmpty) {
          _currentStep = _ImportStep.duplicateResolution;
        } else {
          _currentStep = _ImportStep.reviewQuestions;
        }
      });
    }
  }

  void _applyDuplicateStrategy() {
    final existingRepo = ref.read(questionsRepositoryProvider);
    final Set<String> idsToRemove = {};

    if (_duplicateStrategy == _DuplicateStrategy.skip) {
      // Remove duplicated extracted questions from import list
      for (final dup in _duplicates) {
        idsToRemove.add(dup.newQuestion.questionId);
      }
      _extractedQuestions.removeWhere((q) => idsToRemove.contains(q.questionId));
      _selectedQuestionIds.removeWhere((id) => idsToRemove.contains(id));
    } else if (_duplicateStrategy == _DuplicateStrategy.replace) {
      // Replace existing in repo
      for (final dup in _duplicates) {
        existingRepo.deleteQuestion(dup.existingQuestion.questionId);
      }
    }
    // keepBoth leaves everything as is

    setState(() {
      _currentStep = _ImportStep.reviewQuestions;
    });
  }

  Future<void> _commitQuestionsToBank() async {
    final questionsToSave = _extractedQuestions
        .where((q) => _selectedQuestionIds.contains(q.questionId))
        .toList();

    if (questionsToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one question to import.')),
      );
      return;
    }

    final qRepo = ref.read(questionsRepositoryProvider);
    await qRepo.addQuestions(questionsToSave);

    // Also register source in SourcesRepository
    final srcRepo = ref.read(sourcesRepositoryProvider);
    final sourceId = questionsToSave.first.sourceId;
    final sourceName = questionsToSave.first.sourceName;
    final userId = ref.read(authRepositoryProvider).currentUser?.id ?? 'user';

    await srcRepo.addSource(
      SourceDocumentModel(
        sourceId: sourceId,
        userId: userId,
        sourceType: _selectedFormat == 'PDF'
            ? SourceType.pdf
            : (_selectedFormat.contains('Image') || _selectedFormat.contains('Camera')
                ? SourceType.questionImage
                : SourceType.document),
        sourceName: sourceName,
        subject: _subjectCtrl.text.trim().isNotEmpty ? _subjectCtrl.text.trim() : 'General',
        topic: _topicCtrl.text.trim().isNotEmpty ? _topicCtrl.text.trim() : 'Mixed Topics',
        uploadedAt: DateTime.now(),
        processedStatus: ProcessedStatus.processed,
        pageCount: 1,
        rawText: 'Imported via Question Bank Material Extractor (${questionsToSave.length} questions extracted)',
      ),
    );

    if (mounted) {
      setState(() {
        _currentStep = _ImportStep.completed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 860,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1E3A8A), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Material Import & Question Extractor',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        'Supports PDF, Word, PowerPoint, Images, Camera photos & Text papers',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Step Content
            Expanded(child: _buildCurrentStepView()),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case _ImportStep.selectSource:
        return _buildSelectSourceView();
      case _ImportStep.processing:
        return _buildProcessingView();
      case _ImportStep.duplicateResolution:
        return _buildDuplicateResolutionView();
      case _ImportStep.reviewQuestions:
        return _buildReviewQuestionsView();
      case _ImportStep.completed:
        return _buildCompletedView();
    }
  }

  Widget _buildSelectSourceView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. Choose Material Format',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _formatOptions.map((fmt) {
              final isSelected = _selectedFormat == fmt;
              return ChoiceChip(
                label: Text(fmt),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedFormat = fmt;
                      _pickedFileName = null;
                      _pickedBytes = null;
                      _rawContent = null;
                    });
                  }
                },
                selectedColor: const Color(0xFF1E3A8A).withOpacity(0.15),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // File / Input Picker Area
          if (_selectedFormat == 'Direct Text / Paste Paper') ...[
            const Text(
              '2. Paste Question Paper / Text Content',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textInputCtrl,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: 'Paste questions, options, equations, and answer keys here...\n'
                    'Example:\nQ1. For an RLC circuit at resonance, the power factor is:\n'
                    '(A) 0\n(B) 0.5 leading\n(C) 1.0\n(D) 0.5 lagging\nAnswer: C\nSolution: At resonance, inductive and capacitive reactance cancel out.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ] else ...[
            const Text(
              '2. Select or Capture File',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.withOpacity(0.04),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFormat.contains('Image') || _selectedFormat.contains('Camera')
                        ? Icons.add_a_photo_outlined
                        : Icons.cloud_upload_outlined,
                    size: 48,
                    color: const Color(0xFF1E3A8A),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _pickedFileName ?? 'No file selected yet',
                    style: TextStyle(
                      fontWeight: _pickedFileName != null ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                      color: _pickedFileName != null ? Colors.green.shade800 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: Icon(
                      _selectedFormat.contains('Camera')
                          ? Icons.camera_alt_rounded
                          : Icons.folder_open_rounded,
                    ),
                    label: Text(
                      _selectedFormat.contains('Camera')
                          ? 'Take / Select Photo'
                          : 'Browse File',
                    ),
                    onPressed: _pickFile,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Metadata Selection
          const Text(
            '3. Default Subject & Topic Classification',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _subjects.contains(_subjectCtrl.text) ? _subjectCtrl.text : _subjects.first,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _subjectCtrl.text = v);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _topicCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Topic / Chapter',
                    hintText: 'e.g. RLC Resonance, Op-Amps',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Start AI Extraction & Analysis'),
              onPressed: () {
                if (_selectedFormat == 'Direct Text / Paste Paper') {
                  if (_textInputCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please paste some question text to analyze.')),
                    );
                    return;
                  }
                } else if (_pickedFileName == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a file first.')),
                  );
                  return;
                }
                _startAiExtraction();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: _processingProgress,
              strokeWidth: 6,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Extracting Questions with Gemini Vision & OCR',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            _processingStage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Parsing formulas, LaTeX expressions, logic gate symbols & waveforms...',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateResolutionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(
              '${_duplicates.length} Duplicate / Similar Question(s) Detected',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'These questions closely match ones already in your Question Bank. Choose how to handle them:',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),

        // Strategy radio options
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<_DuplicateStrategy>(
                    title: const Text('Skip Duplicates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Do not import duplicate items', style: TextStyle(fontSize: 11)),
                    value: _DuplicateStrategy.skip,
                    groupValue: _duplicateStrategy,
                    onChanged: (v) => setState(() => _duplicateStrategy = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<_DuplicateStrategy>(
                    title: const Text('Replace Existing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Overwrite old version with new', style: TextStyle(fontSize: 11)),
                    value: _DuplicateStrategy.replace,
                    groupValue: _duplicateStrategy,
                    onChanged: (v) => setState(() => _duplicateStrategy = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<_DuplicateStrategy>(
                    title: const Text('Keep Both', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Save as separate questions', style: TextStyle(fontSize: 11)),
                    value: _DuplicateStrategy.keepBoth,
                    groupValue: _duplicateStrategy,
                    onChanged: (v) => setState(() => _duplicateStrategy = v!),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Duplicates preview list
        Expanded(
          child: ListView.builder(
            itemCount: _duplicates.length,
            itemBuilder: (ctx, i) {
              final dup = _duplicates[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${(dup.similarityScore * 100).toInt()}% Match',
                              style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Subject: ${dup.newQuestion.subject}', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('New: ${dup.newQuestion.questionText}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Existing: ${dup.existingQuestion.questionText}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: _applyDuplicateStrategy,
            child: const Text('Continue to Review Questions'),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewQuestionsView() {
    final confirmedAnsCount = _extractedQuestions.where((q) => q.correctAnswer.isNotEmpty && q.correctAnswer != 'ANSWER UNKNOWN').length;
    final diagramCount = _extractedQuestions.where((q) => q.diagramType != DiagramType.none).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Extraction summary pills
        Row(
          children: [
            _buildStatBadge('Detected: ${_extractedQuestions.length}', Colors.blue),
            const SizedBox(width: 8),
            _buildStatBadge('Answers Found: $confirmedAnsCount', Colors.green),
            const SizedBox(width: 8),
            _buildStatBadge('Diagrams: $diagramCount', Colors.purple),
            const SizedBox(width: 8),
            _buildStatBadge('Selected: ${_selectedQuestionIds.length}', Colors.orange),
            const Spacer(),
            TextButton.icon(
              icon: Icon(
                _selectedQuestionIds.length == _extractedQuestions.length
                    ? Icons.deselect_rounded
                    : Icons.select_all_rounded,
                size: 16,
              ),
              label: Text(_selectedQuestionIds.length == _extractedQuestions.length ? 'Deselect All' : 'Select All'),
              onPressed: () {
                setState(() {
                  if (_selectedQuestionIds.length == _extractedQuestions.length) {
                    _selectedQuestionIds.clear();
                  } else {
                    _selectedQuestionIds.clear();
                    for (final q in _extractedQuestions) {
                      _selectedQuestionIds.add(q.questionId);
                    }
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Review extracted questions below. You can uncheck items or edit answers before saving to your Question Bank.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),

        // Questions List
        Expanded(
          child: ListView.builder(
            itemCount: _extractedQuestions.length,
            itemBuilder: (ctx, i) {
              final q = _extractedQuestions[i];
              final isChecked = _selectedQuestionIds.contains(q.questionId);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: isChecked ? const Color(0xFF1E3A8A).withOpacity(0.5) : Colors.grey.shade200,
                    width: isChecked ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isChecked,
                        activeColor: const Color(0xFF1E3A8A),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedQuestionIds.add(q.questionId);
                            } else {
                              _selectedQuestionIds.remove(q.questionId);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Q${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A))),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(q.questionType.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                                if (q.diagramType != DiagramType.none) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.schema_rounded, size: 12, color: Colors.purple),
                                        SizedBox(width: 4),
                                        Text('Diagram', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: q.correctAnswer.isNotEmpty && q.correctAnswer != 'ANSWER UNKNOWN'
                                        ? Colors.green.withOpacity(0.12)
                                        : Colors.orange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    q.correctAnswer.isNotEmpty && q.correctAnswer != 'ANSWER UNKNOWN'
                                        ? 'Ans: ${q.correctAnswer}'
                                        : 'Needs Verification',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: q.correctAnswer.isNotEmpty && q.correctAnswer != 'ANSWER UNKNOWN'
                                          ? Colors.green.shade800
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            MathFormulaView(
                              formula: q.questionText,
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            if (q.options.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: q.options.map((opt) {
                                  final isAnswer = opt.startsWith(q.correctAnswer) || opt.contains(q.correctAnswer);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isAnswer ? Colors.green.shade50 : Colors.grey.withOpacity(0.06),
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
                            ],
                            if (q.solution.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Solution: ${q.solution}',
                                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = _ImportStep.selectSource),
              child: const Text('Back to Import Options'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.save_rounded),
              label: Text('Save ${_selectedQuestionIds.length} Questions to Bank'),
              onPressed: _commitQuestionsToBank,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedView() {
    final count = _selectedQuestionIds.length;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 72),
          const SizedBox(height: 16),
          Text(
            '$count Questions Added Successfully!',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'All questions are categorized as UNSOLVED and ready for practice, AI test generation, or manual solving.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close & View Question Bank'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color.shade800, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
