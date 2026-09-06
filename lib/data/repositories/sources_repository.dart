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
    if (_sources.isEmpty) {
      // Provide foundational starter study materials strictly tagged
      final doc1Id = 'starter_doc_network_theory';
      final doc1Text = '''
Page 1: Network Theory Fundamentals
Section: Mesh Analysis and Nodal Analysis
Kirchhoff's Current Law states that at any node in an electrical circuit, the sum of currents entering the node is equal to the sum of currents leaving the node.
Kirchhoff's Voltage Law states that the directed sum of electrical potential differences around any closed circuit loop is equal to zero.
In Mesh Analysis, mesh currents are assigned to each planar loop, and KVL equations are formulated. The number of independent mesh equations required is given by b - n + 1, where b is the number of branches and n is the number of nodes.

Page 2: Network Theorems
Section: Thevenin and Norton Equivalents
Thevenin's Theorem states that any linear bilateral network across two terminals can be replaced by an equivalent voltage source Vth in series with an equivalent resistance Rth.
Vth is the open-circuit voltage across the terminals.
Rth is the input impedance looking into the terminals with all independent sources turned off (voltage sources shorted, current sources opened).
Norton's Theorem replaces the network with an equivalent current source IN in parallel with RN, where IN = Vth / Rth and RN = Rth.
Maximum Power Transfer Theorem: Maximum power is transferred from a source to a load when the load impedance ZL is equal to the complex conjugate of the source internal impedance Zs (i.e., ZL = Zs*). For purely resistive circuits, RL = Rth.
Maximum efficiency under maximum power transfer condition is exactly 50%.
''';

      final doc2Id = 'starter_doc_digital_electronics';
      final doc2Text = '''
Page 1: Boolean Minimization & Gates
Section: Logic Gates & Universal Realization
NAND and NOR gates are universal gates because any Boolean function can be realized using only NAND or only NOR gates.
De Morgan's laws state that the complement of a union is the intersection of the complements, and the complement of an intersection is the union of the complements.
A 2-to-1 Multiplexer has two data inputs (I0, I1), one select line (S), and output Y = S' I0 + S I1.
Any Boolean function of n variables can be implemented using a 2^(n-1)-to-1 multiplexer with no additional external gates.

Page 2: Sequential Logic & Flip-Flops
Section: Flip-Flops and Counters
An SR latch has an invalid condition when both S and R inputs are logic 1.
A JK flip-flop eliminates the invalid state of the SR flip-flop by toggling output when J = 1 and K = 1.
Race-around condition occurs in level-triggered JK flip-flops when clock pulse duration tp is greater than propagation delay of the flip-flop Δt, and J = K = 1.
It is prevented using Master-Slave JK flip-flop or edge-triggering.
A Mod-N counter requires n flip-flops where 2^(n-1) <= N <= 2^n.
''';

      final doc1Chunks = TextChunker.chunkText(
        sourceId: doc1Id,
        text: doc1Text,
        topic: 'Network Analysis',
      );

      final doc2Chunks = TextChunker.chunkText(
        sourceId: doc2Id,
        text: doc2Text,
        topic: 'Boolean Algebra & Combinational Circuits',
      );

      _sources = [
        SourceDocumentModel(
          sourceId: doc1Id,
          userId: userId,
          sourceType: SourceType.pdf,
          sourceName: 'Network Theory Notes.pdf',
          subject: 'Network Theory',
          topic: 'Network Analysis',
          subtopic: 'KCL, KVL & Node/Mesh Analysis',
          pageCount: 2,
          rawText: doc1Text,
          chunks: doc1Chunks,
          uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        SourceDocumentModel(
          sourceId: doc2Id,
          userId: userId,
          sourceType: SourceType.document,
          sourceName: 'Digital Electronics Principles.doc',
          subject: 'Digital Electronics',
          topic: 'Boolean Algebra & Combinational Circuits',
          subtopic: 'K-Maps & Logic Gate Minimization',
          pageCount: 2,
          rawText: doc2Text,
          chunks: doc2Chunks,
          uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

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
}

