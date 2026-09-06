import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../data/models/sync_model.dart';
import 'local_storage_service.dart';

class SyncService extends ChangeNotifier {
  final LocalStorageService _storage;
  SyncStatus _status = SyncStatus.synced;
  Timer? _syncTimer;
  bool _isProcessing = false;

  SyncService(this._storage) {
    _startPeriodicSync();
  }

  SyncStatus get status => _status;

  void _setStatus(SyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      syncPendingData();
    });
  }

  Future<void> syncPendingData() async {
    if (_isProcessing) return;
    final uid = _storage.getCurrentUserId();
    if (uid == null) return;

    final queue = _storage.getSyncQueue(uid);
    if (queue.isEmpty) {
      if (_status != SyncStatus.synced) {
        _setStatus(SyncStatus.synced);
      }
      return;
    }

    // Check if Firebase is available
    bool hasFirebase = false;
    try {
      if (Firebase.apps.isNotEmpty) {
        hasFirebase = true;
      }
    } catch (_) {
      hasFirebase = false;
    }

    if (!hasFirebase) {
      _setStatus(SyncStatus.offline);
      return;
    }

    _isProcessing = true;
    _setStatus(SyncStatus.syncing);

    try {
      final firestore = FirebaseFirestore.instance;
      for (final action in List<QueuedActionModel>.from(queue)) {
        final docRef = firestore
            .collection('users')
            .doc(uid)
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

        await _storage.removeQueuedAction(uid, action.actionId);
      }

      _setStatus(SyncStatus.synced);
    } catch (e) {
      // Network failed or offline
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

