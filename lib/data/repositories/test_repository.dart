import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/local_storage_service.dart';
import '../models/test_model.dart';
import '../models/test_result_model.dart';
import '../models/sync_model.dart';

class TestRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<TestModel> _tests = [];
  List<TestResultModel> _results = [];
  String? _currentUserId;

  TestRepository(this._storage);

  List<TestModel> get tests => _tests;
  List<TestResultModel> get results => _results;

  void loadForUser(String userId) {
    _currentUserId = userId;
    _tests = _storage.getTests(userId);
    _results = _storage.getTestResults(userId);
    notifyListeners();
  }

  Future<void> saveTest(TestModel test) async {
    if (_currentUserId == null) return;
    _tests.insert(0, test);
    await _storage.saveTests(_currentUserId!, _tests);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.create,
        collectionName: 'tests',
        documentId: test.testId,
        payload: test.toJson(),
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Calculates exam score strictly according to the formula:
  /// Score = Correct Marks - Negative Marks
  TestResultModel calculateAndSaveResult({
    required TestModel test,
    required List<TestQuestionModel> answeredQuestions,
    required int timeUsedSeconds,
  }) {
    if (_currentUserId == null) throw Exception('User not authenticated');

    int correctCount = 0;
    int wrongCount = 0;
    int unattemptedCount = 0;
    double negativeMarksDeducted = 0.0;
    double correctMarksAwarded = 0.0;

    final Map<String, int> topicCorrect = {};
    final Map<String, int> topicWrong = {};
    final Map<String, int> topicUnattempted = {};
    final Map<String, int> topicTotal = {};

    final Map<String, int> diffCorrect = {};
    final Map<String, int> diffTotal = {};

    final List<TestQuestionModel> scoredQuestions = [];

    for (final q in answeredQuestions) {
      final topicName = q.topic.isEmpty ? 'General' : q.topic;
      final diffLabel = q.difficulty.label;

      topicTotal[topicName] = (topicTotal[topicName] ?? 0) + 1;
      diffTotal[diffLabel] = (diffTotal[diffLabel] ?? 0) + 1;

      if (q.userAnswer == null || q.userAnswer!.trim().isEmpty || q.status == TestQuestionStatus.timeUp) {
        unattemptedCount += 1;
        topicUnattempted[topicName] = (topicUnattempted[topicName] ?? 0) + 1;
        scoredQuestions.add(
          q.copyWith(
            marksAwarded: test.unattemptedMarks,
            isCorrect: false,
          ),
        );
      } else if (q.userAnswer!.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase()) {
        correctCount += 1;
        correctMarksAwarded += test.correctMarks;
        topicCorrect[topicName] = (topicCorrect[topicName] ?? 0) + 1;
        diffCorrect[diffLabel] = (diffCorrect[diffLabel] ?? 0) + 1;
        scoredQuestions.add(
          q.copyWith(
            marksAwarded: test.correctMarks,
            isCorrect: true,
          ),
        );
      } else {
        wrongCount += 1;
        topicWrong[topicName] = (topicWrong[topicName] ?? 0) + 1;
        final deduction = test.negativeMarkingEnabled ? test.negativeMarks.abs() : 0.0;
        negativeMarksDeducted += deduction;
        scoredQuestions.add(
          q.copyWith(
            marksAwarded: -deduction,
            isCorrect: false,
          ),
        );
      }
    }

    final totalScore = correctMarksAwarded - negativeMarksDeducted;
    final maxScore = test.questionCount * test.correctMarks;
    final percentage = maxScore > 0 ? ((totalScore / maxScore) * 100).clamp(0.0, 100.0) : 0.0;

    // Generate topic breakdowns
    final Map<String, TopicPerformance> topicBreakdown = {};
    for (final topic in topicTotal.keys) {
      final total = topicTotal[topic] ?? 0;
      final correct = topicCorrect[topic] ?? 0;
      final wrong = topicWrong[topic] ?? 0;
      final unattempted = topicUnattempted[topic] ?? 0;
      final accuracy = total > 0 ? (correct / total) * 100 : 0.0;

      topicBreakdown[topic] = TopicPerformance(
        topic: topic,
        correct: correct,
        wrong: wrong,
        unattempted: unattempted,
        total: total,
        accuracy: accuracy,
      );
    }

    // Generate difficulty breakdowns
    final Map<String, DifficultyPerformance> diffBreakdown = {};
    for (final diff in ['EASY', 'MEDIUM', 'HARD']) {
      final total = diffTotal[diff] ?? 0;
      final correct = diffCorrect[diff] ?? 0;
      final accuracy = total > 0 ? (correct / total) * 100 : 0.0;

      diffBreakdown[diff] = DifficultyPerformance(
        difficulty: diff,
        correct: correct,
        total: total,
        accuracy: accuracy,
      );
    }

    final result = TestResultModel(
      resultId: const Uuid().v4(),
      testId: test.testId,
      userId: _currentUserId!,
      title: test.title,
      score: totalScore,
      maxScore: maxScore,
      percentage: percentage,
      correctCount: correctCount,
      wrongCount: wrongCount,
      unattemptedCount: unattemptedCount,
      negativeMarksDeducted: negativeMarksDeducted,
      timeUsedSeconds: timeUsedSeconds,
      topicBreakdown: topicBreakdown,
      difficultyBreakdown: diffBreakdown,
      questions: scoredQuestions,
      completedAt: DateTime.now(),
    );

    _results.insert(0, result);
    _storage.saveTestResults(_currentUserId!, _results);
    _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.create,
        collectionName: 'testResults',
        documentId: result.resultId,
        payload: result.toJson(),
        timestamp: DateTime.now(),
      ),
    );

    notifyListeners();
    return result;
  }
}

