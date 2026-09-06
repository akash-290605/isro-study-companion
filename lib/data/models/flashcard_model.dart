import 'question_model.dart';

class FlashcardModel {
  final String cardId;
  final String userId;
  final String sourceId;
  final String sourceName;
  final String sourceLocation;
  final String sourceChunk;
  final String subject;
  final String topic;
  final String question; // Front
  final String answer; // Back
  final Difficulty difficulty;
  final DateTime reviewDate;
  final int intervalDays;
  final int repetitionCount;
  final DateTime createdAt;

  const FlashcardModel({
    required this.cardId,
    required this.userId,
    required this.sourceId,
    required this.sourceName,
    this.sourceLocation = '',
    this.sourceChunk = '',
    this.subject = '',
    this.topic = '',
    required this.question,
    required this.answer,
    this.difficulty = Difficulty.medium,
    required this.reviewDate,
    this.intervalDays = 1,
    this.repetitionCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'userId': userId,
    'sourceId': sourceId,
    'sourceName': sourceName,
    'sourceLocation': sourceLocation,
    'sourceChunk': sourceChunk,
    'subject': subject,
    'topic': topic,
    'question': question,
    'answer': answer,
    'difficulty': difficulty.name,
    'reviewDate': reviewDate.toIso8601String(),
    'intervalDays': intervalDays,
    'repetitionCount': repetitionCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FlashcardModel.fromJson(Map<String, dynamic> json) => FlashcardModel(
    cardId: json['cardId'] as String,
    userId: json['userId'] as String? ?? '',
    sourceId: json['sourceId'] as String? ?? '',
    sourceName: json['sourceName'] as String? ?? 'Unknown Source',
    sourceLocation: json['sourceLocation'] as String? ?? '',
    sourceChunk: json['sourceChunk'] as String? ?? '',
    subject: json['subject'] as String? ?? '',
    topic: json['topic'] as String? ?? '',
    question: json['question'] as String,
    answer: json['answer'] as String,
    difficulty: Difficulty.fromString(json['difficulty'] as String? ?? 'medium'),
    reviewDate: json['reviewDate'] != null
        ? DateTime.parse(json['reviewDate'] as String)
        : DateTime.now(),
    intervalDays: json['intervalDays'] as int? ?? 1,
    repetitionCount: json['repetitionCount'] as int? ?? 0,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
  );

  FlashcardModel copyWith({
    String? cardId,
    String? userId,
    String? sourceId,
    String? sourceName,
    String? sourceLocation,
    String? sourceChunk,
    String? subject,
    String? topic,
    String? question,
    String? answer,
    Difficulty? difficulty,
    DateTime? reviewDate,
    int? intervalDays,
    int? repetitionCount,
    DateTime? createdAt,
  }) {
    return FlashcardModel(
      cardId: cardId ?? this.cardId,
      userId: userId ?? this.userId,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      sourceLocation: sourceLocation ?? this.sourceLocation,
      sourceChunk: sourceChunk ?? this.sourceChunk,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      difficulty: difficulty ?? this.difficulty,
      reviewDate: reviewDate ?? this.reviewDate,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitionCount: repetitionCount ?? this.repetitionCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

