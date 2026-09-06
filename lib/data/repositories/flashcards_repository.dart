import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/local_storage_service.dart';
import '../models/flashcard_model.dart';
import '../models/question_model.dart';
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
    if (_cards.isEmpty) {
      _cards = [
        FlashcardModel(
          cardId: 'fc_01',
          userId: userId,
          sourceId: 'starter_doc_network_theory',
          sourceName: 'Network Theory Notes.pdf',
          sourceLocation: 'Page 1, Mesh Analysis and Nodal Analysis',
          sourceChunk:
              'The number of independent mesh equations required is given by b - n + 1, where b is the number of branches and n is the number of nodes.',
          subject: 'Network Theory',
          topic: 'Network Analysis',
          question: 'How do you calculate the number of independent mesh equations in planar circuit analysis?',
          answer: 'According to the study material ("Network Theory Notes.pdf", Page 1):\nNumber of mesh equations = b - n + 1, where b = branches and n = nodes.',
          difficulty: Difficulty.easy,
          reviewDate: DateTime.now(),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        FlashcardModel(
          cardId: 'fc_02',
          userId: userId,
          sourceId: 'starter_doc_digital_electronics',
          sourceName: 'Digital Electronics Principles.doc',
          sourceLocation: 'Page 1, Logic Gates & Universal Realization',
          sourceChunk:
              'NAND and NOR gates are universal gates because any Boolean function can be realized using only NAND or only NOR gates.',
          subject: 'Digital Electronics',
          topic: 'Boolean Algebra & Combinational Circuits',
          question: 'Why are NAND and NOR classified as universal logic gates?',
          answer: 'According to "Digital Electronics Principles.doc" (Page 1):\nAny Boolean function can be completely realized using only NAND gates or only NOR gates without additional gates.',
          difficulty: Difficulty.easy,
          reviewDate: DateTime.now(),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
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
    notifyListeners();
  }
}

