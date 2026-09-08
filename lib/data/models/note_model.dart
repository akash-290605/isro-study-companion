class NoteModel {
  final String noteId;
  final String userId;
  final String title;
  final String content;
  final String subject;
  final String topic;
  final String? subtopic;
  final List<String> tags;
  final String? imageBase64;
  final String? imageName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.noteId,
    required this.userId,
    required this.title,
    required this.content,
    this.subject = '',
    this.topic = '',
    this.subtopic,
    this.tags = const [],
    this.imageBase64,
    this.imageName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'noteId': noteId,
    'userId': userId,
    'title': title,
    'content': content,
    'subject': subject,
    'topic': topic,
    'subtopic': subtopic,
    'tags': tags,
    'imageBase64': imageBase64,
    'imageName': imageName,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
    noteId: json['noteId'] as String,
    userId: json['userId'] as String? ?? '',
    title: json['title'] as String,
    content: json['content'] as String,
    subject: json['subject'] as String? ?? '',
    topic: json['topic'] as String? ?? '',
    subtopic: json['subtopic'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const [],
    imageBase64: json['imageBase64'] as String?,
    imageName: json['imageName'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.now(),
  );

  NoteModel copyWith({
    String? noteId,
    String? userId,
    String? title,
    String? content,
    String? subject,
    String? topic,
    String? subtopic,
    List<String>? tags,
    String? imageBase64,
    String? imageName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      noteId: noteId ?? this.noteId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      tags: tags ?? this.tags,
      imageBase64: imageBase64 ?? this.imageBase64,
      imageName: imageName ?? this.imageName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

