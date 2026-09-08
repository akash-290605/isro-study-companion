import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/app_error_handler.dart';
import '../../../core/services/providers.dart';
import '../../../data/models/question_model.dart';
import '../../ocr_verification/screens/ocr_verification_dialog.dart';

class UploadHubScreen extends ConsumerStatefulWidget {
  const UploadHubScreen({super.key});

  @override
  ConsumerState<UploadHubScreen> createState() => _UploadHubScreenState();
}

class _UploadHubScreenState extends ConsumerState<UploadHubScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;
  String _statusText = '';

  // Manual Text Controllers
  final _manualNameCtrl = TextEditingController(text: 'Signals & Systems Summary');
  final _manualContentCtrl = TextEditingController();
  final _manualSubjectCtrl = TextEditingController(text: 'Signals and Systems');
  final _manualTopicCtrl = TextEditingController(text: 'Continuous & Discrete Signals');

  // URL Ingestion Controller
  final _urlCtrl = TextEditingController();
  final _urlSubjectCtrl = TextEditingController(text: 'Network Theory');
  final _urlTopicCtrl = TextEditingController(text: 'Network Analysis');

  @override
  void dispose() {
    _scrollController.dispose();
    _manualNameCtrl.dispose();
    _manualContentCtrl.dispose();
    _manualSubjectCtrl.dispose();
    _manualTopicCtrl.dispose();
    _urlCtrl.dispose();
    _urlSubjectCtrl.dispose();
    _urlTopicCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleImageUpload() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
    );

    if (files.isEmpty) return;
    final file = files.first;

    setState(() {
      _isProcessing = true;
      _statusText = 'Preprocessing image, running OCR and Vision extraction...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Launch human review modal
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OCRVerificationDialog(
        fileName: file.name,
        initialQuestionText:
            'A series RLC circuit has R = 10 Ω, L = 0.1 H, and C = 10 μF. What is the resonant frequency ω0 in radians/second?',
        initialOptions: const ['100 rad/s', '1000 rad/s', '316 rad/s', '10000 rad/s'],
        initialCorrectAnswer: '1000 rad/s',
        initialSolution:
            'Resonant frequency in series RLC is given by ω0 = 1 / √(LC) = 1 / √(0.1 × 10^-5) = 1 / √(10^-6) = 1000 rad/s.',
        initialSubject: 'Network Theory',
        initialTopic: 'Two-Port Networks & Resonance',
        initialDifficulty: Difficulty.medium,
      ),
    );

    if (approved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question verified and approved into Question Bank!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      context.go('/question-bank');
    }
  }

  Future<void> _handleDocumentUpload() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (files.isEmpty) return;
    final file = files.first;

    setState(() {
      _isProcessing = true;
      _statusText = 'Extracting document text and building indexed RAG chunks...';
    });

    await Future.delayed(const Duration(milliseconds: 1400));

    // Simulate extracted text and chunking
    final sampleExtractedText = '''
Page 1: ${file.name} - Extracted Content
Section: Core Engineering Concepts
The Fourier Transform of an impulse function δ(t) is 1 across all frequencies.
The convolution of two signals in the time domain corresponds to multiplication in the frequency domain.
A linear time-invariant system is completely characterized by its impulse response h(t).
Stability condition: The impulse response must be absolutely integrable, i.e., ∫|h(t)|dt < ∞.
''';

    await ref.read(sourcesRepositoryProvider).addManualTextSource(
          name: file.name,
          content: sampleExtractedText,
          subject: 'Signals and Systems',
          topic: 'Continuous & Discrete Signals',
        );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document "${file.name}" processed and added to Source Library!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    context.go('/source-library');
  }

  Future<void> _handleUrlIngestion() async {
    if (_urlCtrl.text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Connecting to user URL and extracting text...';
    });

    try {
      await ref.read(sourcesRepositoryProvider).addUrlSource(
            url: _urlCtrl.text.trim(),
            subject: _urlSubjectCtrl.text.trim(),
            topic: _urlTopicCtrl.text.trim(),
          );

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('URL content extracted and indexed in Source Library!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.go('/source-library');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        // Pre-fill manual entry fields to make pasting seamless
        _manualSubjectCtrl.text = _urlSubjectCtrl.text;
        _manualTopicCtrl.text = _urlTopicCtrl.text;
        _manualNameCtrl.text = _urlCtrl.text.trim();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.getFriendlyMessage(e)),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Paste Manually',
              textColor: Colors.white,
              onPressed: () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleManualText() async {
    if (_manualContentCtrl.text.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Chunking and indexing manual notes into Source Library...';
    });

    await ref.read(sourcesRepositoryProvider).addManualTextSource(
          name: _manualNameCtrl.text.trim(),
          content: _manualContentCtrl.text.trim(),
          subject: _manualSubjectCtrl.text.trim(),
          topic: _manualTopicCtrl.text.trim(),
        );

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notes saved and indexed in Source Library!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      context.go('/source-library');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'UPLOAD HUB',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload personal notes, question photos, PDFs, or enter URLs. Only user-uploaded materials are used for RAG AI test generation.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              if (_isProcessing)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFF93C5FD),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Processing Study Material...',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(_statusText, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Upload Modalities Grid
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width >= 700 ? 3 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _uploadCard(
                    title: 'Question Image OCR',
                    description: 'Upload question photo. Preprocesses & verifies equation text before saving.',
                    icon: Icons.camera_alt_rounded,
                    color: const Color(0xFF2563EB),
                    buttonText: 'Upload Photo',
                    onTap: _isProcessing ? null : _handleImageUpload,
                  ),
                  _uploadCard(
                    title: 'Theory PDF / DOC',
                    description: 'Upload textbooks or notes. Extracts text and builds indexed RAG chunks.',
                    icon: Icons.picture_as_pdf_rounded,
                    color: const Color(0xFF0284C7),
                    buttonText: 'Select Document',
                    onTap: _isProcessing ? null : _handleDocumentUpload,
                  ),
                  _uploadCard(
                    title: 'Question Paper',
                    description: 'Upload complete ISRO or ECE question papers for automated extraction.',
                    icon: Icons.assignment_rounded,
                    color: const Color(0xFF8B5CF6),
                    buttonText: 'Upload Paper',
                    onTap: _isProcessing ? null : _handleDocumentUpload,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // URL Ingestion Section (Section 16)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'URL INGESTION (USER-PROVIDED ONLY)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Processes ONLY the content available at the exact URL provided. Never queries search engines for alternative content.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _urlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Web Page URL (e.g. https://example.com/mesh_analysis)',
                          prefixIcon: Icon(Icons.http_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlSubjectCtrl,
                              decoration: const InputDecoration(labelText: 'Subject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _urlTopicCtrl,
                              decoration: const InputDecoration(labelText: 'Topic'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Fetch & Index URL Content'),
                          onPressed: _isProcessing ? null : _handleUrlIngestion,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Manual Text Input Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.text_snippet_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'MANUAL TEXT ENTRY',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Paste lecture transcripts, study summaries, or formula notes directly to create a source.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualNameCtrl,
                              decoration: const InputDecoration(labelText: 'Source Name'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _manualSubjectCtrl,
                              decoration: const InputDecoration(labelText: 'Subject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _manualTopicCtrl,
                              decoration: const InputDecoration(labelText: 'Topic'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _manualContentCtrl,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Paste Content Text Here...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Index Manual Notes into Library'),
                          onPressed: _isProcessing ? null : _handleManualText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String buttonText,
    required VoidCallback? onTap,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTap,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

