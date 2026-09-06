import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/starter_syllabus.dart';
import '../../core/services/local_storage_service.dart';
import '../models/syllabus_model.dart';
import '../models/sync_model.dart';

class SyllabusRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<SyllabusSubject> _subjects = [];
  String? _currentUserId;

  SyllabusRepository(this._storage);

  List<SyllabusSubject> get subjects => _subjects;

  void loadForUser(String userId) {
    _currentUserId = userId;
    final saved = _storage.getSyllabus(userId);
    if (saved.isEmpty) {
      // Preload with Starter ECE Syllabus
      _subjects = List<SyllabusSubject>.from(starterEceSyllabus);
      _storage.saveSyllabus(userId, _subjects);
    } else {
      _subjects = saved;
    }
    notifyListeners();
  }

  double get overallProgressPercentage {
    if (_subjects.isEmpty) return 0.0;
    double total = 0.0;
    for (final s in _subjects) {
      total += s.completionPercentage;
    }
    return total / _subjects.length;
  }

  Future<void> updateSubjectStatus(String subjectId, SyllabusStatus status) async {
    if (_currentUserId == null) return;
    _subjects = _subjects.map((s) {
      if (s.id == subjectId) {
        return s.copyWith(status: status);
      }
      return s;
    }).toList();

    await _persistAndEnqueue('subject_update', subjectId);
    notifyListeners();
  }

  Future<void> updateTopicStatus(String subjectId, String topicId, SyllabusStatus status) async {
    if (_currentUserId == null) return;
    _subjects = _subjects.map((s) {
      if (s.id == subjectId) {
        final updatedTopics = s.topics.map((t) {
          if (t.id == topicId) {
            return t.copyWith(status: status);
          }
          return t;
        }).toList();
        return s.copyWith(topics: updatedTopics);
      }
      return s;
    }).toList();

    await _persistAndEnqueue('topic_update', topicId);
    notifyListeners();
  }

  Future<void> updateSubtopicStatus(
    String subjectId,
    String topicId,
    String subtopicId,
    SyllabusStatus status,
  ) async {
    if (_currentUserId == null) return;
    _subjects = _subjects.map((s) {
      if (s.id == subjectId) {
        final updatedTopics = s.topics.map((t) {
          if (t.id == topicId) {
            final updatedSubtopics = t.subtopics.map((st) {
              if (st.id == subtopicId) {
                return st.copyWith(status: status);
              }
              return st;
            }).toList();
            return t.copyWith(subtopics: updatedSubtopics);
          }
          return t;
        }).toList();
        return s.copyWith(topics: updatedTopics);
      }
      return s;
    }).toList();

    await _persistAndEnqueue('subtopic_update', subtopicId);
    notifyListeners();
  }

  Future<void> addCustomTopic(String subjectId, String topicName) async {
    if (_currentUserId == null) return;
    final newTopic = SyllabusTopic(
      id: const Uuid().v4(),
      name: topicName.trim(),
      subjectId: subjectId,
      status: SyllabusStatus.notStarted,
    );

    _subjects = _subjects.map((s) {
      if (s.id == subjectId) {
        return s.copyWith(topics: [...s.topics, newTopic]);
      }
      return s;
    }).toList();

    await _persistAndEnqueue('topic_create', newTopic.id);
    notifyListeners();
  }

  Future<void> deleteTopic(String subjectId, String topicId) async {
    if (_currentUserId == null) return;
    _subjects = _subjects.map((s) {
      if (s.id == subjectId) {
        return s.copyWith(
          topics: s.topics.where((t) => t.id != topicId).toList(),
        );
      }
      return s;
    }).toList();

    await _persistAndEnqueue('topic_delete', topicId, isDelete: true);
    notifyListeners();
  }

  Future<void> _persistAndEnqueue(String actionType, String docId, {bool isDelete = false}) async {
    if (_currentUserId == null) return;
    await _storage.saveSyllabus(_currentUserId!, _subjects);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: isDelete ? QueuedActionType.delete : QueuedActionType.update,
        collectionName: 'syllabus',
        documentId: docId,
        payload: {'updatedAt': DateTime.now().toIso8601String()},
        timestamp: DateTime.now(),
      ),
    );
  }
}

