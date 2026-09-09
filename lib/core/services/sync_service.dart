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

  void _initStatus() {
    bool hasFirebase = false;
    try {
      hasFirebase = Firebase.apps.isNotEmpty;
    } catch (_) {}

    if (hasFirebase) {
      try {
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

  Future<void> syncPendingData() async {
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
      // Local storage is operating completely normally
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

    // If not signed into Firebase cloud account, the app runs in Local Storage mode
    if (fbUser == null) {
      _setStatus(SyncStatus.localOnly);
      return;
    }

    final queue = _storage.getSyncQueue(fbUser.uid);
    if (queue.isEmpty) {
      if (_status != SyncStatus.synced) {
        _setStatus(SyncStatus.synced);
      }
      return;
    }

    _isProcessing = true;
    _setStatus(SyncStatus.syncing);

    try {
      final firestore = FirebaseFirestore.instance;
      for (final action in List<QueuedActionModel>.from(queue)) {
        final docRef = firestore
            .collection('users')
            .doc(fbUser.uid)
            .collection(action.collectionName)
            .doc(action.documentId);

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

      _setStatus(SyncStatus.synced);
    } catch (e) {
      if (kDebugMode) {
        print('Cloud sync error: $e');
      }
      // If Firestore failed during an authenticated cloud sync attempt
      _setStatus(SyncStatus.offline);
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

