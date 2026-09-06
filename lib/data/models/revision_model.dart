class RevisionSessionModel {
  final String sessionId;
  final String userId;
  final String title;
  final List<String> topicsDue;
  final List<String> mistakesToReview;
  final List<String> flashcardsDue;
  final DateTime scheduledDate;
  final bool isCompleted;
  final DateTime? completedAt;

  const RevisionSessionModel({
    required this.sessionId,
    required this.userId,
    required this.title,
    this.topicsDue = const [],
    this.mistakesToReview = const [],
    this.flashcardsDue = const [],
    required this.scheduledDate,
    this.isCompleted = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'userId': userId,
    'title': title,
    'topicsDue': topicsDue,
    'mistakesToReview': mistakesToReview,
    'flashcardsDue': flashcardsDue,
    'scheduledDate': scheduledDate.toIso8601String(),
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory RevisionSessionModel.fromJson(Map<String, dynamic> json) =>
      RevisionSessionModel(
        sessionId: json['sessionId'] as String,
        userId: json['userId'] as String? ?? '',
        title: json['title'] as String,
        topicsDue: (json['topicsDue'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        mistakesToReview: (json['mistakesToReview'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        flashcardsDue: (json['flashcardsDue'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        scheduledDate: json['scheduledDate'] != null
            ? DateTime.parse(json['scheduledDate'] as String)
            : DateTime.now(),
        isCompleted: json['isCompleted'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );

  RevisionSessionModel copyWith({
    String? sessionId,
    String? userId,
    String? title,
    List<String>? topicsDue,
    List<String>? mistakesToReview,
    List<String>? flashcardsDue,
    DateTime? scheduledDate,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return RevisionSessionModel(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      topicsDue: topicsDue ?? this.topicsDue,
      mistakesToReview: mistakesToReview ?? this.mistakesToReview,
      flashcardsDue: flashcardsDue ?? this.flashcardsDue,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

