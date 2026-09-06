enum TimerMode {
  stopwatch,
  pomodoro;

  String get label => this == TimerMode.stopwatch ? 'Stopwatch' : 'Pomodoro';
}

class StudySessionModel {
  final String sessionId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final TimerMode mode;
  final String subject;
  final String topic;
  final String? subtopic;
  final String device;
  final DateTime date;

  const StudySessionModel({
    required this.sessionId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    this.mode = TimerMode.stopwatch,
    this.subject = '',
    this.topic = '',
    this.subtopic,
    this.device = 'Unknown',
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'userId': userId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'durationSeconds': durationSeconds,
    'mode': mode.name,
    'subject': subject,
    'topic': topic,
    'subtopic': subtopic,
    'device': device,
    'date': date.toIso8601String(),
  };

  factory StudySessionModel.fromJson(Map<String, dynamic> json) =>
      StudySessionModel(
        sessionId: json['sessionId'] as String,
        userId: json['userId'] as String? ?? '',
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'] as String)
            : DateTime.now(),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : DateTime.now(),
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        mode: TimerMode.values.firstWhere(
          (e) => e.name == json['mode'],
          orElse: () => TimerMode.stopwatch,
        ),
        subject: json['subject'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
        subtopic: json['subtopic'] as String?,
        device: json['device'] as String? ?? 'Unknown',
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
      );
}

