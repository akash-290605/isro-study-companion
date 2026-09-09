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

  int get totalCount => _questions.length;
  int get solvedCount => _questions.where((q) => q.status == QuestionStatus.solved || (q.isAttempted && (q.isLastAttemptCorrect ?? false))).length;
  int get unsolvedCount => _questions.where((q) => q.status == QuestionStatus.unsolved && !q.isAttempted).length;
  int get needsReviewCount => _questions.where((q) => q.status == QuestionStatus.needsReview || q.verificationStatus == VerificationStatus.needsReview).length;
  int get partiallySolvedCount => _questions.where((q) => q.status == QuestionStatus.partiallySolved).length;

  /// Identifies corrupted or raw document byte data incorrectly saved as a question
  static bool isCorruptedQuestion(QuestionModel q) {
    final text = q.questionText.trim();
    if (text.startsWith('%PDF') || text.startsWith('PDF-')) return true;
    if (text.contains('1 0 obj') && text.contains('endobj')) return true;
    if (text.contains('<< /Type') || text.contains('<</Type') || text.contains('/Catalog')) return true;
    if (text.contains('/Kids[') || text.contains('/MediaBox[')) return true;
    if (text.length > 3000 && text.contains('obj') && text.contains('endobj')) return true;
    if (text.length > 10000 && q.options.isEmpty) return true;
    return false;
  }

  void loadForUser(String userId) {
    _currentUserId = userId;
    _questions = _storage.getQuestions(userId);
    // Purge any inbuilt/starter questions
    // Purge any inbuilt/starter questions and any corrupted document dumps
    final beforeCount = _questions.length;
    _questions.removeWhere((q) =>
        q.questionId.startsWith('q_nt_') ||
        q.questionId.startsWith('q_de_') ||
        q.sourceId.startsWith('starter_doc_'));
        q.sourceId.startsWith('starter_doc_') ||
        isCorruptedQuestion(q));
    if (_questions.length != beforeCount) {
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
    QuestionStatus? status,
    QuestionType? questionType,
    VerificationStatus? verificationStatus,
  }) {
    return _questions.where((q) {
      if (isCorruptedQuestion(q)) return false;
      if (subject != null && subject.isNotEmpty && q.subject != subject) return false;
      if (topic != null && topic.isNotEmpty && q.topic != topic) return false;
      if (difficulty != null && q.difficulty != difficulty) return false;
      if (sourceId != null && sourceId.isNotEmpty && q.sourceId != sourceId) return false;
      if (isAttempted != null && q.isAttempted != isAttempted) return false;
      if (isCorrect != null && q.isLastAttemptCorrect != isCorrect) return false;
      if (status != null && q.status != status) return false;
      if (questionType != null && q.questionType != questionType) return false;
      if (verificationStatus != null && q.verificationStatus != verificationStatus) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final match = q.questionText.toLowerCase().contains(query) ||
            q.subject.toLowerCase().contains(query) ||
            q.topic.toLowerCase().contains(query) ||
            q.sourceName.toLowerCase().contains(query) ||
            q.tags.any((t) => t.toLowerCase().contains(query));
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  Future<void> addQuestion(QuestionModel question) async {
    if (_currentUserId == null) return;
    if (_currentUserId == null || isCorruptedQuestion(question)) return;
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

  Future<void> addQuestions(List<QuestionModel> newQuestions) async {
    if (_currentUserId == null || newQuestions.isEmpty) return;
    _questions.insertAll(0, newQuestions);
    final validQuestions = newQuestions.where((q) => !isCorruptedQuestion(q)).toList();
    if (validQuestions.isEmpty) return;
    _questions.insertAll(0, validQuestions);
    await _storage.saveQuestions(_currentUserId!, _questions);
    for (final q in newQuestions) {
    for (final q in validQuestions) {
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.create,
          collectionName: 'questions',
          documentId: q.questionId,
          payload: q.toJson(),
          timestamp: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  Future<void> saveQuestion(QuestionModel question) async {
    if (_currentUserId == null) return;
    final index = _questions.indexWhere((q) => q.questionId == question.questionId);
    if (index >= 0) {
      _questions[index] = question;
      await _storage.saveQuestions(_currentUserId!, _questions);
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.update,
          collectionName: 'questions',
          documentId: question.questionId,
          payload: question.toJson(),
          timestamp: DateTime.now(),
        ),
      );
    } else {
      await addQuestion(question);
      return;
    }
    notifyListeners();
  }

  Future<void> updateQuestionStatus(String questionId, QuestionStatus status) async {
    if (_currentUserId == null) return;
    final index = _questions.indexWhere((q) => q.questionId == questionId);
    if (index >= 0) {
      final updated = _questions[index].copyWith(
        status: status,
        isAttempted: status == QuestionStatus.solved || status == QuestionStatus.attempted || status == QuestionStatus.partiallySolved,
        isLastAttemptCorrect: status == QuestionStatus.solved,
      );
      _questions[index] = updated;
      await _storage.saveQuestions(_currentUserId!, _questions);
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.update,
          collectionName: 'questions',
          documentId: questionId,
          payload: updated.toJson(),
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> updateUserNotes(String questionId, String notes) async {
    if (_currentUserId == null) return;
    final index = _questions.indexWhere((q) => q.questionId == questionId);
    if (index >= 0) {
      final updated = _questions[index].copyWith(userNotes: notes);
      _questions[index] = updated;
      await _storage.saveQuestions(_currentUserId!, _questions);
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.update,
          collectionName: 'questions',
          documentId: questionId,
          payload: updated.toJson(),
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> recordDetailedAttempt(
    String questionId,
    bool isCorrect, {
    DateTime? attemptedAt,
  }) async {
    if (_currentUserId == null) return;
    final index = _questions.indexWhere((q) => q.questionId == questionId);
    if (index >= 0) {
      final q = _questions[index];
      final newAttemptCount = q.attemptCount + 1;
      final newCorrect = isCorrect ? q.correctAttempts + 1 : q.correctAttempts;
      final newIncorrect = !isCorrect ? q.incorrectAttempts + 1 : q.incorrectAttempts;
      final QuestionStatus newStatus = isCorrect
          ? QuestionStatus.solved
          : (q.status == QuestionStatus.solved ? QuestionStatus.partiallySolved : QuestionStatus.attempted);

      final updated = q.copyWith(
        isAttempted: true,
        isLastAttemptCorrect: isCorrect,
        attemptCount: newAttemptCount,
        correctAttempts: newCorrect,
        incorrectAttempts: newIncorrect,
        status: newStatus,
        lastAttemptedAt: attemptedAt ?? DateTime.now(),
      );
      _questions[index] = updated;
      await _storage.saveQuestions(_currentUserId!, _questions);
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.update,
          collectionName: 'questions',
          documentId: questionId,
          payload: updated.toJson(),
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> updateQuestionAttempt(String questionId, bool isCorrect) async {
    await recordDetailedAttempt(questionId, isCorrect);
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

  Future<void> clearAllQuestions() async {
    if (_currentUserId == null) return;
    _questions.clear();
    await _storage.saveQuestions(_currentUserId!, _questions);
    notifyListeners();
  }
}
