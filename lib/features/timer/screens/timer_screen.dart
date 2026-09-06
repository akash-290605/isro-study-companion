import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/providers.dart';
import '../../../data/models/study_session_model.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  TimerMode _mode = TimerMode.pomodoro;
  bool _isRunning = false;
  bool _isBreak = false;

  // Timestamp-based timing ensures exact accuracy across backgrounding/tab changes
  DateTime? _sessionStartTime;
  DateTime? _timerSegmentStartTime;
  int _accumulatedSeconds = 0;
  Timer? _periodicTicker;

  // Pomodoro settings
  final int _studyMinutes = AppConstants.defaultPomodoroStudyMinutes;
  final int _shortBreakMinutes = AppConstants.defaultPomodoroShortBreakMinutes;
  int _completedCycles = 0;

  // Subject / Topic tagging
  String _selectedSubject = 'Network Theory';
  String _selectedTopic = 'Network Analysis';
  final String _selectedSubtopic = 'KCL, KVL & Node/Mesh Analysis';

  @override
  void dispose() {
    _periodicTicker?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _sessionStartTime ??= DateTime.now();
      _timerSegmentStartTime = DateTime.now();
    });

    _periodicTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          // Trigger re-render with accurate timestamp comparison
        });
      }
    });
  }

  void _pauseTimer() {
    if (_timerSegmentStartTime != null) {
      _accumulatedSeconds += DateTime.now().difference(_timerSegmentStartTime!).inSeconds;
    }
    _periodicTicker?.cancel();
    setState(() {
      _isRunning = false;
      _timerSegmentStartTime = null;
    });
  }

  int get _currentSeconds {
    if (!_isRunning || _timerSegmentStartTime == null) {
      return _accumulatedSeconds;
    }
    final segmentElapsed = DateTime.now().difference(_timerSegmentStartTime!).inSeconds;
    return _accumulatedSeconds + segmentElapsed;
  }

  Future<void> _stopAndSaveSession() async {
    final totalSeconds = _currentSeconds;
    _pauseTimer();

    if (totalSeconds < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Study session too short (< 10s) to record.')),
      );
      _resetTimer();
      return;
    }

    final end = DateTime.now();
    final start = _sessionStartTime ?? end.subtract(Duration(seconds: totalSeconds));

    await ref.read(studySessionsRepositoryProvider).recordSession(
          startTime: start,
          endTime: end,
          durationSeconds: totalSeconds,
          mode: _mode,
          subject: _selectedSubject,
          topic: _selectedTopic,
          subtopic: _selectedSubtopic,
          device: Theme.of(context).platform.name,
        );

    // Increment user streak if minimum study goal met
    await ref.read(authRepositoryProvider).incrementStreak();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${_formatDuration(totalSeconds)} study session in "$_selectedSubject → $_selectedTopic".',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
    _resetTimer();
  }

  void _resetTimer() {
    _periodicTicker?.cancel();
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _sessionStartTime = null;
      _timerSegmentStartTime = null;
      _accumulatedSeconds = 0;
    });
  }

  String _formatDuration(int totalSec) {
    final hours = totalSec ~/ 3600;
    final mins = (totalSec % 3600) ~/ 60;
    final secs = totalSec % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final syllabus = ref.watch(syllabusRepositoryProvider);
    final subjectNames = syllabus.subjects.map((s) => s.name).toList();
    if (!subjectNames.contains(_selectedSubject) && subjectNames.isNotEmpty) {
      _selectedSubject = subjectNames.first;
    }

    final currentSubjectObj = syllabus.subjects.firstWhere(
      (s) => s.name == _selectedSubject,
      orElse: () => syllabus.subjects.isNotEmpty ? syllabus.subjects.first : throw Exception(),
    );

    final topicNames = currentSubjectObj.topics.map((t) => t.name).toList();
    if (!topicNames.contains(_selectedTopic) && topicNames.isNotEmpty) {
      _selectedTopic = topicNames.first;
    }

    // Pomodoro countdown calculation
    final targetSeconds = (_isBreak ? _shortBreakMinutes : _studyMinutes) * 60;
    final pomodoroRemaining = (targetSeconds - _currentSeconds).clamp(0, targetSeconds);

    if (_mode == TimerMode.pomodoro && _isRunning && pomodoroRemaining <= 0) {
      // Auto cycle switch
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _accumulatedSeconds = 0;
            _timerSegmentStartTime = DateTime.now();
            if (!_isBreak) {
              _completedCycles += 1;
              _isBreak = true;
            } else {
              _isBreak = false;
            }
          });
        }
      });
    }

    final displayTime = _mode == TimerMode.stopwatch
        ? _formatDuration(_currentSeconds)
        : _formatDuration(pomodoroRemaining);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header & Mode Selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'STUDY TIMER',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SegmentedButton<TimerMode>(
                        segments: const [
                          ButtonSegment(
                            value: TimerMode.pomodoro,
                            label: Text('Pomodoro'),
                            icon: Icon(Icons.timer_outlined, size: 16),
                          ),
                          ButtonSegment(
                            value: TimerMode.stopwatch,
                            label: Text('Stopwatch'),
                            icon: Icon(Icons.av_timer_rounded, size: 16),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (set) {
                          if (!_isRunning) {
                            setState(() {
                              _mode = set.first;
                              _resetTimer();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subject / Topic Association
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ASSOCIATE WITH SYLLABUS TOPIC',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSubject,
                              decoration: const InputDecoration(labelText: 'Subject'),
                              isExpanded: true,
                              items: subjectNames.map((s) {
                                return DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: _isRunning
                                  ? null
                                  : (v) {
                                      if (v != null) {
                                        setState(() {
                                          _selectedSubject = v;
                                          final sub = syllabus.subjects.firstWhere((s) => s.name == v);
                                          _selectedTopic = sub.topics.isNotEmpty ? sub.topics.first.name : '';
                                        });
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: topicNames.contains(_selectedTopic) ? _selectedTopic : null,
                              decoration: const InputDecoration(labelText: 'Topic'),
                              isExpanded: true,
                              items: topicNames.map((t) {
                                return DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis));
                              }).toList(),
                              onChanged: _isRunning
                                  ? null
                                  : (v) {
                                      if (v != null) {
                                        setState(() => _selectedTopic = v);
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Timer Display Card
              Card(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _isRunning
                        ? const Color(0xFF1E3A8A)
                        : Colors.grey.withOpacity(0.2),
                    width: _isRunning ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Column(
                    children: [
                      if (_mode == TimerMode.pomodoro) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isBreak ? Colors.green.shade50 : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isBreak ? Colors.green.shade300 : const Color(0xFF93C5FD),
                            ),
                          ),
                          child: Text(
                            _isBreak
                                ? '☕ SHORT BREAK (Cycle $_completedCycles Done)'
                                : '🎯 STUDY INTERVAL (Cycle ${_completedCycles + 1})',
                            style: TextStyle(
                              color: _isBreak ? Colors.green.shade800 : const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        displayTime,
                        style: const TextStyle(
                          fontSize: 68,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_selectedSubject • $_selectedTopic',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              backgroundColor: _isRunning ? Colors.amber.shade700 : const Color(0xFF1E3A8A),
                            ),
                            icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 24),
                            label: Text(_isRunning ? 'Pause' : 'Start Focus', style: const TextStyle(fontSize: 16)),
                            onPressed: _toggleTimer,
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                            label: const Text('Save & Finish'),
                            onPressed: _currentSeconds > 0 ? _stopAndSaveSession : null,
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: 'Reset',
                            icon: const Icon(Icons.refresh_rounded),
                            onPressed: _currentSeconds > 0 ? _resetTimer : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Timestamp & Background Accuracy Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Timestamp-accurate timing persists accurately if phone sleeps, browser tab switches, or app is backgrounded.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

