enum Difficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'EASY';
      case Difficulty.medium:
        return 'MEDIUM';
      case Difficulty.hard:
        return 'HARD';
    }
  }

  static Difficulty fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'easy':
        return Difficulty.easy;
      case 'hard':
        return Difficulty.hard;
      case 'medium':
      default:
        return Difficulty.medium;
    }
  }
}

class QuestionModel {
  final String questionId;
  final String userId;
  final String questionText;
  final List<String> options;
  final String correctAnswer; // usually 'A', 'B', 'C', 'D' or option text
  final String solution;
  final String subject;
  final String topic;
  final String? subtopic;
  final Difficulty difficulty;
  final String sourceId;
  final String sourceName;
  final String sourceLocation; // e.g. "Page 24, Mesh Analysis"
  final String sourceChunk;
  final DateTime createdAt;
  final bool isAttempted;
  final bool? isLastAttemptCorrect;

  const QuestionModel({
    required this.questionId,
    required this.userId,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.solution = '',
    this.subject = '',
    this.topic = '',
    this.subtopic,
    this.difficulty = Difficulty.medium,
    required this.sourceId,
    required this.sourceName,
    this.sourceLocation = '',
    this.sourceChunk = '',
    required this.createdAt,
    this.isAttempted = false,
    this.isLastAttemptCorrect,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'userId': userId,
    'questionText': questionText,
    'options': options,
    'correctAnswer': correctAnswer,
    'solution': solution,
    'subject': subject,
    'topic': topic,
    'subtopic': subtopic,
    'difficulty': difficulty.name,
    'sourceId': sourceId,
    'sourceName': sourceName,
    'sourceLocation': sourceLocation,
    'sourceChunk': sourceChunk,
    'createdAt': createdAt.toIso8601String(),
    'isAttempted': isAttempted,
    'isLastAttemptCorrect': isLastAttemptCorrect,
  };

  factory QuestionModel.fromJson(Map<String, dynamic> json) => QuestionModel(
    questionId: json['questionId'] as String,
    userId: json['userId'] as String? ?? '',
    questionText: json['questionText'] as String,
    options: (json['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    correctAnswer: json['correctAnswer'] as String,
    solution: json['solution'] as String? ?? '',
    subject: json['subject'] as String? ?? '',
    topic: json['topic'] as String? ?? '',
    subtopic: json['subtopic'] as String?,
    difficulty: Difficulty.fromString(json['difficulty'] as String? ?? 'medium'),
    sourceId: json['sourceId'] as String? ?? '',
    sourceName: json['sourceName'] as String? ?? 'Unknown Source',
    sourceLocation: json['sourceLocation'] as String? ?? '',
    sourceChunk: json['sourceChunk'] as String? ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    isAttempted: json['isAttempted'] as bool? ?? false,
    isLastAttemptCorrect: json['isLastAttemptCorrect'] as bool?,
  );

  QuestionModel copyWith({
    String? questionId,
    String? userId,
    String? questionText,
    List<String>? options,
    String? correctAnswer,
    String? solution,
    String? subject,
    String? topic,
    String? subtopic,
    Difficulty? difficulty,
    String? sourceId,
    String? sourceName,
    String? sourceLocation,
    String? sourceChunk,
    DateTime? createdAt,
    bool? isAttempted,
    bool? isLastAttemptCorrect,
  }) {
    return QuestionModel(
      questionId: questionId ?? this.questionId,
      userId: userId ?? this.userId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      solution: solution ?? this.solution,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      difficulty: difficulty ?? this.difficulty,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      sourceLocation: sourceLocation ?? this.sourceLocation,
      sourceChunk: sourceChunk ?? this.sourceChunk,
      createdAt: createdAt ?? this.createdAt,
      isAttempted: isAttempted ?? this.isAttempted,
      isLastAttemptCorrect: isLastAttemptCorrect ?? this.isLastAttemptCorrect,
    );
  }
}

