import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/local_storage_service.dart';
import '../models/study_session_model.dart';
import '../models/sync_model.dart';

class StudySessionsRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<StudySessionModel> _sessions = [];
  String? _currentUserId;

  StudySessionsRepository(this._storage);

  List<StudySessionModel> get sessions => _sessions;

  void loadForUser(String userId) {
    _currentUserId = userId;
    _sessions = _storage.getStudySessions(userId);
    if (_sessions.isEmpty) {
      // Starter sessions to show initial analytics
      final now = DateTime.now();
      _sessions = [
        StudySessionModel(
          sessionId: 'session_01',
          userId: userId,
          startTime: now.subtract(const Duration(hours: 3)),
          endTime: now.subtract(const Duration(hours: 1, minutes: 40)),
          durationSeconds: 4800, // 1h 20m
          mode: TimerMode.pomodoro,
          subject: 'Network Theory',
          topic: 'Network Analysis',
          subtopic: 'KCL, KVL & Node/Mesh Analysis',
          device: 'Windows Desktop',
          date: now,
        ),
        StudySessionModel(
          sessionId: 'session_02',
          userId: userId,
          startTime: now.subtract(const Duration(days: 1, hours: 2)),
          endTime: now.subtract(const Duration(days: 1)),
          durationSeconds: 7200, // 2h
          mode: TimerMode.stopwatch,
          subject: 'Digital Electronics',
          topic: 'Boolean Algebra & Combinational Circuits',
          device: 'Web Browser',
          date: now.subtract(const Duration(days: 1)),
        ),
      ];
      _storage.saveStudySessions(userId, _sessions);
    }
    notifyListeners();
  }

  int get todayStudySeconds {
    final now = DateTime.now();
    return _sessions.where((s) {
      return s.date.year == now.year &&
          s.date.month == now.month &&
          s.date.day == now.day;
    }).fold(0, (sum, s) => sum + s.durationSeconds);
  }

  int get weeklyStudySeconds {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _sessions.where((s) => s.date.isAfter(weekAgo)).fold(0, (sum, s) => sum + s.durationSeconds);
  }

  int get monthlyStudySeconds {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return _sessions.where((s) => s.date.isAfter(monthAgo)).fold(0, (sum, s) => sum + s.durationSeconds);
  }

  Map<String, int> get subjectStudySeconds {
    final Map<String, int> map = {};
    for (final s in _sessions) {
      final key = s.subject.isEmpty ? 'General' : s.subject;
      map[key] = (map[key] ?? 0) + s.durationSeconds;
    }
    return map;
  }

  Map<String, int> get topicStudySeconds {
    final Map<String, int> map = {};
    for (final s in _sessions) {
      final key = s.topic.isEmpty ? 'General' : s.topic;
      map[key] = (map[key] ?? 0) + s.durationSeconds;
    }
    return map;
  }

  Future<void> recordSession({
    required DateTime startTime,
    required DateTime endTime,
    required int durationSeconds,
    required TimerMode mode,
    required String subject,
    required String topic,
    String? subtopic,
    required String device,
  }) async {
    if (_currentUserId == null) return;
    final session = StudySessionModel(
      sessionId: const Uuid().v4(),
      userId: _currentUserId!,
      startTime: startTime,
      endTime: endTime,
      durationSeconds: durationSeconds,
      mode: mode,
      subject: subject,
      topic: topic,
      subtopic: subtopic,
      device: device,
      date: DateTime.now(),
    );

    _sessions.insert(0, session);
    await _storage.saveStudySessions(_currentUserId!, _sessions);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.create,
        collectionName: 'studySessions',
        documentId: session.sessionId,
        payload: session.toJson(),
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}

