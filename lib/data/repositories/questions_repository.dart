import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/local_storage_service.dart';
import '../models/question_model.dart';
import '../models/sync_model.dart';

class QuestionsRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<QuestionModel> _questions = [];
  String? _currentUserId;

  QuestionsRepository(this._storage);

  List<QuestionModel> get questions => _questions;

  void loadForUser(String userId) {
    _currentUserId = userId;
    _questions = _storage.getQuestions(userId);
    if (_questions.isEmpty) {
      // Seed initial verified source-grounded questions
      _questions = [
        QuestionModel(
          questionId: 'q_nt_01',
          userId: userId,
          questionText:
              'In a planar circuit with 8 branches and 5 nodes, how many independent mesh equations are required for Mesh Analysis?',
          options: ['3', '4', '5', '8'],
          correctAnswer: '4',
          solution:
              'According to Mesh Analysis rules, the number of independent mesh equations required is b - n + 1. Here b = 8 and n = 5, so 8 - 5 + 1 = 4.',
          subject: 'Network Theory',
          topic: 'Network Analysis',
          subtopic: 'KCL, KVL & Node/Mesh Analysis',
          difficulty: Difficulty.easy,
          sourceId: 'starter_doc_network_theory',
          sourceName: 'Network Theory Notes.pdf',
          sourceLocation: 'Page 1, Mesh Analysis and Nodal Analysis',
          sourceChunk:
              'The number of independent mesh equations required is given by b - n + 1, where b is the number of branches and n is the number of nodes.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        QuestionModel(
          questionId: 'q_nt_02',
          userId: userId,
          questionText:
              'Under the Maximum Power Transfer Theorem for purely resistive linear networks, what is the maximum possible theoretical efficiency?',
          options: ['25%', '50%', '75%', '100%'],
          correctAnswer: '50%',
          solution:
              'When load resistance RL equals internal Thevenin resistance Rth, half of the total generated power is dissipated in Rth and half in RL, giving exactly 50% efficiency.',
          subject: 'Network Theory',
          topic: 'Network Analysis',
          subtopic: 'Thevenin, Norton, Superposition & Max Power',
          difficulty: Difficulty.medium,
          sourceId: 'starter_doc_network_theory',
          sourceName: 'Network Theory Notes.pdf',
          sourceLocation: 'Page 2, Thevenin and Norton Equivalents',
          sourceChunk:
              'Maximum efficiency under maximum power transfer condition is exactly 50%.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        QuestionModel(
          questionId: 'q_nt_03',
          userId: userId,
          questionText:
              'To determine Thevenin resistance (Rth) looking into a linear network, how must independent voltage and current sources be treated?',
          options: [
            'Voltage sources shorted, current sources opened',
            'Voltage sources opened, current sources shorted',
            'Both voltage and current sources shorted',
            'Both voltage and current sources opened',
          ],
          correctAnswer: 'Voltage sources shorted, current sources opened',
          solution:
              'Independent sources are deactivated by zeroing their value: zero volts means a short circuit, and zero amperes means an open circuit.',
          subject: 'Network Theory',
          topic: 'Network Analysis',
          subtopic: 'Thevenin, Norton, Superposition & Max Power',
          difficulty: Difficulty.easy,
          sourceId: 'starter_doc_network_theory',
          sourceName: 'Network Theory Notes.pdf',
          sourceLocation: 'Page 2, Thevenin and Norton Equivalents',
          sourceChunk:
              'Rth is the input impedance looking into the terminals with all independent sources turned off (voltage sources shorted, current sources opened).',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        QuestionModel(
          questionId: 'q_de_01',
          userId: userId,
          questionText:
              'Why are NAND and NOR gates termed universal logic gates?',
          options: [
            'They operate with the lowest propagation delay',
            'Any Boolean function can be realized using only NAND or only NOR gates',
            'They consume the least static power dissipation in CMOS technology',
            'They can be used without pull-up resistors',
          ],
          correctAnswer:
              'Any Boolean function can be realized using only NAND or only NOR gates',
          solution:
              'Universal realization allows implementing NOT, AND, and OR operations entirely using NAND or NOR logic without additional gates.',
          subject: 'Digital Electronics',
          topic: 'Boolean Algebra & Combinational Circuits',
          subtopic: 'K-Maps & Logic Gate Minimization',
          difficulty: Difficulty.easy,
          sourceId: 'starter_doc_digital_electronics',
          sourceName: 'Digital Electronics Principles.doc',
          sourceLocation: 'Page 1, Logic Gates & Universal Realization',
          sourceChunk:
              'NAND and NOR gates are universal gates because any Boolean function can be realized using only NAND or only NOR gates.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        QuestionModel(
          questionId: 'q_de_02',
          userId: userId,
          questionText:
              'Under what condition does a race-around condition occur in a level-triggered JK flip-flop?',
          options: [
            'J = 0, K = 1 and clock pulse duration tp < propagation delay Δt',
            'J = 1, K = 0 and clock pulse duration tp > propagation delay Δt',
            'J = 1, K = 1 and clock pulse duration tp > propagation delay Δt',
            'J = 0, K = 0 with high clock frequency',
          ],
          correctAnswer:
              'J = 1, K = 1 and clock pulse duration tp > propagation delay Δt',
          solution:
              'When J=K=1, the output toggles repeatedly while the clock is high if the clock pulse width exceeds the flip-flop propagation delay. Master-Slave JK or edge-triggering prevents this.',
          subject: 'Digital Electronics',
          topic: 'Boolean Algebra & Combinational Circuits',
          subtopic: 'Sequential Circuits & Finite State Machines',
          difficulty: Difficulty.hard,
          sourceId: 'starter_doc_digital_electronics',
          sourceName: 'Digital Electronics Principles.doc',
          sourceLocation: 'Page 2, Flip-Flops and Counters',
          sourceChunk:
              'Race-around condition occurs in level-triggered JK flip-flops when clock pulse duration tp is greater than propagation delay of the flip-flop Δt, and J = K = 1.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        QuestionModel(
          questionId: 'q_de_03',
          userId: userId,
          questionText:
              'How many flip-flops are minimally required to construct a Mod-12 counter?',
          options: ['3', '4', '6', '12'],
          correctAnswer: '4',
          solution:
              'For a Mod-N counter, 2^(n-1) <= N <= 2^n. For N = 12, 2^3 = 8 < 12 <= 2^4 = 16. Therefore, n = 4 flip-flops.',
          subject: 'Digital Electronics',
          topic: 'Boolean Algebra & Combinational Circuits',
          subtopic: 'Sequential Circuits & Finite State Machines',
          difficulty: Difficulty.medium,
          sourceId: 'starter_doc_digital_electronics',
          sourceName: 'Digital Electronics Principles.doc',
          sourceLocation: 'Page 2, Flip-Flops and Counters',
          sourceChunk:
              'A Mod-N counter requires n flip-flops where 2^(n-1) <= N <= 2^n.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      _storage.saveQuestions(userId, _questions);
    }
    notifyListeners();
  }

  List<QuestionModel> filterQuestions({
    String? subject,
    String? topic,
    Difficulty? difficulty,
    String? sourceId,
    bool? isAttempted,
    bool? isCorrect,
    String? searchQuery,
  }) {
    return _questions.where((q) {
      if (subject != null && subject.isNotEmpty && q.subject != subject) return false;
      if (topic != null && topic.isNotEmpty && q.topic != topic) return false;
      if (difficulty != null && q.difficulty != difficulty) return false;
      if (sourceId != null && sourceId.isNotEmpty && q.sourceId != sourceId) return false;
      if (isAttempted != null && q.isAttempted != isAttempted) return false;
      if (isCorrect != null && q.isLastAttemptCorrect != isCorrect) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final match = q.questionText.toLowerCase().contains(query) ||
            q.subject.toLowerCase().contains(query) ||
            q.topic.toLowerCase().contains(query) ||
            q.sourceName.toLowerCase().contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  Future<void> addQuestion(QuestionModel question) async {
    if (_currentUserId == null) return;
    _questions.insert(0, question);
    await _storage.saveQuestions(_currentUserId!, _questions);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.create,
        collectionName: 'questions',
        documentId: question.questionId,
        payload: question.toJson(),
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> updateQuestionAttempt(String questionId, bool isCorrect) async {
    if (_currentUserId == null) return;
    final index = _questions.indexWhere((q) => q.questionId == questionId);
    if (index >= 0) {
      _questions[index] = _questions[index].copyWith(
        isAttempted: true,
        isLastAttemptCorrect: isCorrect,
      );
      await _storage.saveQuestions(_currentUserId!, _questions);
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    if (_currentUserId == null) return;
    _questions.removeWhere((q) => q.questionId == questionId);
    await _storage.saveQuestions(_currentUserId!, _questions);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.delete,
        collectionName: 'questions',
        documentId: questionId,
        payload: {},
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}

