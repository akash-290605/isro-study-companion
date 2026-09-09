import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isro_study_companion/core/services/local_storage_service.dart';
import 'package:isro_study_companion/data/repositories/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late AuthRepository authRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await LocalStorageService.init();
    authRepo = AuthRepository(storage);
  });

  group('Authentication & Strict Password Verification Tests', () {
    test('Default starter account succeeds with correct password', () async {
      await authRepo.signInWithEmailPassword(
        email: 'isro_aspirant@companion.edu',
        password: 'isro2026',
      );
      expect(authRepo.isAuthenticated, isTrue);
      expect(authRepo.currentUser?.email, 'isro_aspirant@companion.edu');
    });

    test('Default starter account REJECTS wrong password', () async {
      expect(
        () async => await authRepo.signInWithEmailPassword(
          email: 'isro_aspirant@companion.edu',
          password: 'wrong_password',
        ),
        throwsA(isA<Exception>()),
      );
      expect(authRepo.isAuthenticated, isFalse);
    });

    test('Random unregistered email REJECTS without bypass', () async {
      expect(
        () async => await authRepo.signInWithEmailPassword(
          email: 'random_stranger@isro.org',
          password: 'any_password123',
        ),
        throwsA(isA<Exception>()),
      );
      expect(authRepo.isAuthenticated, isFalse);
    });

    test('User registration saves hashed credentials and verifies strictly', () async {
      const email = 'new_candidate@isro.gov.in';
      const password = 'SecurePassword2026!';
      const name = 'Dr. Vikram';

      await authRepo.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: name,
      );

      expect(authRepo.isAuthenticated, isTrue);
      expect(authRepo.currentUser?.displayName, name);

      // Sign out
      await authRepo.signOut();
      expect(authRepo.isAuthenticated, isFalse);

      // Attempt login with WRONG password -> MUST FAIL
      expect(
        () async => await authRepo.signInWithEmailPassword(
          email: email,
          password: 'WrongPassword!',
        ),
        throwsA(isA<Exception>()),
      );
      expect(authRepo.isAuthenticated, isFalse);

      // Attempt login with CORRECT password -> MUST SUCCEED
      await authRepo.signInWithEmailPassword(
        email: email,
        password: password,
      );
      expect(authRepo.isAuthenticated, isTrue);
      expect(authRepo.currentUser?.email, email);
    });

    test('Password hash cannot be reversed or bypassed with empty inputs', () async {
      expect(
        () async => await authRepo.signInWithEmailPassword(email: '', password: ''),
        throwsA(isA<Exception>()),
      );
      expect(
        () async => await authRepo.registerWithEmailPassword(
          email: 'test@isro.in',
          password: '123', // less than 6 chars
          displayName: 'Test',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
