import 'dart:convert';

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

enum QuestionType {
  mcq,
  multipleCorrect,
  trueFalse,
  fillInBlank,
  numerical,
  shortAnswer,
  longAnswer,
  conceptual,
  formulaBased,
  calculationBased,
  diagramBased,
  matchFollowing,
  assertionReason,
  coding,
  debugging;

  String get label {
    switch (this) {
      case QuestionType.mcq:
        return 'Multiple Choice';
      case QuestionType.multipleCorrect:
        return 'Multiple Correct';
      case QuestionType.trueFalse:
        return 'True / False';
      case QuestionType.fillInBlank:
        return 'Fill in the Blank';
      case QuestionType.numerical:
        return 'Numerical';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.longAnswer:
        return 'Descriptive / Long Answer';
      case QuestionType.conceptual:
        return 'Conceptual';
      case QuestionType.formulaBased:
        return 'Formula Based';
      case QuestionType.calculationBased:
        return 'Calculation Based';
      case QuestionType.diagramBased:
        return 'Diagram Based';
      case QuestionType.matchFollowing:
        return 'Match the Following';
      case QuestionType.assertionReason:
        return 'Assertion & Reason';
      case QuestionType.coding:
        return 'Verilog / Hardware Coding';
      case QuestionType.debugging:
        return 'Circuit Debugging';
    }
  }

  static QuestionType fromString(String val) {
    for (final t in QuestionType.values) {
      if (t.name.toLowerCase() == val.toLowerCase().trim()) return t;
    }
    return QuestionType.mcq;
  }
}

enum QuestionStatus {
  unsolved,
  attempted,
  partiallySolved,
  solved,
  needsReview;

  String get label {
    switch (this) {
      case QuestionStatus.unsolved:
        return 'UNSOLVED';
      case QuestionStatus.attempted:
        return 'ATTEMPTED';
      case QuestionStatus.partiallySolved:
        return 'PARTIALLY SOLVED';
      case QuestionStatus.solved:
        return 'SOLVED';
      case QuestionStatus.needsReview:
        return 'NEEDS REVIEW';
    }
  }

  static QuestionStatus fromString(String val) {
    for (final s in QuestionStatus.values) {
      if (s.name.toLowerCase() == val.toLowerCase().trim()) return s;
    }
    return QuestionStatus.unsolved;
  }
}

enum VerificationStatus {
  sourceVerified,
  aiVerified,
  aiGenerated,
  needsReview,
  unknown;

  String get label {
    switch (this) {
      case VerificationStatus.sourceVerified:
        return 'Source Verified';
      case VerificationStatus.aiVerified:
        return 'AI Verified';
      case VerificationStatus.aiGenerated:
        return 'AI Generated';
      case VerificationStatus.needsReview:
        return 'Needs Review';
      case VerificationStatus.unknown:
        return 'Answer Unknown';
    }
  }

  static VerificationStatus fromString(String val) {
    for (final v in VerificationStatus.values) {
      if (v.name.toLowerCase() == val.toLowerCase().trim()) return v;
    }
    return VerificationStatus.sourceVerified;
  }
}

enum DiagramType {
  none,
  logicGate,
  timingWaveform,
  flipFlop,
  fsmState,
  circuit,
  memoryBlock,
  customImage;

  static DiagramType fromString(String val) {
    for (final d in DiagramType.values) {
      if (d.name.toLowerCase() == val.toLowerCase().trim()) return d;
    }
    return DiagramType.none;
  }
}

