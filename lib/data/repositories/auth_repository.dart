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
    _isLoading = true;
    notifyListeners();

    try {
      if (Firebase.apps.isNotEmpty) {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final fbUser = cred.user;
        if (fbUser != null) {
          var user = _storage.getUser(fbUser.uid);
          user ??= UserModel(
            id: fbUser.uid,
            email: fbUser.email ?? email,
            displayName: fbUser.displayName ?? email.split('@').first,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          _currentUser = user.copyWith(lastLoginAt: DateTime.now());
          await _storage.saveUser(_currentUser!);
          await _storage.setCurrentUserId(_currentUser!.id);
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // If Firebase fails or is not connected, fallback to local offline mode
    }

    // Local / Offline authentication fallback
    final mockUid = 'user_${email.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    var user = _storage.getUser(mockUid);
    user ??= UserModel(
      id: mockUid,
      email: email.trim(),
      displayName: email.split('@').first,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      streakDays: 12, // Starter motivational streak
    );

    _currentUser = user.copyWith(lastLoginAt: DateTime.now());
    await _storage.saveUser(_currentUser!);
    await _storage.setCurrentUserId(_currentUser!.id);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (Firebase.apps.isNotEmpty) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final fbUser = cred.user;
        if (fbUser != null) {
          await fbUser.updateDisplayName(displayName.trim());
          final user = UserModel(
            id: fbUser.uid,
            email: fbUser.email ?? email,
            displayName: displayName.trim(),
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          _currentUser = user;
          await _storage.saveUser(_currentUser!);
          await _storage.setCurrentUserId(_currentUser!.id);
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // Fallback to local
    }

    final mockUid = const Uuid().v4();
    final user = UserModel(
      id: mockUid,
      email: email.trim(),
      displayName: displayName.trim(),
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      streakDays: 1,
    );

    _currentUser = user;
    await _storage.saveUser(user);
    await _storage.setCurrentUserId(user.id);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
        return;
      } catch (_) {}
    }
    // Simulation succeeded for offline
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

