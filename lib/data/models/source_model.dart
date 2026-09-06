enum SourceType {
  pdf,
  document,
  questionImage,
  questionPaper,
  note,
  url,
  manualText;

  String get label {
    switch (this) {
      case SourceType.pdf:
        return 'PDF';
      case SourceType.document:
        return 'Document';
      case SourceType.questionImage:
        return 'Question Image';
      case SourceType.questionPaper:
        return 'Question Paper';
      case SourceType.note:
        return 'Note';
      case SourceType.url:
        return 'URL';
      case SourceType.manualText:
        return 'Manual Text';
    }
  }
}

enum ProcessedStatus {
  pending,
  processing,
  processed,
  error;

  String get label {
    switch (this) {
      case ProcessedStatus.pending:
        return 'Pending';
      case ProcessedStatus.processing:
        return 'Processing...';
      case ProcessedStatus.processed:
        return 'Ready';
      case ProcessedStatus.error:
        return 'Error';
    }
  }
}

class SourceChunkModel {
  final String chunkId;
  final String sourceId;
  final int pageNumber;
  final String section;
  final String content;
  final String topic;

  const SourceChunkModel({
    required this.chunkId,
    required this.sourceId,
    this.pageNumber = 1,
    this.section = 'General',
    required this.content,
    this.topic = '',
  });

  Map<String, dynamic> toJson() => {
    'chunkId': chunkId,
    'sourceId': sourceId,
    'pageNumber': pageNumber,
    'section': section,
    'content': content,
    'topic': topic,
  };

  factory SourceChunkModel.fromJson(Map<String, dynamic> json) =>
      SourceChunkModel(
        chunkId: json['chunkId'] as String,
        sourceId: json['sourceId'] as String,
        pageNumber: json['pageNumber'] as int? ?? 1,
        section: json['section'] as String? ?? 'General',
        content: json['content'] as String,
        topic: json['topic'] as String? ?? '',
      );
}

class SourceDocumentModel {
  final String sourceId;
  final String userId;
  final SourceType sourceType;
  final String sourceName;
  final String? sourceURL;
  final String? filePath;
  final DateTime uploadedAt;
  final String subject;
  final String topic;
  final String? subtopic;
  final ProcessedStatus processedStatus;
  final int pageCount;
  final List<SourceChunkModel> chunks;
  final String rawText;

  const SourceDocumentModel({
    required this.sourceId,
    required this.userId,
    required this.sourceType,
    required this.sourceName,
    this.sourceURL,
    this.filePath,
    required this.uploadedAt,
    this.subject = '',
    this.topic = '',
    this.subtopic,
    this.processedStatus = ProcessedStatus.processed,
    this.pageCount = 1,
    this.chunks = const [],
    this.rawText = '',
  });

  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'userId': userId,
    'sourceType': sourceType.name,
    'sourceName': sourceName,
    'sourceURL': sourceURL,
    'filePath': filePath,
    'uploadedAt': uploadedAt.toIso8601String(),
    'subject': subject,
    'topic': topic,
    'subtopic': subtopic,
    'processedStatus': processedStatus.name,
    'pageCount': pageCount,
    'chunks': chunks.map((c) => c.toJson()).toList(),
    'rawText': rawText,
  };

  factory SourceDocumentModel.fromJson(Map<String, dynamic> json) =>
      SourceDocumentModel(
        sourceId: json['sourceId'] as String,
        userId: json['userId'] as String,
        sourceType: SourceType.values.firstWhere(
          (e) => e.name == json['sourceType'],
          orElse: () => SourceType.document,
        ),
        sourceName: json['sourceName'] as String,
        sourceURL: json['sourceURL'] as String?,
        filePath: json['filePath'] as String?,
        uploadedAt: json['uploadedAt'] != null
            ? DateTime.parse(json['uploadedAt'] as String)
            : DateTime.now(),
        subject: json['subject'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
        subtopic: json['subtopic'] as String?,
        processedStatus: ProcessedStatus.values.firstWhere(
          (e) => e.name == json['processedStatus'],
          orElse: () => ProcessedStatus.processed,
        ),
        pageCount: json['pageCount'] as int? ?? 1,
        chunks: (json['chunks'] as List<dynamic>?)
                ?.map((e) => SourceChunkModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        rawText: json['rawText'] as String? ?? '',
      );

  SourceDocumentModel copyWith({
    String? sourceId,
    String? userId,
    SourceType? sourceType,
    String? sourceName,
    String? sourceURL,
    String? filePath,
    DateTime? uploadedAt,
    String? subject,
    String? topic,
    String? subtopic,
    ProcessedStatus? processedStatus,
    int? pageCount,
    List<SourceChunkModel>? chunks,
    String? rawText,
  }) {
    return SourceDocumentModel(
      sourceId: sourceId ?? this.sourceId,
      userId: userId ?? this.userId,
      sourceType: sourceType ?? this.sourceType,
      sourceName: sourceName ?? this.sourceName,
      sourceURL: sourceURL ?? this.sourceURL,
      filePath: filePath ?? this.filePath,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      processedStatus: processedStatus ?? this.processedStatus,
      pageCount: pageCount ?? this.pageCount,
      chunks: chunks ?? this.chunks,
      rawText: rawText ?? this.rawText,
    );
  }
}