class QuestionModel {
  final String questionId;
  final String userId;
  final String questionText;
  final List<String> options;
  final String correctAnswer; // usually 'A', 'B', 'C', 'D', numerical or text
  final String solution;
  final String subject;
  final String topic;
  final String? subtopic;
  final Difficulty difficulty;
  final QuestionType questionType;
  final QuestionStatus status;
  final VerificationStatus verificationStatus;
  final DiagramType diagramType;
  final Map<String, dynamic>? diagramData;
  final String? diagramImageBase64;
  final String? solutionImageBase64;
  final String userNotes;
  final List<String> tags;
  final String sourceId;
  final String sourceName;
  final String sourceLocation; // e.g. "Page 24, Mesh Analysis"
  final String sourceChunk;
  final List<String> webReferences;
  final DateTime createdAt;
  final DateTime? lastAttemptedAt;
  final int attemptCount;
  final int correctAttempts;
  final int incorrectAttempts;
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
    this.questionType = QuestionType.mcq,
    this.status = QuestionStatus.unsolved,
    this.verificationStatus = VerificationStatus.sourceVerified,
    this.diagramType = DiagramType.none,
    this.diagramData,
    this.diagramImageBase64,
    this.solutionImageBase64,
    this.userNotes = '',
    this.tags = const [],
    required this.sourceId,
    required this.sourceName,
    this.sourceLocation = '',
    this.sourceChunk = '',
    this.webReferences = const [],
    required this.createdAt,
    this.lastAttemptedAt,
    this.attemptCount = 0,
    this.correctAttempts = 0,
    this.incorrectAttempts = 0,
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
        'questionType': questionType.name,
        'status': status.name,
        'verificationStatus': verificationStatus.name,
        'diagramType': diagramType.name,
        'diagramData': diagramData,
        'diagramImageBase64': diagramImageBase64,
        'solutionImageBase64': solutionImageBase64,
        'userNotes': userNotes,
        'tags': tags,
        'sourceId': sourceId,
        'sourceName': sourceName,
        'sourceLocation': sourceLocation,
        'sourceChunk': sourceChunk,
        'webReferences': webReferences,
        'createdAt': createdAt.toIso8601String(),
        'lastAttemptedAt': lastAttemptedAt?.toIso8601String(),
        'attemptCount': attemptCount,
        'correctAttempts': correctAttempts,
        'incorrectAttempts': incorrectAttempts,
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
        correctAnswer: json['correctAnswer'] as String? ?? '',
        solution: json['solution'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
        subtopic: json['subtopic'] as String?,
        difficulty:
            Difficulty.fromString(json['difficulty'] as String? ?? 'medium'),
        questionType: json['questionType'] != null
            ? QuestionType.fromString(json['questionType'] as String)
            : QuestionType.mcq,
        status: json['status'] != null
            ? QuestionStatus.fromString(json['status'] as String)
            : ((json['isAttempted'] as bool? ?? false)
                ? ((json['isLastAttemptCorrect'] as bool? ?? false)
                    ? QuestionStatus.solved
                    : QuestionStatus.attempted)
                : QuestionStatus.unsolved),
        verificationStatus: json['verificationStatus'] != null
            ? VerificationStatus.fromString(
                json['verificationStatus'] as String)
            : (json['correctAnswer'] == null ||
                    (json['correctAnswer'] as String).isEmpty ||
                    json['correctAnswer'] == 'ANSWER UNKNOWN'
                ? VerificationStatus.unknown
                : VerificationStatus.sourceVerified),
        diagramType: json['diagramType'] != null
            ? DiagramType.fromString(json['diagramType'] as String)
            : DiagramType.none,
        diagramData: json['diagramData'] != null
            ? (json['diagramData'] is Map<String, dynamic>
                ? json['diagramData'] as Map<String, dynamic>
                : jsonDecode(json['diagramData'].toString())
                    as Map<String, dynamic>)
            : null,
        diagramImageBase64: json['diagramImageBase64'] as String?,
        solutionImageBase64: json['solutionImageBase64'] as String?,
        userNotes: json['userNotes'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        sourceId: json['sourceId'] as String? ?? '',
        sourceName: json['sourceName'] as String? ?? 'Unknown Source',
        sourceLocation: json['sourceLocation'] as String? ?? '',
        sourceChunk: json['sourceChunk'] as String? ?? '',
        webReferences: (json['webReferences'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        lastAttemptedAt: json['lastAttemptedAt'] != null
            ? DateTime.parse(json['lastAttemptedAt'] as String)
            : null,
        attemptCount: json['attemptCount'] as int? ??
            ((json['isAttempted'] as bool? ?? false) ? 1 : 0),
        correctAttempts: json['correctAttempts'] as int? ??
            ((json['isLastAttemptCorrect'] as bool? ?? false) ? 1 : 0),
        incorrectAttempts: json['incorrectAttempts'] as int? ??
            ((json['isAttempted'] as bool? ?? false) &&
                    !(json['isLastAttemptCorrect'] as bool? ?? false)
                ? 1
                : 0),
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
    QuestionType? questionType,
    QuestionStatus? status,
    VerificationStatus? verificationStatus,
    DiagramType? diagramType,
    Map<String, dynamic>? diagramData,
    String? diagramImageBase64,
    String? solutionImageBase64,
    String? userNotes,
    List<String>? tags,
    String? sourceId,
    String? sourceName,
    String? sourceLocation,
    String? sourceChunk,
    List<String>? webReferences,
    DateTime? createdAt,
    DateTime? lastAttemptedAt,
    int? attemptCount,
    int? correctAttempts,
    int? incorrectAttempts,
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
      questionType: questionType ?? this.questionType,
      status: status ?? this.status,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      diagramType: diagramType ?? this.diagramType,
      diagramData: diagramData ?? this.diagramData,
      diagramImageBase64: diagramImageBase64 ?? this.diagramImageBase64,
      solutionImageBase64: solutionImageBase64 ?? this.solutionImageBase64,
      userNotes: userNotes ?? this.userNotes,
      tags: tags ?? this.tags,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      sourceLocation: sourceLocation ?? this.sourceLocation,
      sourceChunk: sourceChunk ?? this.sourceChunk,
      webReferences: webReferences ?? this.webReferences,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptedAt: lastAttemptedAt ?? this.lastAttemptedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      correctAttempts: correctAttempts ?? this.correctAttempts,
      incorrectAttempts: incorrectAttempts ?? this.incorrectAttempts,
      isAttempted: isAttempted ?? this.isAttempted,
      isLastAttemptCorrect: isLastAttemptCorrect ?? this.isLastAttemptCorrect,
    );
  }
}
