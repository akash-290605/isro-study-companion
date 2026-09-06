import 'package:flutter_test/flutter_test.dart';
import 'package:isro_study_companion/data/datasources/rag_service.dart';
import 'package:isro_study_companion/data/models/question_model.dart';
import 'package:isro_study_companion/data/models/source_model.dart';
import 'package:isro_study_companion/data/models/test_model.dart';

void main() {
  test('RAG Engine strictly enforces source grounding and avoids question fabrication', () {
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

    // User requests 10 questions, but materials only support 1
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
      requestedCount: 10, // Request 10
      easyTime: 60,
      mediumTime: 90,
      hardTime: 120,
      testId: 'test_rag_val',
    );

    // CRITICAL ACCEPTANCE CRITERIA (Section 22 & 63):
    // Must NOT fabricate 9 extra questions!
    expect(result.requestedCount, equals(10));
    expect(result.generatedCount, equals(1));
    expect(result.hasInsufficientSources, isTrue);
    expect(result.questions.length, equals(1));
    expect(result.statusMessage, contains('ONLY 1 QUESTIONS COULD BE GENERATED'));

    // Every question must contain source information (Section 3 & 42)
    final q = result.questions.first;
    expect(q.sourceId, equals('src_mesh_notes'));
    expect(q.sourceName, equals('Network Theory Notes.pdf'));
    expect(q.sourceLocation, contains('Page 24'));
    expect(q.sourceChunk, isNotEmpty);
  });
}

