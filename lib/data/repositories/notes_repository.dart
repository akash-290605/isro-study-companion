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
    if (_notes.isEmpty) {
      // Starter notes for Network Theory & Digital Electronics
      _notes = [
        NoteModel(
          noteId: 'starter_note_1',
          userId: userId,
          title: 'Kirchhoff\'s Laws & Mesh Analysis',
          content:
              r'''Kirchhoff's Current Law (KCL):
The algebraic sum of currents entering a node is zero.
$$\sum_{k=1}^n I_k = 0$$

Kirchhoff's Voltage Law (KVL):
The directed sum of potential differences around any closed loop is zero.
$$\sum_{k=1}^n V_k = 0$$

Mesh Analysis is applicable only for planar circuits using KVL equations.''',
          subject: 'Network Theory',
          topic: 'Network Analysis',
          subtopic: 'KCL, KVL & Node/Mesh Analysis',
          tags: ['kcl', 'kvl', 'mesh', 'circuits'],
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        NoteModel(
          noteId: 'starter_note_2',
          userId: userId,
          title: 'Boolean Algebra & De Morgan\'s Theorems',
          content:
              r'''De Morgan's First Theorem:
$$(A + B)' = A' \cdot B'$$

De Morgan's Second Theorem:
$$(A \cdot B)' = A' + B'$$

Universal Gates: NAND and NOR can realize any Boolean function without using other gate types.''',
          subject: 'Digital Electronics',
          topic: 'Boolean Algebra & Combinational Circuits',
          subtopic: 'K-Maps & Logic Gate Minimization',
          tags: ['boolean', 'demorgan', 'digital', 'gates'],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
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
    notifyListeners();
  }
}

