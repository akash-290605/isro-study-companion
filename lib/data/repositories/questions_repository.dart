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
    // Purge any inbuilt/starter questions
    final beforeCount = _questions.length;
    _questions.removeWhere((q) =>
        q.questionId.startsWith('q_nt_') ||
        q.questionId.startsWith('q_de_') ||
        q.sourceId.startsWith('starter_doc_'));
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

  Future<void> clearAllQuestions() async {
    if (_currentUserId == null) return;
    _questions.clear();
    await _storage.saveQuestions(_currentUserId!, _questions);
    notifyListeners();
  }
}

