import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/local_storage_service.dart';
import '../models/user_model.dart';

class AuthRepository extends ChangeNotifier {
  final LocalStorageService _storage;
  UserModel? _currentUser;
  bool _isLoading = false;

  AuthRepository(this._storage) {
    _initCurrentUser();
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  void _initCurrentUser() {
    final uid = _storage.getCurrentUserId();
    if (uid != null) {
      _currentUser = _storage.getUser(uid);
      if (_currentUser != null) {
        // Update streak logic if needed
        _updateStreakIfNeeded();
      }
    }
    notifyListeners();
  }

  void _updateStreakIfNeeded() {
    if (_currentUser == null) return;
    final now = DateTime.now();
    final lastStudy = _currentUser!.lastStudyDate;

    if (lastStudy == null) return;

    final diffDays = DateTime(now.year, now.month, now.day)
        .difference(DateTime(lastStudy.year, lastStudy.month, lastStudy.day))
        .inDays;

    if (diffDays == 1) {
      // Streak continues
    } else if (diffDays > 1) {
      // Streak broken, reset to 1
      _currentUser = _currentUser!.copyWith(streakDays: 1);
      _storage.saveUser(_currentUser!);
    }
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      throw Exception('Please enter both your email and password.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Attempt Cloud Firebase Authentication if Firebase is available
      if (Firebase.apps.isNotEmpty) {
        try {
          final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPassword,
          );
          final fbUser = cred.user;
          if (fbUser != null) {
            var user = _storage.getUser(fbUser.uid);
            user ??= UserModel(
              id: fbUser.uid,
              email: fbUser.email ?? cleanEmail,
              displayName: fbUser.displayName ?? cleanEmail.split('@').first,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
            );
            _currentUser = user.copyWith(lastLoginAt: DateTime.now());
            await _storage.saveUser(_currentUser!);
            await _storage.setCurrentUserId(_currentUser!.id);
            // Cache credentials for verified offline continuity
            await _storage.saveCredentials(
              cleanEmail,
              LocalStorageService.hashPassword(cleanPassword),
              fbUser.uid,
            );

            _isLoading = false;
            notifyListeners();
            return;
          }
        } on FirebaseAuthException {
          // CRITICAL: Cloud server explicitly rejected credentials (wrong password, user not found, etc.)
          // Never swallow or bypass with a mock user!
          _isLoading = false;
          notifyListeners();
          rethrow;
        } catch (_) {
          // Non-auth error (e.g. network failure / connection refused)
          // Proceed to check if user has local verified credentials
        }
      }

      // 2. Strict Offline Authentication Verification
      final verifiedUserId = _storage.verifyPassword(cleanEmail, cleanPassword);
      if (verifiedUserId == null) {
        _isLoading = false;
        notifyListeners();
        if (_storage.hasAccount(cleanEmail)) {
          throw Exception('Incorrect password. Please verify your credentials.');
        } else {
          throw Exception('No account found for $cleanEmail. Please register first.');
        }
      }

      var user = _storage.getUser(verifiedUserId);
      user ??= UserModel(
        id: verifiedUserId,
        email: cleanEmail,
        displayName: cleanEmail.split('@').first,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        streakDays: 1,
      );

      _currentUser = user.copyWith(lastLoginAt: DateTime.now());
      await _storage.saveUser(_currentUser!);
      await _storage.setCurrentUserId(_currentUser!.id);
      _isLoading = false;
      notifyListeners();
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanName = displayName.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty || cleanName.isEmpty) {
      throw Exception('Full Name, Email, and Password are all required.');
    }
    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      throw Exception('Please enter a valid email address.');
    }
    if (cleanPassword.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Attempt Cloud Firebase Authentication Registration
      if (Firebase.apps.isNotEmpty) {
        try {
          final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPassword,
          );
          final fbUser = cred.user;
          if (fbUser != null) {
            await fbUser.updateDisplayName(cleanName);
            final user = UserModel(
              id: fbUser.uid,
              email: fbUser.email ?? cleanEmail,
              displayName: cleanName,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
            );
            _currentUser = user;
            await _storage.saveUser(_currentUser!);
            await _storage.setCurrentUserId(_currentUser!.id);
            await _storage.saveCredentials(
              cleanEmail,
              LocalStorageService.hashPassword(cleanPassword),
              fbUser.uid,
            );

            _isLoading = false;
            notifyListeners();
            return;
          }
        } on FirebaseAuthException {
          // Cloud registration failure (e.g. email-already-in-use, weak-password)
          _isLoading = false;
          notifyListeners();
          rethrow;
        } catch (_) {
          // Network or offline error - proceed to local registration
        }
      }

      // 2. Strict Offline Account Creation
      if (_storage.hasAccount(cleanEmail)) {
        _isLoading = false;
        notifyListeners();
        throw Exception('An account with $cleanEmail already exists. Please sign in instead.');
      }

      final uid = const Uuid().v4();
      final user = UserModel(
        id: uid,
        email: cleanEmail,
        displayName: cleanName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        streakDays: 1,
      );

      _currentUser = user;
      await _storage.saveUser(user);
      await _storage.setCurrentUserId(user.id);
      await _storage.saveCredentials(
        cleanEmail,
        LocalStorageService.hashPassword(cleanPassword),
        uid,
      );

      _isLoading = false;
      notifyListeners();
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) throw Exception('Please enter your email address.');

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: cleanEmail);
        return;
      } on FirebaseAuthException {
        rethrow;
      } catch (_) {}
    }
  }

  Future<void> updateGoals({
    required int studyMinutes,
    required int questions,
    required int tests,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      dailyStudyGoalMinutes: studyMinutes,
      dailyQuestionsGoal: questions,
      dailyTestsGoal: tests,
    );
    await _storage.saveUser(_currentUser!);
    notifyListeners();
  }

  Future<void> incrementStreak() async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      streakDays: _currentUser!.streakDays + 1,
      lastStudyDate: DateTime.now(),
    );
    await _storage.saveUser(_currentUser!);
    notifyListeners();
  }

  Future<void> updateStreak(int streakDays) async {
    if (_currentUser == null) return;
    final validStreak = streakDays < 0 ? 0 : streakDays;
    _currentUser = _currentUser!.copyWith(
      streakDays: validStreak,
      lastStudyDate: DateTime.now(),
    );
    await _storage.saveUser(_currentUser!);
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}
    await _storage.setCurrentUserId(null);
    _currentUser = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_currentUser == null) return;
    final uid = _currentUser!.id;
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.delete();
      }
    } catch (_) {}
    await _storage.clearUserData(uid);
    await _storage.setCurrentUserId(null);
    _currentUser = null;
    notifyListeners();
  }
}

