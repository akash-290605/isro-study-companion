import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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
    // Purge any inbuilt/starter sources and locally hidden items
    final hidden = _storage.getHiddenItemIds(userId, 'sources');
    _sources.removeWhere((s) => s.sourceId.startsWith('starter_doc_') || hidden.contains(s.sourceId));
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

  Future<void> addSource(SourceDocumentModel doc) async {
    if (_currentUserId == null) return;
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

    String targetUrl = url.trim();
    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
      targetUrl = 'https://$targetUrl';
    }

    final parsedUri = Uri.tryParse(targetUrl);
    if (parsedUri == null || !parsedUri.hasScheme || parsedUri.host.isEmpty) {
      throw Exception('Invalid URL. Please enter a valid address (e.g. https://example.com/notes).');
    }

    String extractedText = '';
    final headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,text/plain;q=0.8,*/*;q=0.7',
      'Accept-Language': 'en-US,en;q=0.9',
    };

    String cleanHtml(String body) {
      return body
          .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<nav[\s\S]*?</nav>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<header[\s\S]*?</header>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<footer[\s\S]*?</footer>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
          .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'&amp;', caseSensitive: false), '&')
          .replaceAll(RegExp(r'&lt;', caseSensitive: false), '<')
          .replaceAll(RegExp(r'&gt;', caseSensitive: false), '>')
          .replaceAll(RegExp(r'&quot;', caseSensitive: false), '"')
          .replaceAll(RegExp(r'&#39;|&apos;', caseSensitive: false), "'")
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    // Step 1: Direct Fetch (works on mobile/desktop, or web with CORS)
    try {
      final response = await http
          .get(parsedUri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        extractedText = cleanHtml(response.body);
      }
    } catch (_) {
      // Direct fetch might fail on web due to CORS; proceed to proxies
    }

    // Step 2: If empty or failed, try CORS proxy (vital on Flutter Web)
    if (extractedText.isEmpty) {
      try {
        final proxyUri = Uri.parse(
          'https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}',
        );
        final proxyResponse = await http
            .get(proxyUri)
            .timeout(const Duration(seconds: 12));
        if (proxyResponse.statusCode >= 200 && proxyResponse.statusCode < 300) {
          extractedText = cleanHtml(proxyResponse.body);
        }
      } catch (_) {
        // Fallback proxy 2
        try {
          final fallbackProxyUri = Uri.parse(
            'https://corsproxy.io/?url=${Uri.encodeComponent(targetUrl)}',
          );
          final fbResponse = await http
              .get(fallbackProxyUri)
              .timeout(const Duration(seconds: 12));
          if (fbResponse.statusCode >= 200 && fbResponse.statusCode < 300) {
            extractedText = cleanHtml(fbResponse.body);
          }
        } catch (_) {}
      }
    }

    if (extractedText.trim().isEmpty || extractedText.length < 20) {
      throw Exception(
        'Unable to extract article text from this website. The site may block automated access or require login. Please copy the text and use the "Manual Text Entry" section below.',
      );
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
  Future<void> deleteSource(
    String sourceId, {
    bool permanent = true,
    bool deleteAssociatedQuestions = false,
    List<String>? associatedQuestionIds,
  }) async {
    if (_currentUserId == null) return;

    if (permanent) {
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
      try {
        if (Firebase.apps.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserId!)
              .collection('sources')
              .doc(sourceId)
              .delete();
        }
      } catch (_) {}

      if (deleteAssociatedQuestions && associatedQuestionIds != null && associatedQuestionIds.isNotEmpty) {
        final localQuestions = _storage.getQuestions(_currentUserId!);
        localQuestions.removeWhere((q) => associatedQuestionIds.contains(q.questionId));
        await _storage.saveQuestions(_currentUserId!, localQuestions);

        for (final qId in associatedQuestionIds) {
          await _storage.enqueueAction(
            _currentUserId!,
            QueuedActionModel(
              actionId: const Uuid().v4(),
              actionType: QueuedActionType.delete,
              collectionName: 'questions',
              documentId: qId,
              payload: {},
              timestamp: DateTime.now(),
            ),
          );
          try {
            if (Firebase.apps.isNotEmpty) {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(_currentUserId!)
                  .collection('questions')
                  .doc(qId)
                  .delete();
            }
          } catch (_) {}
        }
      }
    } else {
      await _storage.hideItemLocally(_currentUserId!, 'sources', sourceId);
      _sources.removeWhere((s) => s.sourceId == sourceId);
      await _storage.saveSources(_currentUserId!, _sources);

      if (deleteAssociatedQuestions && associatedQuestionIds != null) {
        for (final qId in associatedQuestionIds) {
          await _storage.hideItemLocally(_currentUserId!, 'questions', qId);
        }
        final localQuestions = _storage.getQuestions(_currentUserId!);
        localQuestions.removeWhere((q) => associatedQuestionIds.contains(q.questionId));
        await _storage.saveQuestions(_currentUserId!, localQuestions);
      }
    }
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

