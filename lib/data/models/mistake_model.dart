import 'question_model.dart';

class MistakeModel {
  final String mistakeId;
  final String userId;
  final String questionId;
  final String questionText;
  final List<String> options;
  final String userAnswer;
  final String correctAnswer;
  final String solution;
  final String subject;
  final String topic;
  final Difficulty difficulty;
  final String sourceId;
  final String sourceName;
  final String sourceLocation;
  final String testId;
  final DateTime testDate;
  final String userNotes;
  final bool isResolved;
  final DateTime dateAdded;

  const MistakeModel({
    required this.mistakeId,
    required this.userId,
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.userAnswer,
    required this.correctAnswer,
    this.solution = '',
    this.subject = '',
    this.topic = '',
    this.difficulty = Difficulty.medium,
    required this.sourceId,
    required this.sourceName,
    this.sourceLocation = '',
    this.testId = '',
    required this.testDate,
    this.userNotes = '',
    this.isResolved = false,
    required this.dateAdded,
  });

  Map<String, dynamic> toJson() => {
    'mistakeId': mistakeId,
    'userId': userId,
    'questionId': questionId,
    'questionText': questionText,
    'options': options,
    'userAnswer': userAnswer,
    'correctAnswer': correctAnswer,
    'solution': solution,
    'subject': subject,
    'topic': topic,
    'difficulty': difficulty.name,
    'sourceId': sourceId,
    'sourceName': sourceName,
    'sourceLocation': sourceLocation,
    'testId': testId,
    'testDate': testDate.toIso8601String(),
    'userNotes': userNotes,
    'isResolved': isResolved,
    'dateAdded': dateAdded.toIso8601String(),
  };

  factory MistakeModel.fromJson(Map<String, dynamic> json) => MistakeModel(
    mistakeId: json['mistakeId'] as String,
    userId: json['userId'] as String? ?? '',
    questionId: json['questionId'] as String,
    questionText: json['questionText'] as String,
    options: (json['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    userAnswer: json['userAnswer'] as String? ?? '',
    correctAnswer: json['correctAnswer'] as String,
    solution: json['solution'] as String? ?? '',
    subject: json['subject'] as String? ?? '',
    topic: json['topic'] as String? ?? '',
    difficulty: Difficulty.fromString(json['difficulty'] as String? ?? 'medium'),
    sourceId: json['sourceId'] as String? ?? '',
    sourceName: json['sourceName'] as String? ?? 'Unknown Source',
    sourceLocation: json['sourceLocation'] as String? ?? '',
    testId: json['testId'] as String? ?? '',
    testDate: json['testDate'] != null
        ? DateTime.parse(json['testDate'] as String)
        : DateTime.now(),
    userNotes: json['userNotes'] as String? ?? '',
    isResolved: json['isResolved'] as bool? ?? false,
    dateAdded: json['dateAdded'] != null
        ? DateTime.parse(json['dateAdded'] as String)
        : DateTime.now(),
  );

  MistakeModel copyWith({
    String? mistakeId,
    String? userId,
    String? questionId,
    String? questionText,
    List<String>? options,
    String? userAnswer,
    String? correctAnswer,
    String? solution,
    String? subject,
    String? topic,
    Difficulty? difficulty,
    String? sourceId,
    String? sourceName,
    String? sourceLocation,
    String? testId,
    DateTime? testDate,
    String? userNotes,
    bool? isResolved,
    DateTime? dateAdded,
  }) {
    return MistakeModel(
      mistakeId: mistakeId ?? this.mistakeId,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      userAnswer: userAnswer ?? this.userAnswer,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      solution: solution ?? this.solution,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      sourceLocation: sourceLocation ?? this.sourceLocation,
      testId: testId ?? this.testId,
      testDate: testDate ?? this.testDate,
      userNotes: userNotes ?? this.userNotes,
      isResolved: isResolved ?? this.isResolved,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
}

