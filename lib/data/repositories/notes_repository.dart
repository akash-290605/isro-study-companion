import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/local_storage_service.dart';
import '../models/note_model.dart';
import '../models/sync_model.dart';

class NotesRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<NoteModel> _notes = [];
  String? _currentUserId;

  NotesRepository(this._storage);

  List<NoteModel> get notes => _notes;

  void loadForUser(String userId) {
    _currentUserId = userId;
    _notes = _storage.getNotes(userId);
    // Purge any inbuilt/starter notes
    final beforeCount = _notes.length;
    _notes.removeWhere((n) => n.noteId.startsWith('starter_note'));
    if (_notes.length != beforeCount) {
      _storage.saveNotes(userId, _notes);
    }
    notifyListeners();
  }

  List<NoteModel> searchNotes(String query) {
    if (query.trim().isEmpty) return _notes;
    final q = query.toLowerCase().trim();
    return _notes.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q) ||
          n.subject.toLowerCase().contains(q) ||
          n.topic.toLowerCase().contains(q) ||
          n.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  List<NoteModel> getNotesBySubject(String subject) {
    return _notes.where((n) => n.subject == subject).toList();
  }

  List<NoteModel> getNotesByTopic(String topic) {
    return _notes.where((n) => n.topic == topic).toList();
  }

  Future<void> saveNote(NoteModel note) async {
    if (_currentUserId == null) return;
    final index = _notes.indexWhere((n) => n.noteId == note.noteId);
    if (index >= 0) {
      _notes[index] = note.copyWith(updatedAt: DateTime.now());
    } else {
      _notes.insert(0, note);
    }

    await _storage.saveNotes(_currentUserId!, _notes);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: index >= 0 ? QueuedActionType.update : QueuedActionType.create,
        collectionName: 'notes',
        documentId: note.noteId,
        payload: note.toJson(),
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    if (_currentUserId == null) return;
    _notes.removeWhere((n) => n.noteId == noteId);
    await _storage.saveNotes(_currentUserId!, _notes);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.delete,
        collectionName: 'notes',
        documentId: noteId,
        payload: {},
        timestamp: DateTime.now(),
      ),
    );
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId!)
            .collection('notes')
            .doc(noteId)
            .delete();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> clearAllNotes() async {
    if (_currentUserId == null) return;
    _notes.clear();
    await _storage.saveNotes(_currentUserId!, _notes);
    notifyListeners();
  }
}

