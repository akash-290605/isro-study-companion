import 'package:flutter_test/flutter_test.dart';
import 'package:isro_study_companion/data/datasources/smart_question_generator_service.dart';
import 'package:isro_study_companion/data/datasources/rag_service.dart';
import 'package:isro_study_companion/data/models/question_model.dart';
import 'package:isro_study_companion/data/models/source_model.dart';
import 'package:isro_study_companion/data/models/test_model.dart';

void main() {
  group('AI Question Auto-Expansion & Web Search Tests', () {
    test('SmartQuestionGeneratorService searches and synthesizes similar questions from single seed question', () async {
      final seed = QuestionModel(
        questionId: 'seed_01',
        userId: 'test_user',
        sourceId: 'syllabus_01',
        sourceName: 'ISRO ECE Syllabus',
        questionText: 'In a series RLC circuit at resonance, the impedance is purely resistive.',
        options: const [
          'A. Purely resistive',
          'B. Purely inductive',
          'C. Purely capacitive',
          'D. Zero',
        ],
        correctAnswer: 'A',
        solution: 'At resonance, inductive and capacitive reactances cancel out: XL = XC, leaving Z = R.',
        subject: 'Network Theory',
        topic: 'RLC Resonant Circuits',
        difficulty: Difficulty.medium,
        questionType: QuestionType.mcq,
        createdAt: DateTime.now(),
      );

      final generated = await SmartQuestionGeneratorService.searchAndGenerateSimilarQuestions(
        seedQuestion: seed,
        count: 3,
        currentUserId: 'test_user',
      );

      expect(generated.length, equals(3));
      for (final q in generated) {
        expect(q.options.length, equals(4));
        expect(q.correctAnswer.isNotEmpty, isTrue);
        expect(q.solution.isNotEmpty, isTrue);
        expect(q.sourceName, contains('Web Search'));
        expect(q.verificationStatus, equals(VerificationStatus.aiGenerated));
      }
    });

    test('RAGService with allowAiExpansion: true automatically completes required question count when sources are minimal', () {
      final sources = [
        SourceDocumentModel(
          sourceId: 'src_mesh_notes',
          userId: 'user_1',
          sourceType: SourceType.pdf,
          sourceName: 'Network Theory Notes.pdf',
          subject: 'Network Theory',
          topic: 'Network Analysis',
          chunks: const [
            SourceChunkModel(
              chunkId: 'chunk_1',
              sourceId: 'src_mesh_notes',
              pageNumber: 24,
              section: 'Mesh Analysis',
              content: 'The number of independent mesh equations required for planar circuits is b - n + 1.',
              topic: 'Network Analysis',
            ),
          ],
          uploadedAt: DateTime.now(),
        ),
      ];

      final questionBank = [
        QuestionModel(
          questionId: 'q_grounded_1',
          userId: 'user_1',
          questionText: 'What is the formula for independent mesh equations?',
          options: ['b - n + 1', 'b + n - 1', 'b - n', 'n - 1'],
          correctAnswer: 'b - n + 1',
          solution: 'Directly stated on Page 24 of Network Theory Notes.pdf',
          subject: 'Network Theory',
          topic: 'Network Analysis',
          sourceId: 'src_mesh_notes',
          sourceName: 'Network Theory Notes.pdf',
          sourceLocation: 'Page 24, Mesh Analysis',
          sourceChunk: 'The number of independent mesh equations required for planar circuits is b - n + 1.',
          createdAt: DateTime.now(),
        ),
      ];

      // Request 5 questions with allowAiExpansion: true
      final result = RAGService.generateExamQuestions(
        allSources: sources,
        availableQuestionBank: questionBank,
        selectedSourceIds: ['src_mesh_notes'],
        selectedSubjects: ['Network Theory'],
        selectedTopics: ['Network Analysis'],
        selectedSubtopics: const [],
        difficultyMode: DifficultyMode.medium,
        easyPercentage: 30,
        mediumPercentage: 50,
        hardPercentage: 20,
        requestedCount: 5,
        easyTime: 60,
        mediumTime: 90,
        hardTime: 120,
        testId: 'test_ai_expansion',
        allowAiExpansion: true,
      );

      // Must satisfy requestedCount: 5 questions and hasInsufficientSources is false!
      expect(result.requestedCount, equals(5));
      expect(result.generatedCount, equals(5));
      expect(result.questions.length, equals(5));
      expect(result.hasInsufficientSources, isFalse);
    });
  });
}
