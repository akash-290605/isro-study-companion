import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/local_storage_service.dart';
import '../models/flashcard_model.dart';
import '../models/sync_model.dart';

class FlashcardsRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<FlashcardModel> _cards = [];
  String? _currentUserId;

  FlashcardsRepository(this._storage);

  List<FlashcardModel> get cards => _cards;

  List<FlashcardModel> get dueCards {
    final now = DateTime.now();
    return _cards.where((c) => c.reviewDate.isBefore(now) || c.reviewDate.day == now.day).toList();
  }

  void loadForUser(String userId) {
    _currentUserId = userId;
    _cards = _storage.getFlashcards(userId);
    // Purge any inbuilt/starter flashcards
    final beforeCount = _cards.length;
    _cards.removeWhere((c) =>
        c.cardId.startsWith('fc_') ||
        c.sourceId.startsWith('starter_doc_'));
    if (_cards.length != beforeCount) {
      _storage.saveFlashcards(userId, _cards);
    }
    notifyListeners();
  }

  Future<void> addFlashcard(FlashcardModel card) async {
    if (_currentUserId == null) return;
    _cards.insert(0, card);
    await _storage.saveFlashcards(_currentUserId!, _cards);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.create,
        collectionName: 'flashcards',
        documentId: card.cardId,
        payload: card.toJson(),
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> answerCard(String cardId, bool knewAnswer) async {
    if (_currentUserId == null) return;
    final index = _cards.indexWhere((c) => c.cardId == cardId);
    if (index >= 0) {
      final card = _cards[index];
      final newInterval = knewAnswer ? (card.intervalDays * 2).clamp(1, 60) : 1;
      final newReviewDate = DateTime.now().add(Duration(days: newInterval));

      final updated = card.copyWith(
        intervalDays: newInterval,
        reviewDate: newReviewDate,
        repetitionCount: card.repetitionCount + 1,
      );

      _cards[index] = updated;
      await _storage.saveFlashcards(_currentUserId!, _cards);
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.update,
          collectionName: 'flashcards',
          documentId: cardId,
          payload: updated.toJson(),
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> deleteFlashcard(String cardId) async {
    if (_currentUserId == null) return;
    _cards.removeWhere((c) => c.cardId == cardId);
    await _storage.saveFlashcards(_currentUserId!, _cards);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.delete,
        collectionName: 'flashcards',
        documentId: cardId,
        payload: {},
        timestamp: DateTime.now(),
      ),
    );
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId!)
            .collection('flashcards')
            .doc(cardId)
            .delete();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> clearAllCards() async {
    if (_currentUserId == null) return;
    final toDelete = List<FlashcardModel>.from(_cards);
    _cards.clear();
    await _storage.saveFlashcards(_currentUserId!, _cards);
    for (final c in toDelete) {
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.delete,
          collectionName: 'flashcards',
          documentId: c.cardId,
          payload: {},
          timestamp: DateTime.now(),
        ),
      );
    }
    try {
      if (Firebase.apps.isNotEmpty) {
        final col = FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId!)
            .collection('flashcards');
        for (final c in toDelete) {
          col.doc(c.cardId).delete();
        }
      }
    } catch (_) {}
    notifyListeners();
  }
}

