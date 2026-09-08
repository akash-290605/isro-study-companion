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
    // Purge any inbuilt/starter formulas
    final beforeCount = _formulas.length;
    _formulas.removeWhere((f) =>
        f.formulaId.startsWith('form_') ||
        f.sourceId.startsWith('starter_doc_'));
    if (_formulas.length != beforeCount) {
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

  Future<void> saveFormula(FormulaModel formula) async {
    if (_currentUserId == null) return;
    final index = _formulas.indexWhere((f) => f.formulaId == formula.formulaId);
    if (index >= 0) {
      _formulas[index] = formula;
      await _storage.saveFormulas(_currentUserId!, _formulas);
      await _storage.enqueueAction(
        _currentUserId!,
        QueuedActionModel(
          actionId: const Uuid().v4(),
          actionType: QueuedActionType.update,
          collectionName: 'formulas',
          documentId: formula.formulaId,
          payload: formula.toJson(),
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    } else {
      await addFormula(formula);
    }
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

  Future<void> clearAllFormulas() async {
    if (_currentUserId == null) return;
    _formulas.clear();
    await _storage.saveFormulas(_currentUserId!, _formulas);
    notifyListeners();
  }
}

