import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/math_renderer.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/study_session_model.dart';
import '../../../data/models/test_model.dart';
import '../../test_results/screens/test_result_screen.dart';

class TestRunnerScreen extends ConsumerStatefulWidget {
  final TestModel test;

  const TestRunnerScreen({super.key, required this.test});

  @override
  ConsumerState<TestRunnerScreen> createState() => _TestRunnerScreenState();
}

class _TestRunnerScreenState extends ConsumerState<TestRunnerScreen> {
  late List<TestQuestionModel> _questions;
  int _currentIndex = 0;

  // Per-question countdown state
  int _currentQuestionSecondsRemaining = 90;
  Timer? _questionTicker;

  // Track remaining time per question so revisit doesn't restart timer
  final Map<int, int> _questionRemainingSecondsMap = {};

  // Overall test timer tracking
  int _totalElapsedSeconds = 0;
  Timer? _overallTicker;

  @override
  void initState() {
    super.initState();
    _questions = List<TestQuestionModel>.from(widget.test.questions);
    _initQuestionTimer(_currentIndex);

    // Track overall duration
    _overallTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _totalElapsedSeconds += 1;
    });
  }

  @override
  void dispose() {
    _questionTicker?.cancel();
    _overallTicker?.cancel();
    super.dispose();
  }

  void _initQuestionTimer(int index) {
    _questionTicker?.cancel();
    final q = _questions[index];

    // Check if this question already has remaining seconds saved
    if (_questionRemainingSecondsMap.containsKey(index)) {
      _currentQuestionSecondsRemaining = _questionRemainingSecondsMap[index]!;
    } else {
      _currentQuestionSecondsRemaining = q.timeAllowedSeconds;
      _questionRemainingSecondsMap[index] = _currentQuestionSecondsRemaining;
    }

    // If time was already expired previously, lock it
    if (_currentQuestionSecondsRemaining <= 0) {
      return;
    }

    _questionTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_currentQuestionSecondsRemaining > 0) {
          _currentQuestionSecondsRemaining -= 1;
          _questionRemainingSecondsMap[index] = _currentQuestionSecondsRemaining;
        } else {
          // Time expired for this question: lock and auto-move to next!
          timer.cancel();
          _handleQuestionTimeUp(index);
        }
      });
    });
  }

  void _handleQuestionTimeUp(int index) {
    final currentQ = _questions[index];
    final updatedQ = currentQ.copyWith(
      status: currentQ.userAnswer != null && currentQ.userAnswer!.isNotEmpty
          ? TestQuestionStatus.answered
          : TestQuestionStatus.timeUp,
      timeUsedSeconds: currentQ.timeAllowedSeconds,
    );
    _questions[index] = updatedQ;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Time up for Question ${index + 1}! Moving to next.'),
        duration: const Duration(seconds: 1),
      ),
    );

    if (index < _questions.length - 1) {
      _goToQuestion(index + 1);
    } else {
      _submitTest();
    }
  }

  void _goToQuestion(int newIndex) {
    if (newIndex < 0 || newIndex >= _questions.length) return;
    if (widget.test.strictModeNoPrevious && newIndex < _currentIndex) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Strict Mode enabled: Cannot return to previous questions.')),
      );
      return;
    }

    // Save remaining seconds for the question we're leaving
    _questionRemainingSecondsMap[_currentIndex] = _currentQuestionSecondsRemaining;

    setState(() {
      _currentIndex = newIndex;
    });
    _initQuestionTimer(newIndex);
  }

  void _selectAnswer(String option) {
    final currentQ = _questions[_currentIndex];
    // If locked by time-up, prevent changes
    if (_currentQuestionSecondsRemaining <= 0 || currentQ.status == TestQuestionStatus.timeUp) {
      return;
    }

    final updated = currentQ.copyWith(
      userAnswer: option,
      status: TestQuestionStatus.answered,
    );
    setState(() {
      _questions[_currentIndex] = updated;
    });
  }

  void _toggleMarkForReview() {
    final currentQ = _questions[_currentIndex];
    final newStatus = currentQ.status == TestQuestionStatus.markedForReview
        ? (currentQ.userAnswer != null ? TestQuestionStatus.answered : TestQuestionStatus.unanswered)
        : TestQuestionStatus.markedForReview;

    setState(() {
      _questions[_currentIndex] = currentQ.copyWith(status: newStatus);
    });
  }

  Future<void> _submitTest() async {
    _questionTicker?.cancel();
    _overallTicker?.cancel();

    // Calculate score, record mistakes, and update performance
    final testRepo = ref.read(testRepositoryProvider);
    final result = testRepo.calculateAndSaveResult(
      test: widget.test,
      answeredQuestions: _questions,
      timeUsedSeconds: _totalElapsedSeconds,
    );

    final deviceName = Theme.of(context).platform.name;

    // Ingest mistakes into Mistake Notebook
    await ref.read(mistakesRepositoryProvider).ingestTestMistakes(
          testId: widget.test.testId,
          questions: result.questions,
        );

    // Save test session in StudySessions for study time tracking
    await ref.read(studySessionsRepositoryProvider).recordSession(
          startTime: DateTime.now().subtract(Duration(seconds: _totalElapsedSeconds)),
          endTime: DateTime.now(),
          durationSeconds: _totalElapsedSeconds,
          mode: TimerMode.stopwatch,
          subject: widget.test.selectedTopics.isNotEmpty ? widget.test.selectedTopics.first : 'Exam Test',
          topic: 'Mock Test Session',
          device: deviceName,
        );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => TestResultScreen(result: result),
        ),
      );
    }
  }

  void _confirmSubmit() {
    final unanswered = _questions.where((q) => q.userAnswer == null).length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Test?'),
        content: Text(
          unanswered > 0
              ? 'You have $unanswered unattempted questions. Unattempted questions receive 0 marks.\nAre you sure you want to submit?'
              : 'Are you sure you want to submit your answers?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continue Test')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              Navigator.pop(ctx);
              _submitTest();
            },
            child: const Text('Submit Now'),
          ),
        ],
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentIndex];
    final isLocked = _currentQuestionSecondsRemaining <= 0 || currentQ.status == TestQuestionStatus.timeUp;

    Color diffColor = Colors.orange;
    if (currentQ.difficulty == Difficulty.easy) diffColor = Colors.green;
    if (currentQ.difficulty == Difficulty.hard) diffColor = Colors.red;

    final isWide = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title, style: const TextStyle(fontSize: 15)),
        actions: [
          // Per-question countdown timer badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _currentQuestionSecondsRemaining <= 15
                  ? Colors.red.shade100
                  : const Color(0xFF1E3A8A).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _currentQuestionSecondsRemaining <= 15
                    ? Colors.red
                    : const Color(0xFF1E3A8A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: _currentQuestionSecondsRemaining <= 15 ? Colors.red : const Color(0xFF1E3A8A),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTimer(_currentQuestionSecondsRemaining),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: _currentQuestionSecondsRemaining <= 15 ? Colors.red : const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: _confirmSubmit,
            child: const Text('Submit Test', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Main Question Card
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Topic & Difficulty & Status Tag Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentIndex + 1} of ${_questions.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: diffColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentQ.difficulty.label,
                              style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentQ.topic,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  if (isLocked)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_clock_rounded, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Time has expired for this question. Answer is locked.',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  // Question Text
                  MathFormulaView(
                    formula: currentQ.questionText,
                    textStyle: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // Options
                  ...currentQ.options.asMap().entries.map((entry) {
                    final isSelected = currentQ.userAnswer == entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: InkWell(
                        onTap: isLocked ? null : () => _selectAnswer(entry.value),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1E3A8A).withOpacity(0.1)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1E3A8A)
                                  : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + entry.key),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: MathFormulaView(
                                  formula: entry.value,
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Bottom Controls: Previous, Mark for Review, Next
                  Row(
                    children: [
                      if (!widget.test.strictModeNoPrevious)
                        OutlinedButton.icon(
                          onPressed: _currentIndex > 0 ? () => _goToQuestion(_currentIndex - 1) : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                          label: const Text('Previous'),
                        ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: currentQ.status == TestQuestionStatus.markedForReview
                              ? Colors.purple
                              : null,
                        ),
                        onPressed: _toggleMarkForReview,
                        icon: Icon(
                          currentQ.status == TestQuestionStatus.markedForReview
                              ? Icons.bookmark_added
                              : Icons.bookmark_border,
                          color: currentQ.status == TestQuestionStatus.markedForReview
                              ? Colors.purple
                              : null,
                        ),
                        label: Text(
                          currentQ.status == TestQuestionStatus.markedForReview
                              ? 'Marked for Review'
                              : 'Mark for Review',
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: _currentIndex < _questions.length - 1
                            ? () => _goToQuestion(_currentIndex + 1)
                            : _confirmSubmit,
                        icon: Icon(
                          _currentIndex < _questions.length - 1
                              ? Icons.chevron_right_rounded
                              : Icons.check_circle_rounded,
                        ),
                        label: Text(_currentIndex < _questions.length - 1 ? 'Next' : 'Submit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Question Palette Sidebar (Desktop)
          if (isWide)
            Container(
              width: 260,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey.shade200)),
              ),
              child: _buildQuestionPalette(),
            ),
        ],
      ),
      endDrawer: isWide ? null : Drawer(child: _buildQuestionPalette()),
    );
  }

  Widget _buildQuestionPalette() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUESTION PALETTE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              _legendItem(Colors.green, 'Answered'),
              const SizedBox(width: 8),
              _legendItem(Colors.purple, 'Review'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _legendItem(Colors.red, 'Time Up'),
              const SizedBox(width: 8),
              _legendItem(Colors.grey, 'Unanswered'),
            ],
          ),
          const Divider(height: 24),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _questions.length,
              itemBuilder: (ctx, i) {
                final q = _questions[i];
                final isCurrent = i == _currentIndex;

                Color bg = Colors.grey.shade200;
                Color textCol = Colors.black87;

                if (q.status == TestQuestionStatus.answered) {
                  bg = Colors.green.shade600;
                  textCol = Colors.white;
                } else if (q.status == TestQuestionStatus.markedForReview) {
                  bg = Colors.purple.shade600;
                  textCol = Colors.white;
                } else if (q.status == TestQuestionStatus.timeUp) {
                  bg = Colors.red.shade600;
                  textCol = Colors.white;
                }

                return InkWell(
                  onTap: () => _goToQuestion(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrent
                          ? Border.all(color: const Color(0xFF1E3A8A), width: 2.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: textCol,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

