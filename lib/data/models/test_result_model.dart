import 'test_model.dart';

class TopicPerformance {
  final String topic;
  final int correct;
  final int wrong;
  final int unattempted;
  final int total;
  final double accuracy;

  const TopicPerformance({
    required this.topic,
    required this.correct,
    required this.wrong,
    required this.unattempted,
    required this.total,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() => {
    'topic': topic,
    'correct': correct,
    'wrong': wrong,
    'unattempted': unattempted,
    'total': total,
    'accuracy': accuracy,
  };

  factory TopicPerformance.fromJson(Map<String, dynamic> json) => TopicPerformance(
    topic: json['topic'] as String,
    correct: json['correct'] as int? ?? 0,
    wrong: json['wrong'] as int? ?? 0,
    unattempted: json['unattempted'] as int? ?? 0,
    total: json['total'] as int? ?? 0,
    accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
  );
}

class DifficultyPerformance {
  final String difficulty;
  final int correct;
  final int total;
  final double accuracy;

  const DifficultyPerformance({
    required this.difficulty,
    required this.correct,
    required this.total,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() => {
    'difficulty': difficulty,
    'correct': correct,
    'total': total,
    'accuracy': accuracy,
  };

  factory DifficultyPerformance.fromJson(Map<String, dynamic> json) =>
      DifficultyPerformance(
        difficulty: json['difficulty'] as String,
        correct: json['correct'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      );
}

class TestResultModel {
  final String resultId;
  final String testId;
  final String userId;
  final String title;
  final double score;
  final double maxScore;
  final double percentage;
  final int correctCount;
  final int wrongCount;
  final int unattemptedCount;
  final double negativeMarksDeducted;
  final int timeUsedSeconds;
  final Map<String, TopicPerformance> topicBreakdown;
  final Map<String, DifficultyPerformance> difficultyBreakdown;
  final List<TestQuestionModel> questions;
  final DateTime completedAt;

  const TestResultModel({
    required this.resultId,
    required this.testId,
    required this.userId,
    this.title = 'ISRO Practice Test',
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.correctCount,
    required this.wrongCount,
    required this.unattemptedCount,
    required this.negativeMarksDeducted,
    required this.timeUsedSeconds,
    this.topicBreakdown = const {},
    this.difficultyBreakdown = const {},
    this.questions = const [],
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'resultId': resultId,
    'testId': testId,
    'userId': userId,
    'title': title,
    'score': score,
    'maxScore': maxScore,
    'percentage': percentage,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'unattemptedCount': unattemptedCount,
    'negativeMarksDeducted': negativeMarksDeducted,
    'timeUsedSeconds': timeUsedSeconds,
    'topicBreakdown': topicBreakdown.map((k, v) => MapEntry(k, v.toJson())),
    'difficultyBreakdown':
        difficultyBreakdown.map((k, v) => MapEntry(k, v.toJson())),
    'questions': questions.map((q) => q.toJson()).toList(),
    'completedAt': completedAt.toIso8601String(),
  };

  factory TestResultModel.fromJson(Map<String, dynamic> json) => TestResultModel(
    resultId: json['resultId'] as String,
    testId: json['testId'] as String,
    userId: json['userId'] as String? ?? '',
    title: json['title'] as String? ?? 'ISRO Practice Test',
    score: (json['score'] as num?)?.toDouble() ?? 0.0,
    maxScore: (json['maxScore'] as num?)?.toDouble() ?? 0.0,
    percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    correctCount: json['correctCount'] as int? ?? 0,
    wrongCount: json['wrongCount'] as int? ?? 0,
    unattemptedCount: json['unattemptedCount'] as int? ?? 0,
    negativeMarksDeducted:
        (json['negativeMarksDeducted'] as num?)?.toDouble() ?? 0.0,
    timeUsedSeconds: json['timeUsedSeconds'] as int? ?? 0,
    topicBreakdown: (json['topicBreakdown'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, TopicPerformance.fromJson(v as Map<String, dynamic>)),
        ) ??
        const {},
    difficultyBreakdown:
        (json['difficultyBreakdown'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(
                k,
                DifficultyPerformance.fromJson(v as Map<String, dynamic>),
              ),
            ) ??
            const {},
    questions: (json['questions'] as List<dynamic>?)
            ?.map((e) => TestQuestionModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : DateTime.now(),
  );
}

