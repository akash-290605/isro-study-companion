import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/utils/text_chunker.dart';
import '../models/source_model.dart';
import '../models/sync_model.dart';

class SourcesRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<SourceDocumentModel> _sources = [];
  String? _currentUserId;

  SourcesRepository(this._storage);

  List<SourceDocumentModel> get sources => _sources;

  void loadForUser(String userId) {
    _currentUserId = userId;
    _sources = _storage.getSources(userId);
    // Purge any inbuilt/starter sources
    final beforeCount = _sources.length;
    _sources.removeWhere((s) => s.sourceId.startsWith('starter_doc_'));
    if (_sources.length != beforeCount) {
      _storage.saveSources(userId, _sources);
    }
    notifyListeners();
  }

  List<SourceDocumentModel> searchSources(String query) {
    if (query.trim().isEmpty) return _sources;
    final q = query.toLowerCase().trim();
    return _sources.where((s) {
      return s.sourceName.toLowerCase().contains(q) ||
          s.subject.toLowerCase().contains(q) ||
          s.topic.toLowerCase().contains(q);
    }).toList();
  }

  Future<SourceDocumentModel> addManualTextSource({
    required String name,
    required String content,
    required String subject,
    required String topic,
    String? subtopic,
  }) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    final sourceId = const Uuid().v4();
    final chunks = TextChunker.chunkText(
      sourceId: sourceId,
      text: content,
      topic: topic,
    );

    final doc = SourceDocumentModel(
      sourceId: sourceId,
      userId: _currentUserId!,
      sourceType: SourceType.manualText,
      sourceName: name.trim().isEmpty ? 'Manual Text Notes' : name.trim(),
      subject: subject,
      topic: topic,
      subtopic: subtopic,
      pageCount: (chunks.length / 2).ceil().clamp(1, 999),
      rawText: content,
      chunks: chunks,
      uploadedAt: DateTime.now(),
    );

    _sources.insert(0, doc);
    await _storage.saveSources(_currentUserId!, _sources);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.create,
        collectionName: 'sources',
        documentId: doc.sourceId,
        payload: doc.toJson(),
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
    return doc;
  }

  Future<SourceDocumentModel> addUrlSource({
    required String url,
    required String subject,
    required String topic,
    String? subtopic,
  }) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    String extractedText = '';
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Strip basic HTML tags strictly without contacting external search engines
        final body = response.body;
        extractedText = body
            .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
            .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      } else {
        throw Exception('Unable to access this URL. Please upload the material instead.');
      }
    } catch (_) {
      throw Exception('Unable to access this URL. Please upload the material instead.');
    }

    if (extractedText.isEmpty) {
      throw Exception('Unable to access this URL. Please upload the material instead.');
    }

    final sourceId = const Uuid().v4();
    final chunks = TextChunker.chunkText(
      sourceId: sourceId,
      text: extractedText,
      defaultSection: 'Web Source Content',
      topic: topic,
    );

    final doc = SourceDocumentModel(
      sourceId: sourceId,
      userId: _currentUserId!,
      sourceType: SourceType.url,
      sourceName: url,
      sourceURL: url,
      subject: subject,
      topic: topic,
      subtopic: subtopic,
      pageCount: (chunks.length / 2).ceil().clamp(1, 999),
      rawText: extractedText,
      chunks: chunks,
      uploadedAt: DateTime.now(),
    );

    _sources.insert(0, doc);
    await _storage.saveSources(_currentUserId!, _sources);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.create,
        collectionName: 'sources',
        documentId: doc.sourceId,
        payload: doc.toJson(),
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
    return doc;
  }

  Future<void> deleteSource(String sourceId) async {
    if (_currentUserId == null) return;
    _sources.removeWhere((s) => s.sourceId == sourceId);
    await _storage.saveSources(_currentUserId!, _sources);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.delete,
        collectionName: 'sources',
        documentId: sourceId,
        payload: {},
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> renameSource(String sourceId, String newName) async {
    if (_currentUserId == null) return;
    final index = _sources.indexWhere((s) => s.sourceId == sourceId);
    if (index >= 0) {
      _sources[index] = _sources[index].copyWith(sourceName: newName.trim());
      await _storage.saveSources(_currentUserId!, _sources);
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.update,
          collectionName: 'sources',
          documentId: sourceId,
          payload: {'sourceName': newName.trim()},
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> clearAllSources() async {
    if (_currentUserId == null) return;
    _sources.clear();
    await _storage.saveSources(_currentUserId!, _sources);
    notifyListeners();
  }
}

