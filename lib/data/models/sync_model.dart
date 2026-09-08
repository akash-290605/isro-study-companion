enum SyncStatus {
  synced,
  syncing,
  localOnly,
  offline;

  String get label {
    switch (this) {
      case SyncStatus.synced:
        return '✓ Synced';
      case SyncStatus.syncing:
        return '⟳ Syncing...';
      case SyncStatus.localOnly:
        return '✓ Saved Locally';
      case SyncStatus.offline:
        return 'Offline (Saved)';
    }
  }
}

enum QueuedActionType {
  create,
  update,
  delete;
}

class QueuedActionModel {
  final String actionId;
  final QueuedActionType actionType;
  final String collectionName;
  final String documentId;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  const QueuedActionModel({
    required this.actionId,
    required this.actionType,
    required this.collectionName,
    required this.documentId,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'actionId': actionId,
    'actionType': actionType.name,
    'collectionName': collectionName,
    'documentId': documentId,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
  };

  factory QueuedActionModel.fromJson(Map<String, dynamic> json) =>
      QueuedActionModel(
        actionId: json['actionId'] as String,
        actionType: QueuedActionType.values.firstWhere(
          (e) => e.name == json['actionType'],
          orElse: () => QueuedActionType.update,
        ),
        collectionName: json['collectionName'] as String,
        documentId: json['documentId'] as String,
        payload: json['payload'] as Map<String, dynamic>? ?? {},
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
      );
}

