import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/local_storage_service.dart';
import '../models/formula_model.dart';
import '../models/sync_model.dart';

class FormulaRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  List<FormulaModel> _formulas = [];
  String? _currentUserId;

  FormulaRepository(this._storage);

  List<FormulaModel> get formulas => _formulas;

  void loadForUser(String userId) {
    _currentUserId = userId;
    _formulas = _storage.getFormulas(userId);
    if (_formulas.isEmpty) {
      _formulas = [
        FormulaModel(
          formulaId: 'form_01',
          userId: userId,
          subject: 'Network Theory',
          topic: 'Network Analysis',
          title: 'Kirchhoff\'s Current Law (KCL)',
          latexExpression: r'\sum_{k=1}^{n} I_k = 0',
          description: 'Sum of algebraic currents entering a junction is zero.',
          sourceId: 'starter_doc_network_theory',
          sourceName: 'Network Theory Notes.pdf',
          sourceLocation: 'Page 1, Mesh Analysis',
          isFavorite: true,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        FormulaModel(
          formulaId: 'form_02',
          userId: userId,
          subject: 'Network Theory',
          topic: 'Network Analysis',
          title: 'Maximum Power Transfer Efficiency',
          latexExpression: r'\eta = \frac{P_L}{P_{total}} = \frac{I^2 R_L}{I^2 (R_{th} + R_L)} = 50\%',
          description: 'Occurs when load impedance equals conjugate source impedance.',
          sourceId: 'starter_doc_network_theory',
          sourceName: 'Network Theory Notes.pdf',
          sourceLocation: 'Page 2, Thevenin and Norton Equivalents',
          isFavorite: true,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        FormulaModel(
          formulaId: 'form_03',
          userId: userId,
          subject: 'Digital Electronics',
          topic: 'Boolean Algebra & Combinational Circuits',
          title: 'De Morgan\'s First Law',
          latexExpression: r'\overline{A + B} = \overline{A} \cdot \overline{B}',
          description: 'Complement of a sum equals product of individual complements.',
          sourceId: 'starter_doc_digital_electronics',
          sourceName: 'Digital Electronics Principles.doc',
          sourceLocation: 'Page 1, Logic Gates',
          isFavorite: false,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        FormulaModel(
          formulaId: 'form_04',
          userId: userId,
          subject: 'Digital Electronics',
          topic: 'Boolean Algebra & Combinational Circuits',
          title: 'Mod-N Counter Flip-Flop Formula',
          latexExpression: r'2^{n-1} \le N \le 2^n',
          description: 'Calculates the minimum flip-flops required for a Mod-N counter.',
          sourceId: 'starter_doc_digital_electronics',
          sourceName: 'Digital Electronics Principles.doc',
          sourceLocation: 'Page 2, Flip-Flops and Counters',
          isFavorite: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
      _storage.saveFormulas(userId, _formulas);
    }
    notifyListeners();
  }

  List<FormulaModel> searchFormulas(String query) {
    if (query.trim().isEmpty) return _formulas;
    final q = query.toLowerCase().trim();
    return _formulas.where((f) {
      return f.title.toLowerCase().contains(q) ||
          f.subject.toLowerCase().contains(q) ||
          f.topic.toLowerCase().contains(q) ||
          f.description.toLowerCase().contains(q) ||
          f.latexExpression.toLowerCase().contains(q);
    }).toList();
  }

  List<FormulaModel> getFormulasBySubject(String subject) {
    return _formulas.where((f) => f.subject == subject).toList();
  }

  Future<void> addFormula(FormulaModel formula) async {
    if (_currentUserId == null) return;
    _formulas.insert(0, formula);
    await _storage.saveFormulas(_currentUserId!, _formulas);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.create,
        collectionName: 'formulas',
        documentId: formula.formulaId,
        payload: formula.toJson(),
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> toggleFavorite(String formulaId) async {
    if (_currentUserId == null) return;
    final index = _formulas.indexWhere((f) => f.formulaId == formulaId);
    if (index >= 0) {
      final updated = _formulas[index].copyWith(
        isFavorite: !_formulas[index].isFavorite,
      );
      _formulas[index] = updated;
      await _storage.saveFormulas(_currentUserId!, _formulas);
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.update,
          collectionName: 'formulas',
          documentId: formulaId,
          payload: {'isFavorite': updated.isFavorite},
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> deleteFormula(String formulaId) async {
    if (_currentUserId == null) return;
    _formulas.removeWhere((f) => f.formulaId == formulaId);
    await _storage.saveFormulas(_currentUserId!, _formulas);
    await _storage.enqueueAction(
      _currentUserId!,
      QueuedActionModel(
        actionId: const Uuid().v4(),
        actionType: QueuedActionType.delete,
        collectionName: 'formulas',
        documentId: formulaId,
        payload: {},
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}

