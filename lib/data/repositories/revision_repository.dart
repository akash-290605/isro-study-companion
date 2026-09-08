import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/local_storage_service.dart';
import '../models/revision_model.dart';
import '../models/sync_model.dart';

class RevisionRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<RevisionSessionModel> _revisions = [];
  String? _currentUserId;

  RevisionRepository(this._storage);

  List<RevisionSessionModel> get revisions => _revisions;

  void loadForUser(String userId) {
    _currentUserId = userId;
    _revisions = _storage.getRevisions(userId);
    // Purge any inbuilt/starter revision sessions
    final beforeCount = _revisions.length;
    _revisions.removeWhere((r) => r.sessionId.startsWith('rev_'));
    if (_revisions.length != beforeCount) {
      _storage.saveRevisions(userId, _revisions);
    }
    notifyListeners();
  }

  Future<RevisionSessionModel> generateSmartRevision({
    required List<String> weakTopics,
    required List<String> mistakeIds,
    required List<String> dueFlashcardIds,
  }) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final session = RevisionSessionModel(
      sessionId: const Uuid().v4(),
      userId: _currentUserId!,
      title: 'Revision Session (${DateTime.now().day}/${DateTime.now().month})',
      topicsDue: weakTopics,
      mistakesToReview: mistakeIds,
      flashcardsDue: dueFlashcardIds,
      scheduledDate: DateTime.now(),
    );

    _revisions.insert(0, session);
    await _storage.saveRevisions(_currentUserId!, _revisions);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.create,
        collectionName: 'revisionSessions',
        documentId: session.sessionId,
        payload: session.toJson(),
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
    return session;
  }

  Future<void> markCompleted(String sessionId) async {
    if (_currentUserId == null) return;
    final index = _revisions.indexWhere((r) => r.sessionId == sessionId);
    if (index >= 0) {
      final updated = _revisions[index].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      _revisions[index] = updated;
      await _storage.saveRevisions(_currentUserId!, _revisions);
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.update,
          collectionName: 'revisionSessions',
          documentId: sessionId,
          payload: {'isCompleted': true, 'completedAt': DateTime.now().toIso8601String()},
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> clearAllRevisions() async {
    if (_currentUserId == null) return;
    _revisions.clear();
    await _storage.saveRevisions(_currentUserId!, _revisions);
    notifyListeners();
  }
}

