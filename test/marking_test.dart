import 'package:flutter_test/flutter_test.dart';
import 'package:isro_study_companion/data/models/question_model.dart';
import 'package:isro_study_companion/data/models/test_model.dart';
import 'package:isro_study_companion/data/repositories/test_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isro_study_companion/core/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late TestRepository testRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorageService.init();
    testRepo = TestRepository(storage);
    testRepo.loadForUser('test_user_01');
  });

  test('Exam Score Calculation with Negative Marking Enabled (Example in Section 26)', () {
    // Specification Section 26 Example:
    // Total Questions: 20
    // Correct: 14 (+1 each = 14)
    // Wrong: 4 (-0.25 each = 1)
    // Unattempted: 2 (0 each = 0)
    // Final Score = 14 - 1 = 13 (Percentage = 65%)

    final test = TestModel(
      testId: 'test_26',
      userId: 'test_user_01',
      questionCount: 20,
      correctMarks: 1.0,
      negativeMarks: -0.25,
      unattemptedMarks: 0.0,
      negativeMarkingEnabled: true,
      createdAt: DateTime(2026, 9, 6),
    );

    final List<TestQuestionModel> answeredQuestions = [];

    // 14 correct questions
    for (int i = 0; i < 14; i++) {
      answeredQuestions.add(
        TestQuestionModel(
          questionId: 'q_$i',
          testId: 'test_26',
          sourceId: 'src_1',
          sourceName: 'Network Theory Notes.pdf',
          questionText: 'Question $i',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          userAnswer: 'A',
          difficulty: Difficulty.medium,
          timeAllowedSeconds: 90,
          status: TestQuestionStatus.answered,
        ),
      );
    }

    // 4 wrong questions
    for (int i = 14; i < 18; i++) {
      answeredQuestions.add(
        TestQuestionModel(
          questionId: 'q_$i',
          testId: 'test_26',
          sourceId: 'src_1',
          sourceName: 'Network Theory Notes.pdf',
          questionText: 'Question $i',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          userAnswer: 'B', // Incorrect
          difficulty: Difficulty.medium,
          timeAllowedSeconds: 90,
          status: TestQuestionStatus.answered,
        ),
      );
    }

    // 2 unattempted questions
    for (int i = 18; i < 20; i++) {
      answeredQuestions.add(
        TestQuestionModel(
          questionId: 'q_$i',
          testId: 'test_26',
          sourceId: 'src_1',
          sourceName: 'Network Theory Notes.pdf',
          questionText: 'Question $i',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          userAnswer: null, // Unattempted
          difficulty: Difficulty.medium,
          timeAllowedSeconds: 90,
          status: TestQuestionStatus.unanswered,
        ),
      );
    }

    final result = testRepo.calculateAndSaveResult(
      test: test,
      answeredQuestions: answeredQuestions,
      timeUsedSeconds: 1662, // 27:42
    );

    expect(result.correctCount, equals(14));
    expect(result.wrongCount, equals(4));
    expect(result.unattemptedCount, equals(2));
    expect(result.negativeMarksDeducted, equals(1.0));
    expect(result.score, equals(13.0));
    expect(result.percentage, equals(65.0));
  });

  test('Exam Score Calculation with Negative Marking Disabled', () {
    final test = TestModel(
      testId: 'test_neg_disabled',
      userId: 'test_user_01',
      questionCount: 10,
      correctMarks: 2.0,
      negativeMarks: -0.5,
      unattemptedMarks: 0.0,
      negativeMarkingEnabled: false, // Disabled
      createdAt: DateTime(2026, 9, 6),
    );

    final List<TestQuestionModel> answeredQuestions = [
      // 5 correct (+2 each = 10)
      for (int i = 0; i < 5; i++)
        TestQuestionModel(
          questionId: 'qc_$i',
          testId: 'test_neg_disabled',
          sourceId: 'src_1',
          sourceName: 'Notes.pdf',
          questionText: 'Q $i',
          options: const ['A', 'B'],
          correctAnswer: 'A',
          userAnswer: 'A',
          difficulty: Difficulty.easy,
          timeAllowedSeconds: 60,
          status: TestQuestionStatus.answered,
        ),
      // 5 wrong (0 deduction since disabled)
      for (int i = 0; i < 5; i++)
        TestQuestionModel(
          questionId: 'qw_$i',
          testId: 'test_neg_disabled',
          sourceId: 'src_1',
          sourceName: 'Notes.pdf',
          questionText: 'Q $i',
          options: const ['A', 'B'],
          correctAnswer: 'A',
          userAnswer: 'B',
          difficulty: Difficulty.easy,
          timeAllowedSeconds: 60,
          status: TestQuestionStatus.answered,
        ),
    ];

    final result = testRepo.calculateAndSaveResult(
      test: test,
      answeredQuestions: answeredQuestions,
      timeUsedSeconds: 300,
    );

    expect(result.correctCount, equals(5));
    expect(result.wrongCount, equals(5));
    expect(result.negativeMarksDeducted, equals(0.0));
    expect(result.score, equals(10.0));
    expect(result.maxScore, equals(20.0));
    expect(result.percentage, equals(50.0));
  });
}

