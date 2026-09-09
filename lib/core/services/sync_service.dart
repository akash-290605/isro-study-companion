import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../data/models/sync_model.dart';
import 'local_storage_service.dart';

class SyncService extends ChangeNotifier {
  final LocalStorageService _storage;
  SyncStatus _status = SyncStatus.localOnly;
  Timer? _syncTimer;
  bool _isProcessing = false;

  SyncService(this._storage) {
    _initStatus();
    _startPeriodicSync();
  }

  SyncStatus get status => _status;

  void _setStatus(SyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  StreamSubscription<User?>? _authSubscription;

  void _initStatus() {
    bool hasFirebase = false;
    try {
      hasFirebase = Firebase.apps.isNotEmpty;
    } catch (_) {}

    if (hasFirebase) {
      try {
        _authSubscription = FirebaseAuth.instance.authStateChanges().listen((fbUser) {
          if (fbUser != null) {
            _setStatus(SyncStatus.synced);
            syncPendingData(forceFullBackup: true);
          } else {
            _setStatus(SyncStatus.localOnly);
          }
        });

        if (FirebaseAuth.instance.currentUser != null) {
          _status = SyncStatus.synced;
          return;
        }
      } catch (_) {}
    }
    _status = SyncStatus.localOnly;
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      syncPendingData();
    });
  }

  /// Uploads all local collections for [uid] to Cloud Firestore
  Future<void> fullUploadAllCollections(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final userDoc = firestore.collection('users').doc(uid);

    // 1. User profile
    final user = _storage.getUser(uid);
    if (user != null) {
      await userDoc.set(user.toJson(), SetOptions(merge: true));
    }

    // 2. Formulas
    final formulas = _storage.getFormulas(uid);
    for (final f in formulas) {
      await userDoc.collection('formulas').doc(f.formulaId).set(f.toJson(), SetOptions(merge: true));
    }

    // 3. Notes
    final notes = _storage.getNotes(uid);
    for (final n in notes) {
      await userDoc.collection('notes').doc(n.noteId).set(n.toJson(), SetOptions(merge: true));
    }

    // 4. Questions
    final questions = _storage.getQuestions(uid);
    for (final q in questions) {
      await userDoc.collection('questions').doc(q.questionId).set(q.toJson(), SetOptions(merge: true));
    }

    // 5. Syllabus
    final syllabus = _storage.getSyllabus(uid);
    if (syllabus.isNotEmpty) {
      await userDoc.collection('syllabus').doc('current_syllabus').set({
        'updatedAt': DateTime.now().toIso8601String(),
        'subjects': syllabus.map((s) => s.toJson()).toList(),
      }, SetOptions(merge: true));
    }

    // 6. Flashcards
    final flashcards = _storage.getFlashcards(uid);
    for (final fc in flashcards) {
      await userDoc.collection('flashcards').doc(fc.cardId).set(fc.toJson(), SetOptions(merge: true));
    }

    // 7. Mistakes
    final mistakes = _storage.getMistakes(uid);
    for (final m in mistakes) {
      await userDoc.collection('mistakes').doc(m.mistakeId).set(m.toJson(), SetOptions(merge: true));
    }

    // 8. Sources
    final sources = _storage.getSources(uid);
    for (final src in sources) {
      await userDoc.collection('sources').doc(src.sourceId).set(src.toJson(), SetOptions(merge: true));
    }

    // 9. Test Results
    final testResults = _storage.getTestResults(uid);
    for (final tr in testResults) {
      await userDoc.collection('test_results').doc(tr.resultId).set(tr.toJson(), SetOptions(merge: true));
    }
  }

  Future<void> syncPendingData({bool forceFullBackup = false}) async {
    if (_isProcessing) return;
    final uid = _storage.getCurrentUserId();
    if (uid == null) {
      _setStatus(SyncStatus.localOnly);
      return;
    }

    // Check if Firebase is available
    bool hasFirebase = false;
    try {
      hasFirebase = Firebase.apps.isNotEmpty;
    } catch (_) {
      hasFirebase = false;
    }

    if (!hasFirebase) {
      _setStatus(SyncStatus.localOnly);
      return;
    }

    // Check if user is signed in with Firebase cloud auth
    User? fbUser;
    try {
      fbUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      fbUser = null;
    }

    if (fbUser == null) {
      _setStatus(SyncStatus.localOnly);
      return;
    }

    final queue = _storage.getSyncQueue(fbUser.uid);
    if (queue.isEmpty && !forceFullBackup) {
      if (_status != SyncStatus.synced) {
        _setStatus(SyncStatus.synced);
      }
      return;
    }

    _isProcessing = true;
    _setStatus(SyncStatus.syncing);

    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = firestore.collection('users').doc(fbUser.uid);

      // Process queued actions
      for (final action in List<QueuedActionModel>.from(queue)) {
        final docRef = userDoc.collection(action.collectionName).doc(action.documentId);

        switch (action.actionType) {
          case QueuedActionType.create:
          case QueuedActionType.update:
            await docRef.set(action.payload, SetOptions(merge: true));
            break;
          case QueuedActionType.delete:
            await docRef.delete();
            break;
        }

        await _storage.removeQueuedAction(fbUser.uid, action.actionId);
      }

      // If full backup requested or queue had items, ensure entire collection snapshot is up to date
      if (forceFullBackup) {
        await fullUploadAllCollections(fbUser.uid);
      }

      _setStatus(SyncStatus.synced);
    } catch (e) {
      if (kDebugMode) {
        print('Cloud sync error: $e');
      }
      _setStatus(SyncStatus.offline);
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}

