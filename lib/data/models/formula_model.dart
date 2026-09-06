class FormulaModel {
  final String formulaId;
  final String userId;
  final String subject;
  final String topic;
  final String title;
  final String latexExpression;
  final String description;
  final String notes;
  final String sourceId;
  final String sourceName;
  final String sourceLocation;
  final bool isFavorite;
  final DateTime createdAt;

  const FormulaModel({
    required this.formulaId,
    required this.userId,
    required this.subject,
    required this.topic,
    required this.title,
    required this.latexExpression,
    this.description = '',
    this.notes = '',
    this.sourceId = '',
    this.sourceName = '',
    this.sourceLocation = '',
    this.isFavorite = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'formulaId': formulaId,
    'userId': userId,
    'subject': subject,
    'topic': topic,
    'title': title,
    'latexExpression': latexExpression,
    'description': description,
    'notes': notes,
    'sourceId': sourceId,
    'sourceName': sourceName,
    'sourceLocation': sourceLocation,
    'isFavorite': isFavorite,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FormulaModel.fromJson(Map<String, dynamic> json) => FormulaModel(
    formulaId: json['formulaId'] as String,
    userId: json['userId'] as String? ?? '',
    subject: json['subject'] as String? ?? '',
    topic: json['topic'] as String? ?? '',
    title: json['title'] as String,
    latexExpression: json['latexExpression'] as String,
    description: json['description'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    sourceId: json['sourceId'] as String? ?? '',
    sourceName: json['sourceName'] as String? ?? '',
    sourceLocation: json['sourceLocation'] as String? ?? '',
    isFavorite: json['isFavorite'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
  );

  FormulaModel copyWith({
    String? formulaId,
    String? userId,
    String? subject,
    String? topic,
    String? title,
    String? latexExpression,
    String? description,
    String? notes,
    String? sourceId,
    String? sourceName,
    String? sourceLocation,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return FormulaModel(
      formulaId: formulaId ?? this.formulaId,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      title: title ?? this.title,
      latexExpression: latexExpression ?? this.latexExpression,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      sourceLocation: sourceLocation ?? this.sourceLocation,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

