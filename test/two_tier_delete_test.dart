import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isro_study_companion/core/services/local_storage_service.dart';
import 'package:isro_study_companion/data/models/formula_model.dart';
import 'package:isro_study_companion/data/models/question_model.dart';
import 'package:isro_study_companion/data/models/sync_model.dart';
import 'package:isro_study_companion/data/repositories/formula_repository.dart';
import 'package:isro_study_companion/data/repositories/questions_repository.dart';
import 'package:isro_study_companion/data/repositories/sources_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late SourcesRepository sourcesRepo;
  late QuestionsRepository questionsRepo;
  late FormulaRepository formulaRepo;
  const testUserId = 'test_user_123';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorageService.init();
    sourcesRepo = SourcesRepository(storage);
    questionsRepo = QuestionsRepository(storage);
    formulaRepo = FormulaRepository(storage);

    sourcesRepo.loadForUser(testUserId);
    questionsRepo.loadForUser(testUserId);
    formulaRepo.loadForUser(testUserId);
  });

  group('LocalStorageService Hidden Items Tests', () {
    test('Hides and checks locally hidden items', () async {
      expect(storage.isItemHiddenLocally(testUserId, 'sources', 'doc_1'), isFalse);

      await storage.hideItemLocally(testUserId, 'sources', 'doc_1');
      expect(storage.isItemHiddenLocally(testUserId, 'sources', 'doc_1'), isTrue);
      expect(storage.getHiddenItemIds(testUserId, 'sources'), contains('doc_1'));

      await storage.unhideItemLocally(testUserId, 'sources', 'doc_1');
      expect(storage.isItemHiddenLocally(testUserId, 'sources', 'doc_1'), isFalse);
    });
  });

  group('SourcesRepository Two-Tier Delete Tests', () {
    test('Permanent delete enqueues delete action and removes from local storage', () async {
      final doc = await sourcesRepo.addManualTextSource(
        name: 'Signals Notes',
        content: 'Nyquist theorem states that fs >= 2fm.',
        subject: 'Signals and Systems',
        topic: 'Sampling',
      );

      expect(sourcesRepo.sources.any((s) => s.sourceId == doc.sourceId), isTrue);

      await sourcesRepo.deleteSource(doc.sourceId, permanent: true);

      expect(sourcesRepo.sources.any((s) => s.sourceId == doc.sourceId), isFalse);
      final queue = storage.getSyncQueue(testUserId);
      expect(queue.any((a) => a.documentId == doc.sourceId && a.actionType == QueuedActionType.delete), isTrue);
    });

    test('Local-only delete hides document locally without enqueuing delete action', () async {
      final doc = await sourcesRepo.addManualTextSource(
        name: 'Control Systems Notes',
        content: 'Routh Hurwitz stability criterion.',
        subject: 'Control Systems',
        topic: 'Stability',
      );

      await sourcesRepo.deleteSource(doc.sourceId, permanent: false);

      expect(sourcesRepo.sources.any((s) => s.sourceId == doc.sourceId), isFalse);
      expect(storage.isItemHiddenLocally(testUserId, 'sources', doc.sourceId), isTrue);

      // Verify no delete action was enqueued for cloud
      final newQueue = storage.getSyncQueue(testUserId);
      expect(newQueue.where((a) => a.actionType == QueuedActionType.delete).isEmpty, isTrue);

      // Verify reload for user still excludes the locally hidden source
      final newRepo = SourcesRepository(storage);
      newRepo.loadForUser(testUserId);
      expect(newRepo.sources.any((s) => s.sourceId == doc.sourceId), isFalse);
    });
  });

  group('QuestionsRepository Two-Tier Delete Tests', () {
    test('Permanent delete enqueues cloud delete and removes question', () async {
      final q = QuestionModel(
        questionId: 'custom_q_1',
        userId: testUserId,
        subject: 'Digital Electronics',
        topic: 'Logic Gates',
        sourceId: 'doc_de',
        sourceName: 'DE Notes',
        questionText: 'What is the output of XOR gate for 1 and 1?',
        options: ['0', '1', 'Undefined', 'High-Z'],
        correctAnswer: '0',
        solution: '1 XOR 1 = 0',
        createdAt: DateTime.now(),
      );

      await questionsRepo.addQuestion(q);
      expect(questionsRepo.questions.any((item) => item.questionId == 'custom_q_1'), isTrue);

      await questionsRepo.deleteQuestion('custom_q_1', permanent: true);
      expect(questionsRepo.questions.any((item) => item.questionId == 'custom_q_1'), isFalse);

      final queue = storage.getSyncQueue(testUserId);
      expect(queue.any((a) => a.documentId == 'custom_q_1' && a.actionType == QueuedActionType.delete), isTrue);
    });

    test('Local-only delete hides question locally without enqueuing cloud delete', () async {
      final q = QuestionModel(
        questionId: 'custom_q_2',
        userId: testUserId,
        subject: 'Electromagnetics',
        topic: 'Maxwell Equations',
        sourceId: 'doc_em',
        sourceName: 'EM Notes',
        questionText: 'Divergence of magnetic flux density B is zero.',
        options: ['True', 'False'],
        correctAnswer: 'True',
        solution: 'div(B) = 0',
        createdAt: DateTime.now(),
      );

      await questionsRepo.addQuestion(q);
      await questionsRepo.deleteQuestion('custom_q_2', permanent: false);

      expect(questionsRepo.questions.any((item) => item.questionId == 'custom_q_2'), isFalse);
      expect(storage.isItemHiddenLocally(testUserId, 'questions', 'custom_q_2'), isTrue);

      final newRepo = QuestionsRepository(storage);
      newRepo.loadForUser(testUserId);
      expect(newRepo.questions.any((item) => item.questionId == 'custom_q_2'), isFalse);
    });
  });

  group('FormulaRepository Two-Tier Delete Tests', () {
    test('Permanent delete enqueues cloud delete and removes formula', () async {
      final formula = FormulaModel(
        formulaId: 'custom_f_1',
        userId: testUserId,
        title: 'Ohms Law',
        subject: 'Network Theory',
        topic: 'DC Circuits',
        latexExpression: r'V = I \cdot R',
        createdAt: DateTime.now(),
      );

      await formulaRepo.addFormula(formula);
      expect(formulaRepo.formulas.any((f) => f.formulaId == 'custom_f_1'), isTrue);

      await formulaRepo.deleteFormula('custom_f_1', permanent: true);
      expect(formulaRepo.formulas.any((f) => f.formulaId == 'custom_f_1'), isFalse);

      final queue = storage.getSyncQueue(testUserId);
      expect(queue.any((a) => a.documentId == 'custom_f_1' && a.actionType == QueuedActionType.delete), isTrue);
    });

    test('Local-only delete hides formula locally without cloud delete', () async {
      final formula = FormulaModel(
        formulaId: 'custom_f_2',
        userId: testUserId,
        title: 'Euler Identity',
        subject: 'Signals and Systems',
        topic: 'Fourier',
        latexExpression: r'e^{j\pi} + 1 = 0',
        createdAt: DateTime.now(),
      );

      await formulaRepo.addFormula(formula);
      await formulaRepo.deleteFormula('custom_f_2', permanent: false);

      expect(formulaRepo.formulas.any((f) => f.formulaId == 'custom_f_2'), isFalse);
      expect(storage.isItemHiddenLocally(testUserId, 'formulas', 'custom_f_2'), isTrue);

      final newRepo = FormulaRepository(storage);
      newRepo.loadForUser(testUserId);
      expect(newRepo.formulas.any((f) => f.formulaId == 'custom_f_2'), isFalse);
    });
  });
}
