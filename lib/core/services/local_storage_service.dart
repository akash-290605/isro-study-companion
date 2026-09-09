import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/sync_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/syllabus_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/source_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/test_model.dart';
import '../../data/models/test_result_model.dart';
import '../../data/models/mistake_model.dart';
import '../../data/models/flashcard_model.dart';
import '../../data/models/formula_model.dart';
import '../../data/models/study_session_model.dart';
import '../../data/models/revision_model.dart';

/// Manages local offline persistent storage via SharedPreferences.
/// Ensures all user data is isolated per userId and available without network.
class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // --- Auth & Current User ---
  static const _kCurrentUserId = 'current_user_id';

  String? getCurrentUserId() => _prefs.getString(_kCurrentUserId);

  Future<void> setCurrentUserId(String? userId) async {
    if (userId == null) {
      await _prefs.remove(_kCurrentUserId);
    } else {
      await _prefs.setString(_kCurrentUserId, userId);
    }
  }

  // --- Account Credentials (Secure password check) ---
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode('isro_salt_2026_${password.trim()}')).toString();
  }

  String _credKey(String email) => 'cred_${email.trim().toLowerCase()}';

  Future<void> saveCredentials(String email, String passwordHash, String userId) async {
    final payload = {
      'email': email.trim().toLowerCase(),
      'passwordHash': passwordHash,
      'userId': userId,
    };
    await _prefs.setString(_credKey(email), jsonEncode(payload));
  }

  bool hasAccount(String email) {
    final clean = email.trim().toLowerCase();
    if (clean == 'isro_aspirant@companion.edu') return true;
    return _prefs.containsKey(_credKey(clean));
  }

  Map<String, String>? getCredentials(String email) {
    final clean = email.trim().toLowerCase();
    final raw = _prefs.getString(_credKey(clean));
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        'email': map['email'] as String? ?? clean,
        'passwordHash': map['passwordHash'] as String? ?? '',
        'userId': map['userId'] as String? ?? '',
      };
    }
    // Default seeded starter account
    if (clean == 'isro_aspirant@companion.edu') {
      return {
        'email': clean,
        'passwordHash': hashPassword('isro2026'),
        'userId': 'starter_user_isro_aspirant',
      };
    }
    return null;
  }

  String? verifyPassword(String email, String plainPassword) {
    final creds = getCredentials(email);
    if (creds == null) return null;
    final expectedHash = creds['passwordHash'];
    final computedHash = hashPassword(plainPassword);
    if (expectedHash == computedHash) {
      return creds['userId'];
    }
    return null;
  }

  // --- User Profile ---
  String _userKey(String uid) => 'user_profile_$uid';

  UserModel? getUser(String uid) {
    final raw = _prefs.getString(_userKey(uid));
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(_userKey(user.id), jsonEncode(user.toJson()));
  }

  // --- Syllabus Subjects ---
  String _syllabusKey(String uid) => 'syllabus_$uid';

  List<SyllabusSubject> getSyllabus(String uid) {
    final raw = _prefs.getString(_syllabusKey(uid));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => SyllabusSubject.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSyllabus(String uid, List<SyllabusSubject> subjects) async {
    await _prefs.setString(
      _syllabusKey(uid),
      jsonEncode(subjects.map((e) => e.toJson()).toList()),
    );
  }

  // --- Notes ---
  String _notesKey(String uid) => 'notes_$uid';

  List<NoteModel> getNotes(String uid) {
    final raw = _prefs.getString(_notesKey(uid));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveNotes(String uid, List<NoteModel> notes) async {
    await _prefs.setString(
      _notesKey(uid),
      jsonEncode(notes.map((e) => e.toJson()).toList()),
    );
  }

  // --- Sources ---
  String _sourcesKey(String uid) => 'sources_$uid';

  List<SourceDocumentModel> getSources(String uid) {
    final raw = _prefs.getString(_sourcesKey(uid));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => SourceDocumentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSources(String uid, List<SourceDocumentModel> sources) async {
    await _prefs.setString(
      _sourcesKey(uid),
      jsonEncode(sources.map((e) => e.toJson()).toList()),
    );
  }

  // --- Question Bank ---
  String _questionsKey(String uid) => 'questions_$uid';

  List<QuestionModel> getQuestions(String uid) {
    final raw = _prefs.getString(_questionsKey(uid));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => QuestionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveQuestions(String uid, List<QuestionModel> questions) async {
    await _prefs.setString(
      _questionsKey(uid),
      jsonEncode(questions.map((e) => e.toJson()).toList()),
    );
  }

  // --- Tests ---
  String _testsKey(String uid) => 'tests_$uid';

  List<TestModel> getTests(String uid) {
    final raw = _prefs.getString(_testsKey(uid));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => TestModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveTests(String uid, List<TestModel> tests) async {
    await _prefs.setString(
      _testsKey(uid),
      jsonEncode(tests.map((e) => e.toJson()).toList()),
    );
  }

  // --- Test Results ---
  String _testResultsKey(String uid) => 'test_results_$uid';

  List<TestResultModel> getTestResults(String uid) {
    final raw = _prefs.getString(_testResultsKey(uid));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => TestResultModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveTestResults(String uid, List<TestResultModel> results) async {
    await _prefs.setString(
      _testResultsKey(uid),
      jsonEncode(results.map((e) => e.toJson()).toList()),
    );
  }

  // --- Mistakes ---
  String _mistakesKey(String uid) => 'mistakes_$uid';

  List<MistakeModel> getMistakes(String uid) {
    final raw = _prefs.getString(_mistakesKey(uid));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => MistakeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveMistakes(String uid, List<MistakeModel> mistakes) async {
    await _prefs.setString(
      _mistakesKey(uid),
      jsonEncode(mistakes.map((e) => e.toJson()).toList()),
    );
  }

  // --- Flashcards ---
  String _flashcardsKey(String uid) => 'flashcards_$uid';

  List<FlashcardModel> getFlashcards(String uid) {
    final raw = _prefs.getString(_flashcardsKey(uid));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => FlashcardModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveFlashcards(String uid, List<FlashcardModel> cards) async {
    await _prefs.setString(
      _flashcardsKey(uid),
      jsonEncode(cards.map((e) => e.toJson()).toList()),
    );
  }

  // --- Formulas ---
  String _formulasKey(String uid) => 'formulas_$uid';

  List<FormulaModel> getFormulas(String uid) {
    final raw = _prefs.getString(_formulasKey(uid));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => FormulaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveFormulas(String uid, List<FormulaModel> formulas) async {
    await _prefs.setString(
      _formulasKey(uid),
      jsonEncode(formulas.map((e) => e.toJson()).toList()),
    );
  }

  // --- Study Sessions (Timer) ---
  String _sessionsKey(String uid) => 'study_sessions_$uid';

  List<StudySessionModel> getStudySessions(String uid) {
    final raw = _prefs.getString(_sessionsKey(uid));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => StudySessionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveStudySessions(String uid, List<StudySessionModel> sessions) async {
    await _prefs.setString(
      _sessionsKey(uid),
      jsonEncode(sessions.map((e) => e.toJson()).toList()),
    );
  }

  // --- Revision Sessions ---
  String _revisionsKey(String uid) => 'revisions_$uid';

  List<RevisionSessionModel> getRevisions(String uid) {
    final raw = _prefs.getString(_revisionsKey(uid));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => RevisionSessionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveRevisions(String uid, List<RevisionSessionModel> sessions) async {
    await _prefs.setString(
      _revisionsKey(uid),
      jsonEncode(sessions.map((e) => e.toJson()).toList()),
    );
  }

  // --- Sync Queue ---
  String _syncQueueKey(String uid) => 'sync_queue_$uid';

  List<QueuedActionModel> getSyncQueue(String uid) {
    final raw = _prefs.getString(_syncQueueKey(uid));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => QueuedActionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> enqueueAction(String uid, QueuedActionModel action) async {
    final queue = getSyncQueue(uid);
    queue.add(action);
    await _prefs.setString(
      _syncQueueKey(uid),
      jsonEncode(queue.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> removeQueuedAction(String uid, String actionId) async {
    final queue = getSyncQueue(uid);
    queue.removeWhere((a) => a.actionId == actionId);
    await _prefs.setString(
      _syncQueueKey(uid),
      jsonEncode(queue.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> purgeInbuiltData(String uid) async {
    // Purge starter notes
    final notes = getNotes(uid)..removeWhere((n) => n.noteId.startsWith('starter_note'));
    await saveNotes(uid, notes);

    // Purge starter sources
    final sources = getSources(uid)..removeWhere((s) => s.sourceId.startsWith('starter_doc_'));
    await saveSources(uid, sources);

    // Purge starter questions
    final questions = getQuestions(uid)..removeWhere((q) =>
        q.questionId.startsWith('q_nt_') ||
        q.questionId.startsWith('q_de_') ||
        q.sourceId.startsWith('starter_doc_'));
    await saveQuestions(uid, questions);

    // Purge starter flashcards
    final cards = getFlashcards(uid)..removeWhere((c) =>
        c.cardId.startsWith('fc_') ||
        c.sourceId.startsWith('starter_doc_'));
    await saveFlashcards(uid, cards);

    // Purge starter formulas
    final formulas = getFormulas(uid)..removeWhere((f) =>
        f.formulaId.startsWith('form_') ||
        f.sourceId.startsWith('starter_doc_'));
    await saveFormulas(uid, formulas);

    // Purge starter sessions
    final sessions = getStudySessions(uid)..removeWhere((s) => s.sessionId.startsWith('session_'));
    await saveStudySessions(uid, sessions);

    // Purge starter revisions
    final revisions = getRevisions(uid)..removeWhere((r) => r.sessionId.startsWith('rev_'));
    await saveRevisions(uid, revisions);
  }

  Future<void> clearAllStudyData(String uid) async {
    await _prefs.remove(_notesKey(uid));
    await _prefs.remove(_sourcesKey(uid));
    await _prefs.remove(_questionsKey(uid));
    await _prefs.remove(_testsKey(uid));
    await _prefs.remove(_testResultsKey(uid));
    await _prefs.remove(_mistakesKey(uid));
    await _prefs.remove(_flashcardsKey(uid));
    await _prefs.remove(_formulasKey(uid));
    await _prefs.remove(_sessionsKey(uid));
    await _prefs.remove(_revisionsKey(uid));
  }

  Future<void> clearUserData(String uid) async {
    await _prefs.remove(_userKey(uid));
    await _prefs.remove(_syllabusKey(uid));
    await _prefs.remove(_notesKey(uid));
    await _prefs.remove(_sourcesKey(uid));
    await _prefs.remove(_questionsKey(uid));
    await _prefs.remove(_testsKey(uid));
    await _prefs.remove(_testResultsKey(uid));
    await _prefs.remove(_mistakesKey(uid));
    await _prefs.remove(_flashcardsKey(uid));
    await _prefs.remove(_formulasKey(uid));
    await _prefs.remove(_sessionsKey(uid));
    await _prefs.remove(_revisionsKey(uid));
    await _prefs.remove(_syncQueueKey(uid));
  }
}

