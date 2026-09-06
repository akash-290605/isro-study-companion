enum SyllabusStatus {
  notStarted,
  inProgress,
  completed;

  String get label {
    switch (this) {
      case SyllabusStatus.notStarted:
        return 'Not Started';
      case SyllabusStatus.inProgress:
        return 'In Progress';
      case SyllabusStatus.completed:
        return 'Completed';
    }
  }
}

class SyllabusLesson {
  final String id;
  final String name;
  final String subtopicId;
  final SyllabusStatus status;
  final String notes;

  const SyllabusLesson({
    required this.id,
    required this.name,
    required this.subtopicId,
    this.status = SyllabusStatus.notStarted,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subtopicId': subtopicId,
    'status': status.name,
    'notes': notes,
  };

  factory SyllabusLesson.fromJson(Map<String, dynamic> json) => SyllabusLesson(
    id: json['id'] as String,
    name: json['name'] as String,
    subtopicId: json['subtopicId'] as String,
    status: SyllabusStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => SyllabusStatus.notStarted,
    ),
    notes: json['notes'] as String? ?? '',
  );

  SyllabusLesson copyWith({
    String? id,
    String? name,
    String? subtopicId,
    SyllabusStatus? status,
    String? notes,
  }) {
    return SyllabusLesson(
      id: id ?? this.id,
      name: name ?? this.name,
      subtopicId: subtopicId ?? this.subtopicId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

class SyllabusSubtopic {
  final String id;
  final String name;
  final String topicId;
  final SyllabusStatus status;
  final List<SyllabusLesson> lessons;

  const SyllabusSubtopic({
    required this.id,
    required this.name,
    required this.topicId,
    this.status = SyllabusStatus.notStarted,
    this.lessons = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'topicId': topicId,
    'status': status.name,
    'lessons': lessons.map((e) => e.toJson()).toList(),
  };

  factory SyllabusSubtopic.fromJson(Map<String, dynamic> json) => SyllabusSubtopic(
    id: json['id'] as String,
    name: json['name'] as String,
    topicId: json['topicId'] as String,
    status: SyllabusStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => SyllabusStatus.notStarted,
    ),
    lessons: (json['lessons'] as List<dynamic>?)
            ?.map((e) => SyllabusLesson.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  SyllabusSubtopic copyWith({
    String? id,
    String? name,
    String? topicId,
    SyllabusStatus? status,
    List<SyllabusLesson>? lessons,
  }) {
    return SyllabusSubtopic(
      id: id ?? this.id,
      name: name ?? this.name,
      topicId: topicId ?? this.topicId,
      status: status ?? this.status,
      lessons: lessons ?? this.lessons,
    );
  }
}

class SyllabusTopic {
  final String id;
  final String name;
  final String subjectId;
  final SyllabusStatus status;
  final List<SyllabusSubtopic> subtopics;

  const SyllabusTopic({
    required this.id,
    required this.name,
    required this.subjectId,
    this.status = SyllabusStatus.notStarted,
    this.subtopics = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subjectId': subjectId,
    'status': status.name,
    'subtopics': subtopics.map((e) => e.toJson()).toList(),
  };

  factory SyllabusTopic.fromJson(Map<String, dynamic> json) => SyllabusTopic(
    id: json['id'] as String,
    name: json['name'] as String,
    subjectId: json['subjectId'] as String,
    status: SyllabusStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => SyllabusStatus.notStarted,
    ),
    subtopics: (json['subtopics'] as List<dynamic>?)
            ?.map((e) => SyllabusSubtopic.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  SyllabusTopic copyWith({
    String? id,
    String? name,
    String? subjectId,
    SyllabusStatus? status,
    List<SyllabusSubtopic>? subtopics,
  }) {
    return SyllabusTopic(
      id: id ?? this.id,
      name: name ?? this.name,
      subjectId: subjectId ?? this.subjectId,
      status: status ?? this.status,
      subtopics: subtopics ?? this.subtopics,
    );
  }
}

class SyllabusSubject {
  final String id;
  final String name;
  final int order;
  final SyllabusStatus status;
  final List<SyllabusTopic> topics;

  const SyllabusSubject({
    required this.id,
    required this.name,
    this.order = 0,
    this.status = SyllabusStatus.notStarted,
    this.topics = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'order': order,
    'status': status.name,
    'topics': topics.map((e) => e.toJson()).toList(),
  };

  factory SyllabusSubject.fromJson(Map<String, dynamic> json) => SyllabusSubject(
    id: json['id'] as String,
    name: json['name'] as String,
    order: json['order'] as int? ?? 0,
    status: SyllabusStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => SyllabusStatus.notStarted,
    ),
    topics: (json['topics'] as List<dynamic>?)
            ?.map((e) => SyllabusTopic.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  SyllabusSubject copyWith({
    String? id,
    String? name,
    int? order,
    SyllabusStatus? status,
    List<SyllabusTopic>? topics,
  }) {
    return SyllabusSubject(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      status: status ?? this.status,
      topics: topics ?? this.topics,
    );
  }

  double get completionPercentage {
    if (topics.isEmpty) return 0.0;
    int completed = 0;
    int total = 0;
    for (final t in topics) {
      if (t.subtopics.isEmpty) {
        total += 1;
        if (t.status == SyllabusStatus.completed) completed += 1;
      } else {
        for (final st in t.subtopics) {
          total += 1;
          if (st.status == SyllabusStatus.completed) completed += 1;
        }
      }
    }
    return total == 0 ? 0.0 : (completed / total) * 100;
  }
}

