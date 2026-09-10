import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../data/models/sync_model.dart';
import '../../data/models/formula_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/syllabus_model.dart';
import '../../data/models/flashcard_model.dart';
import '../../data/models/mistake_model.dart';
import '../../data/models/source_model.dart';
import '../../data/models/test_result_model.dart';
import '../../data/models/user_model.dart';
import 'local_storage_service.dart';

class SyncService extends ChangeNotifier {
  final LocalStorageService _storage;
  SyncStatus _status = SyncStatus.localOnly;
  Timer? _syncTimer;
  bool _isProcessing = false;

  /// Callback to notify active repositories when cloud data is restored
  void Function(String uid)? onDataRestored;

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

  /// Downloads and restores all collections for [uid] from Cloud Firestore into local storage.
  /// Seamlessly merges cloud data with local items so cross-browser access is instant.
  Future<void> restoreFromCloud(String uid) async {
    bool hasFirebase = false;
    try {
      hasFirebase = Firebase.apps.isNotEmpty;
    } catch (_) {
      hasFirebase = false;
    }
    if (!hasFirebase) {
      onDataRestored?.call(uid);
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = firestore.collection('users').doc(uid);

      final queue = _storage.getSyncQueue(uid);
      final pendingDeletes = queue
          .where((a) => a.actionType == QueuedActionType.delete)
          .map((a) => '${a.collectionName}/${a.documentId}')
          .toSet();

      bool shouldSkip(String collection, String id) {
        if (pendingDeletes.contains('$collection/$id')) return true;
        if (_storage.isItemHiddenLocally(uid, collection, id)) return true;
        return false;
      }

      // 1. User Profile
      try {
        final userSnapshot = await userDoc.get();
        if (userSnapshot.exists && userSnapshot.data() != null) {
          final cloudUser = UserModel.fromJson(userSnapshot.data()!);
          await _storage.saveUser(cloudUser);
        }
      } catch (e) {
        if (kDebugMode) print('Sync: error restoring user profile: $e');
      }

      // 2. Formulas
      try {
        final formulasSnap = await userDoc.collection('formulas').get();
        if (formulasSnap.docs.isNotEmpty) {
          final cloudFormulas = <FormulaModel>[];
          for (final doc in formulasSnap.docs) {
            if (shouldSkip('formulas', doc.id)) continue;
            try {
              cloudFormulas.add(FormulaModel.fromJson(doc.data()));
            } catch (e) {
              if (kDebugMode) print('Sync: error parsing formula: $e');
            }
          }
          final local = _storage.getFormulas(uid);
          final map = <String, FormulaModel>{};
          for (final f in cloudFormulas) {
            map[f.formulaId] = f;
          }
          for (final f in local) {
            map[f.formulaId] = f;
          }
          await _storage.saveFormulas(uid, map.values.toList());
        }
      } catch (e) {
        if (kDebugMode) print('Sync: error restoring formulas: $e');
      }

      // 3. Notes
      try {
        final notesSnap = await userDoc.collection('notes').get();
        if (notesSnap.docs.isNotEmpty) {
          final cloudNotes = <NoteModel>[];
          for (final doc in notesSnap.docs) {
            if (shouldSkip('notes', doc.id)) continue;
            try {
              cloudNotes.add(NoteModel.fromJson(doc.data()));
            } catch (e) {
              if (kDebugMode) print('Sync: error parsing note: $e');
            }
          }
          final local = _storage.getNotes(uid);
          final map = <String, NoteModel>{};
          for (final n in cloudNotes) {
            map[n.noteId] = n;
          }
          for (final n in local) {
            map[n.noteId] = n;
          }
          await _storage.saveNotes(uid, map.values.toList());
        }
      } catch (e) {
        if (kDebugMode) print('Sync: error restoring notes: $e');
      }

      // 4. Questions
      try {
        final questionsSnap = await userDoc.collection('questions').get();
        if (questionsSnap.docs.isNotEmpty) {
          final cloudQuestions = <QuestionModel>[];
          for (final doc in questionsSnap.docs) {
            if (shouldSkip('questions', doc.id)) continue;
            try {
              cloudQuestions.add(QuestionModel.fromJson(doc.data()));
            } catch (e) {
              if (kDebugMode) print('Sync: error parsing question: $e');
            }
          }
          final local = _storage.getQuestions(uid);
          final map = <String, QuestionModel>{};
          for (final q in cloudQuestions) {
            map[q.questionId] = q;
          }
          for (final q in local) {
            map[q.questionId] = q;
          }
          await _storage.saveQuestions(uid, map.values.toList());
        }
      } catch (e) {
        if (kDebugMode) print('Sync: error restoring questions: $e');
      }

      // 5. Syllabus
      try {
        final currentSyllabusDoc = await userDoc.collection('syllabus').doc('current_syllabus').get();
        if (currentSyllabusDoc.exists && currentSyllabusDoc.data() != null) {
          final subjectsJson = currentSyllabusDoc.data()!['subjects'] as List<dynamic>?;
          if (subjectsJson != null && subjectsJson.isNotEmpty) {
            final cloudSubjects = subjectsJson
                .map((s) => SyllabusSubject.fromJson(s as Map<String, dynamic>))
                .toList();
            await _storage.saveSyllabus(uid, cloudSubjects);
          }
        } else {
          final syllabusSnap = await userDoc.collection('syllabus').get();
          if (syllabusSnap.docs.isNotEmpty) {
            final cloudSubjects = <SyllabusSubject>[];
            for (final doc in syllabusSnap.docs) {
              if (doc.id == 'current_syllabus') continue;
              try {
                cloudSubjects.add(SyllabusSubject.fromJson(doc.data()));
              } catch (_) {}
            }
            if (cloudSubjects.isNotEmpty) {
              await _storage.saveSyllabus(uid, cloudSubjects);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('Sync: error restoring syllabus: $e');
      }

      // 6. Flashcards
      try {
        final flashcardsSnap = await userDoc.collection('flashcards').get();
        if (flashcardsSnap.docs.isNotEmpty) {
          final cloudFlashcards = <FlashcardModel>[];
          for (final doc in flashcardsSnap.docs) {
            if (shouldSkip('flashcards', doc.id)) continue;
            try {
              cloudFlashcards.add(FlashcardModel.fromJson(doc.data()));
            } catch (e) {
              if (kDebugMode) print('Sync: error parsing flashcard: $e');
            }
          }
          final local = _storage.getFlashcards(uid);
          final map = <String, FlashcardModel>{};
          for (final fc in cloudFlashcards) {
            map[fc.cardId] = fc;
          }
          for (final fc in local) {
            map[fc.cardId] = fc;
          }
          await _storage.saveFlashcards(uid, map.values.toList());
        }
      } catch (e) {
        if (kDebugMode) print('Sync: error restoring flashcards: $e');
      }

      // 7. Mistakes
      try {
        final mistakesSnap = await userDoc.collection('mistakes').get();
        if (mistakesSnap.docs.isNotEmpty) {
          final cloudMistakes = <MistakeModel>[];
          for (final doc in mistakesSnap.docs) {
            if (shouldSkip('mistakes', doc.id)) continue;
            try {
              cloudMistakes.add(MistakeModel.fromJson(doc.data()));
            } catch (e) {
              if (kDebugMode) print('Sync: error parsing mistake: $e');
            }
          }
          final local = _storage.getMistakes(uid);
          final map = <String, MistakeModel>{};
          for (final m in cloudMistakes) {
            map[m.mistakeId] = m;
          }
          for (final m in local) {
            map[m.mistakeId] = m;
          }
          await _storage.saveMistakes(uid, map.values.toList());
        }
      } catch (e) {
        if (kDebugMode) print('Sync: error restoring mistakes: $e');
      }

      // 8. Sources
      try {
        final sourcesSnap = await userDoc.collection('sources').get();
        if (sourcesSnap.docs.isNotEmpty) {
          final cloudSources = <SourceDocumentModel>[];
          for (final doc in sourcesSnap.docs) {
            if (shouldSkip('sources', doc.id)) continue;
            try {
              cloudSources.add(SourceDocumentModel.fromJson(doc.data()));
            } catch (e) {
              if (kDebugMode) print('Sync: error parsing source: $e');
            }
          }
          final local = _storage.getSources(uid);
          final map = <String, SourceDocumentModel>{};
          for (final s in cloudSources) {
            map[s.sourceId] = s;
          }
          for (final s in local) {
            map[s.sourceId] = s;
          }
          await _storage.saveSources(uid, map.values.toList());
        }
      } catch (e) {
        if (kDebugMode) print('Sync: error restoring sources: $e');
      }

      // 9. Test Results
      try {
        final testsSnap = await userDoc.collection('test_results').get();
        if (testsSnap.docs.isNotEmpty) {
          final cloudTests = <TestResultModel>[];
          for (final doc in testsSnap.docs) {
            try {
              cloudTests.add(TestResultModel.fromJson(doc.data()));
            } catch (e) {
              if (kDebugMode) print('Sync: error parsing test result: $e');
            }
          }
          final local = _storage.getTestResults(uid);
          final map = <String, TestResultModel>{};
          for (final t in cloudTests) {
            map[t.resultId] = t;
          }
          for (final t in local) {
            map[t.resultId] = t;
          }
          await _storage.saveTestResults(uid, map.values.toList());
        }
      } catch (e) {
        if (kDebugMode) print('Sync: error restoring test results: $e');
      }

      onDataRestored?.call(uid);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Sync: cloud restore failed: $e');
    }
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

  /// Two-way sync: Downloads cloud changes first, then uploads local changes
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

    _isProcessing = true;
    _setStatus(SyncStatus.syncing);

    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = firestore.collection('users').doc(fbUser.uid);

      // 1. Process outgoing queued actions FIRST (including deletes) so Firestore is up-to-date
      final queue = _storage.getSyncQueue(fbUser.uid);
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

      // 2. Download latest from Cloud Firestore
      await restoreFromCloud(fbUser.uid);

      // 3. If full backup requested, push any local items to Firestore
      if (forceFullBackup) {
        await fullUploadAllCollections(fbUser.uid);
      }

      onDataRestored?.call(fbUser.uid);
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
