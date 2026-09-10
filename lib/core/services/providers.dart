import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/flashcards_repository.dart';
import '../../data/repositories/formula_repository.dart';
import '../../data/repositories/mistakes_repository.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/repositories/questions_repository.dart';
import '../../data/repositories/revision_repository.dart';
import '../../data/repositories/sources_repository.dart';
import '../../data/repositories/study_sessions_repository.dart';
import '../../data/repositories/syllabus_repository.dart';
import '../../data/repositories/test_repository.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('Initialize in main()');
});

final syncServiceProvider = ChangeNotifierProvider<SyncService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final syncService = SyncService(storage);
  syncService.onDataRestored = (uid) {
    try {
      ref.read(formulaRepositoryProvider).loadForUser(uid);
      ref.read(notesRepositoryProvider).loadForUser(uid);
      ref.read(questionsRepositoryProvider).loadForUser(uid);
      ref.read(syllabusRepositoryProvider).loadForUser(uid);
      ref.read(flashcardsRepositoryProvider).loadForUser(uid);
      ref.read(mistakesRepositoryProvider).loadForUser(uid);
      ref.read(sourcesRepositoryProvider).loadForUser(uid);
      ref.read(testRepositoryProvider).loadForUser(uid);
    } catch (_) {}
  };
  return syncService;
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final authRepositoryProvider = ChangeNotifierProvider<AuthRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return AuthRepository(storage);
});

final syllabusRepositoryProvider =
    ChangeNotifierProvider<SyllabusRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final auth = ref.watch(authRepositoryProvider);
  final repo = SyllabusRepository(storage);
  if (auth.currentUser != null) {
    repo.loadForUser(auth.currentUser!.id);
  }
  return repo;
});

final notesRepositoryProvider = ChangeNotifierProvider<NotesRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final auth = ref.watch(authRepositoryProvider);
  final repo = NotesRepository(storage);
  if (auth.currentUser != null) {
    repo.loadForUser(auth.currentUser!.id);
  }
  return repo;
});

final sourcesRepositoryProvider =
    ChangeNotifierProvider<SourcesRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final auth = ref.watch(authRepositoryProvider);
  final repo = SourcesRepository(storage);
  if (auth.currentUser != null) {
    repo.loadForUser(auth.currentUser!.id);
  }
  return repo;
});

final questionsRepositoryProvider =
    ChangeNotifierProvider<QuestionsRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final auth = ref.watch(authRepositoryProvider);
  final repo = QuestionsRepository(storage);
  if (auth.currentUser != null) {
    repo.loadForUser(auth.currentUser!.id);
  }
  return repo;
});

final testRepositoryProvider = ChangeNotifierProvider<TestRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final auth = ref.watch(authRepositoryProvider);
  final repo = TestRepository(storage);
  if (auth.currentUser != null) {
    repo.loadForUser(auth.currentUser!.id);
  }
  return repo;
});

final mistakesRepositoryProvider =
    ChangeNotifierProvider<MistakesRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final auth = ref.watch(authRepositoryProvider);
  final repo = MistakesRepository(storage);
  if (auth.currentUser != null) {
    repo.loadForUser(auth.currentUser!.id);
  }
  return repo;
});

final flashcardsRepositoryProvider =
    ChangeNotifierProvider<FlashcardsRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final auth = ref.watch(authRepositoryProvider);
  final repo = FlashcardsRepository(storage);
  if (auth.currentUser != null) {
    repo.loadForUser(auth.currentUser!.id);
  }
  return repo;
});

final formulaRepositoryProvider =
    ChangeNotifierProvider<FormulaRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final auth = ref.watch(authRepositoryProvider);
  final repo = FormulaRepository(storage);
  if (auth.currentUser != null) {
    repo.loadForUser(auth.currentUser!.id);
  }
  return repo;
});

final studySessionsRepositoryProvider =
    ChangeNotifierProvider<StudySessionsRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final auth = ref.watch(authRepositoryProvider);
  final repo = StudySessionsRepository(storage);
  if (auth.currentUser != null) {
    repo.loadForUser(auth.currentUser!.id);
  }
  return repo;
});

final revisionRepositoryProvider =
    ChangeNotifierProvider<RevisionRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final auth = ref.watch(authRepositoryProvider);
  final repo = RevisionRepository(storage);
  if (auth.currentUser != null) {
    repo.loadForUser(auth.currentUser!.id);
  }
  return repo;
});

