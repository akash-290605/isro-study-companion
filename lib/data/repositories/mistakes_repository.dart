import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/local_storage_service.dart';
import '../models/mistake_model.dart';
import '../models/test_model.dart';
import '../models/sync_model.dart';

class MistakesRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<MistakeModel> _mistakes = [];
  String? _currentUserId;

  MistakesRepository(this._storage);

  List<MistakeModel> get mistakes => _mistakes;
  int get unresolvedCount => _mistakes.where((m) => !m.isResolved).length;

  void loadForUser(String userId) {
    _currentUserId = userId;
    _mistakes = _storage.getMistakes(userId);
    notifyListeners();
  }

  Future<void> ingestTestMistakes({
    required String testId,
    required List<TestQuestionModel> questions,
  }) async {
    if (_currentUserId == null) return;

    for (final q in questions) {
      if (q.isCorrect == false && q.userAnswer != null && q.userAnswer!.trim().isNotEmpty) {
        // Prevent duplicate mistake for same question from same test
        final existing = _mistakes.any((m) => m.testId == testId && m.questionId == q.questionId);
        if (!existing) {
          final mistake = MistakeModel(
            mistakeId: const Uuid().v4(),
            userId: _currentUserId!,
            questionId: q.questionId,
            questionText: q.questionText,
            options: q.options,
            userAnswer: q.userAnswer ?? '',
            correctAnswer: q.correctAnswer,
            solution: q.solution,
            subject: q.subject,
            topic: q.topic,
            difficulty: q.difficulty,
            sourceId: q.sourceId,
            sourceName: q.sourceName,
            sourceLocation: q.sourceLocation,
            testId: testId,
            testDate: DateTime.now(),
            dateAdded: DateTime.now(),
          );
          _mistakes.insert(0, mistake);
        }
      }
    }

    await _storage.saveMistakes(_currentUserId!, _mistakes);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.update,
        collectionName: 'mistakes',
        documentId: 'bulk_test_$testId',
        payload: {'updatedAt': DateTime.now().toIso8601String()},
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> toggleResolved(String mistakeId) async {
    if (_currentUserId == null) return;
    final index = _mistakes.indexWhere((m) => m.mistakeId == mistakeId);
    if (index >= 0) {
      final updated = _mistakes[index].copyWith(
        isResolved: !_mistakes[index].isResolved,
      );
      _mistakes[index] = updated;
      await _storage.saveMistakes(_currentUserId!, _mistakes);
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.update,
          collectionName: 'mistakes',
          documentId: mistakeId,
          payload: {'isResolved': updated.isResolved},
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> updateNotes(String mistakeId, String notes) async {
    if (_currentUserId == null) return;
    final index = _mistakes.indexWhere((m) => m.mistakeId == mistakeId);
    if (index >= 0) {
      final updated = _mistakes[index].copyWith(userNotes: notes.trim());
      _mistakes[index] = updated;
      await _storage.saveMistakes(_currentUserId!, _mistakes);
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.update,
          collectionName: 'mistakes',
          documentId: mistakeId,
          payload: {'userNotes': updated.userNotes},
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> deleteMistake(String mistakeId) async {
    if (_currentUserId == null) return;
    _mistakes.removeWhere((m) => m.mistakeId == mistakeId);
    await _storage.saveMistakes(_currentUserId!, _mistakes);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.delete,
        collectionName: 'mistakes',
        documentId: mistakeId,
        payload: {},
        timestamp: DateTime.now(),
      ),
    );
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId!)
            .collection('mistakes')
            .doc(mistakeId)
            .delete();
      }
    } catch (_) {}
    notifyListeners();
  }
}

