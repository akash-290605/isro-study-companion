import 'package:flutter_test/flutter_test.dart';
import 'package:isro_study_companion/core/services/local_storage_service.dart';
import 'package:isro_study_companion/data/datasources/ai_answer_search_service.dart';
import 'package:isro_study_companion/data/datasources/ai_question_extractor_service.dart';
import 'package:isro_study_companion/data/datasources/ai_solution_evaluator_service.dart';
import 'package:isro_study_companion/data/datasources/smart_question_generator_service.dart';
import 'package:isro_study_companion/data/models/question_model.dart';
import 'package:isro_study_companion/data/repositories/questions_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AI Question Bank & Extractor System Tests', () {
    final now = DateTime.now();

    test('AIQuestionExtractorService extracts structured questions, options, and solutions', () async {
      final sampleText = "Q1. In a series RLC resonant circuit, what is the value of the impedance at resonance?\n"
          "(A) Zero\n"
          "(B) Equal to resistance R\n"
          "(C) Infinite\n"
          "(D) Purely reactive\n"
          "Answer: B\n"
          "Solution: At series resonance, the inductive reactance XL equals the capacitive reactance XC, so the net reactance is zero and the impedance is purely resistive (Z = R).\n\n"
          "Q2. What is the propagation delay of a CMOS inverter when loaded with capacitance CL?\n"
          "(A) Inversely proportional to supply voltage VDD\n"
          "(B) Independent of CL\n"
          "(C) Directly proportional to CL\n"
          "(D) Both A and C\n"
          "Answer: D\n"
          "Solution: Propagation delay is given by tpd ~ (CL * VDD) / Ion, making it directly proportional to load capacitance CL.";

      final summary = await AIQuestionExtractorService.extractQuestionsFromMaterial(
        fileName: 'network_resonance.txt',
        fileType: 'Direct Text / Paste Paper',
        rawText: sampleText,
        currentUserId: 'test_user_1',
        existingQuestionBank: const [],
      );

      expect(summary.totalDetected, equals(2));
      expect(summary.answersDetected, equals(2));
      expect(summary.extractedQuestions.length, equals(2));

      final q1 = summary.extractedQuestions[0];
      expect(q1.questionText, contains('series RLC resonant circuit'));
      expect(q1.correctAnswer, equals('B'));
      expect(q1.solution, contains('Z = R'));
      expect(q1.status, equals(QuestionStatus.unsolved));

      final q2 = summary.extractedQuestions[1];
      expect(q2.correctAnswer, equals('D'));
      expect(q2.solution, contains('Propagation delay'));
    });

    test('AIQuestionExtractorService extracts sectional textbook format with Chapter, Questions and Answers sections', () async {
      final textbookSample = '''Chapter 1: Binary Number Systems
Questions:
Q1) What is weighted code? Give example.
Q2) What is the key feature of Excess-3 code?
(a) Self-complementary (b) Non-weighted (c) Both a and b (d) None
Q3) In how many different ways can number 5 be represented using 2-4-2-1 code?

Answers:
A1) The weighted code will have a fixed weight for each position.
A2) (c) Both a and b. Excess-3 code is self-complementary and non-weighted.
A3) 2-4-2-1 represents the weights corresponding to bit positions. So the two possible ways are: 1011, 0101
''';

      final summary = await AIQuestionExtractorService.extractQuestionsFromMaterial(
        fileName: 'Digital_Electronics_Ch1.pdf',
        fileType: 'PDF',
        rawText: textbookSample,
        currentUserId: 'test_user_1',
        existingQuestionBank: const [],
      );

      expect(summary.totalDetected, equals(3));
      expect(summary.answersDetected, equals(3));
      final q1 = summary.extractedQuestions[0];
      expect(q1.questionText, contains('What is weighted code'));
      expect(q1.solution, contains('fixed weight for each position'));
      expect(q1.topic, equals('Binary Number Systems'));

      final q2 = summary.extractedQuestions[1];
      expect(q2.correctAnswer, equals('C'));
      expect(q2.options.length, equals(4));

      final q3 = summary.extractedQuestions[2];
      expect(q3.solution, contains('1011, 0101'));
    });

    test('AIQuestionExtractorService detects semantic duplicates against existing question bank', () {
      final existingQ = QuestionModel(
        questionId: 'q_exist_1',
        sourceId: 'src_test',
        sourceName: 'Test Paper',
        createdAt: now,
        userId: 'test_user_1',
        questionText: 'What is the impedance of a series RLC circuit at resonant frequency?',
        options: const ['(A) R', '(B) 0', '(C) Infinity', '(D) XL'],
        correctAnswer: 'A',
        subject: 'Network Theory',
        topic: 'Resonance',
      );

      final candidateQ = QuestionModel(
        questionId: 'q_new_1',
        sourceId: 'src_test',
        sourceName: 'Test Paper',
        createdAt: now,
        userId: 'test_user_1',
        questionText: 'What is the impedance of a series RLC circuit at resonance?',
        options: const ['(A) Purely resistive R', '(B) Zero', '(C) Infinite'],
        correctAnswer: 'A',
        subject: 'Network Theory',
        topic: 'Resonance',
      );

      final duplicates = AIQuestionExtractorService.findDuplicates([candidateQ], [existingQ]);

      expect(duplicates.isNotEmpty, isTrue);
      expect(duplicates.first.similarityScore, greaterThan(0.60));
      expect(duplicates.first.existingQuestion.questionId, equals('q_exist_1'));
    });

    test('AISolutionEvaluatorService evaluates student submission with score, concepts, and status', () async {
      final question = QuestionModel(
        questionId: 'q_eval_1',
        sourceId: 'src_test',
        sourceName: 'Test Paper',
        createdAt: now,
        userId: 'test_user_1',
        questionText: 'Calculate the resonant frequency for L = 10 mH and C = 100 nF.',
        options: const ['(A) 5.03 kHz', '(B) 10 kHz', '(C) 15.9 kHz', '(D) 1.59 kHz'],
        correctAnswer: 'A',
        subject: 'Network Theory',
        topic: 'Resonance and Frequency Calculation',
        solution: 'Formula: f0 = 1 / (2 * pi * sqrt(L * C)). Substituting L = 10mH and C = 100nF gives f0 = 5.032 kHz.',
      );

      final result = await AISolutionEvaluatorService.evaluateUserSolution(
        question: question,
        userTextAnswer: 'Resonance condition: f0 = 1 / (2 * pi * sqrt(L * C)). For L = 10mH and C = 100nF, f0 = 5.03 kHz.',
      );

      expect(result.scoreOutOfTen, greaterThanOrEqualTo(7.0));
      expect(result.resultingStatus, isIn([QuestionStatus.solved, QuestionStatus.partiallySolved]));
      expect(result.coveredConcepts.isNotEmpty, isTrue);
    });

    test('AIAnswerSearchService provides verified solution with references for unknown questions', () async {
      final unknownQ = QuestionModel(
        questionId: 'q_unknown_1',
        sourceId: 'src_test',
        sourceName: 'Test Paper',
        createdAt: now,
        userId: 'test_user_1',
        questionText: 'In an asynchronous FIFO, why is Gray code pointer synchronization preferred over binary?',
        options: const [
          '(A) Gray code changes only one bit per transition, eliminating metastability hazards.',
          '(B) Gray code operates at twice the clock frequency.',
          '(C) Gray code consumes zero dynamic power.',
          '(D) Gray code avoids full/empty flag generation.',
        ],
        correctAnswer: 'ANSWER UNKNOWN',
        verificationStatus: VerificationStatus.unknown,
        subject: 'Digital Electronics',
        topic: 'Asynchronous FIFO & Metastability',
      );

      final webResult = await AIAnswerSearchService.searchAndVerifyAnswer(unknownQ);

      expect(webResult.answer.isNotEmpty, isTrue);
      expect(webResult.explanation, contains('Gray code'));
      expect(webResult.referenceSources.isNotEmpty, isTrue);
      expect(webResult.confidence, greaterThan(0.90));
    });

    test('SmartQuestionGeneratorService generates distinct concept variations', () async {
      final baseQ = QuestionModel(
        questionId: 'q_base_1',
        sourceId: 'src_test',
        sourceName: 'Test Paper',
        createdAt: now,
        userId: 'test_user_1',
        questionText: 'State the Maximum Power Transfer Theorem for AC circuits with load impedance ZL.',
        options: const ['A. ZL = Zth*', 'B. ZL = Zth', 'C. ZL = Rth', 'D. ZL = 0'],
        correctAnswer: 'A',
        subject: 'Network Theory',
        topic: 'Maximum Power Transfer',
      );

      final easierVar = await SmartQuestionGeneratorService.generateVariation(
        baseQuestion: baseQ,
        variationType: VariationType.easier,
        currentUserId: 'test_user_1',
      );

      expect(easierVar.difficulty, equals(Difficulty.easy));
      expect(easierVar.questionId, isNot(equals(baseQ.questionId)));

      final harderVar = await SmartQuestionGeneratorService.generateVariation(
        baseQuestion: baseQ,
        variationType: VariationType.harder,
        currentUserId: 'test_user_1',
      );

      expect(harderVar.difficulty, equals(Difficulty.hard));
    });

    test('QuestionsRepository manages question lifecycle, statuses, and attempts properly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      final repo = QuestionsRepository(storage);

      repo.loadForUser('user_test_abc');
      expect(repo.questions.isEmpty, isTrue);

      final q1 = QuestionModel(
        questionId: 'user_q_1',
        sourceId: 'src_test',
        sourceName: 'Test Paper',
        createdAt: now,
        userId: 'user_test_abc',
        questionText: 'Sample circuit question',
        options: const ['A', 'B'],
        correctAnswer: 'A',
        status: QuestionStatus.unsolved,
        subject: 'Network Theory',
        topic: 'KCL and KVL',
      );

      await repo.addQuestion(q1);
      expect(repo.totalCount, equals(1));
      expect(repo.unsolvedCount, equals(1));
      expect(repo.solvedCount, equals(0));

      await repo.updateQuestionStatus(q1.questionId, QuestionStatus.solved);
      expect(repo.solvedCount, equals(1));
      expect(repo.unsolvedCount, equals(0));

      await repo.recordDetailedAttempt(q1.questionId, true);
      final updated = repo.questions.first;
      expect(updated.attemptCount, equals(1));
      expect(updated.correctAttempts, equals(1));
      expect(updated.status, equals(QuestionStatus.solved));

      await repo.deleteQuestion(q1.questionId);
      expect(repo.totalCount, equals(0));
    });
  });
}
